//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/8/24.
//

import Foundation
import EvervaultInputs

@MainActor
class FrameCheckoutViewModel: ObservableObject {
    enum CheckoutField: Hashable {
        case name, email, addressLine1, city, state, zip, country, card
    }

    @Published var accountPaymentOptions: [FrameObjects.PaymentMethod]?
    /// True once `loadAccountPaymentMethods` has returned. The view defers rendering the
    /// new-card section until this flips, so returning users don't see the Card/Billing
    /// block flash visible before the auto-selection of their first saved method.
    @Published var didLoadAccountPaymentMethods: Bool = false
    @Published var customerName: String = ""
    @Published var customerEmail: String = ""
    @Published var customerAddressLine1: String = ""
    @Published var customerAddressLine2: String = ""
    @Published var customerCity: String = ""
    @Published var customerState: String = ""
    @Published var customerCountry: AvailableCountry = AvailableCountry.defaultCountry
    @Published var customerZipCode: String = ""

    @Published var selectedAccountPaymentOption: FrameObjects.PaymentMethod?
    @Published var cardData = PaymentCardData()

    @Published var fieldErrors: [CheckoutField: String] = [:]
    @Published var isPerformingAction: Bool = false
    @Published var checkoutError: String?

    var accountId: String?
    var amount: Int
    var merchantId: String
    let addressMode: FrameAddressMode

    private var applePayViewModel: FrameApplePayViewModel?

    init(accountId: String?, amount: Int, merchantId: String = "", addressMode: FrameAddressMode = .required) {
        self.accountId = accountId
        self.amount = amount
        self.merchantId = merchantId
        self.addressMode = addressMode
    }

    func loadAccountDetails() async {
        guard let accountId else { return }
        if let response = try? await AccountsAPI.getAccountWith(accountId: accountId).0, let account = response.profile?.individual {
            let name = (account.name?.firstName ?? "") + " " + (account.name?.lastName ?? "")
            self.customerName = name
            self.customerEmail = account.email ?? ""
        }
        
        await loadAccountPaymentMethods()
    }
    
    func loadAccountPaymentMethods() async {
        guard let accountId else {
            self.didLoadAccountPaymentMethods = true
            return
        }
        let response = try? await AccountsAPI.getPaymentMethodsForAccount(accountId: accountId).0
        self.accountPaymentOptions = response?.data

        if selectedAccountPaymentOption == nil,
           cardData.card.number.isEmpty,
           let first = response?.data?.first {
            self.selectedAccountPaymentOption = first
        }
        self.didLoadAccountPaymentMethods = true
    }

    /// Clear field errors that only apply to the new-card flow. Called when the user
    /// selects a saved payment method so stale validation messages don't linger
    /// behind the collapsed Card/Billing sections.
    func clearNewCardFieldErrors() {
        for key: CheckoutField in [.card, .addressLine1, .city, .state, .zip, .country] {
            fieldErrors[key] = nil
        }
    }

    func payWithApplePay(completion: @escaping (Result<String, Error>) -> Void) {
        guard !merchantId.isEmpty else { return }
        guard let accountId, !accountId.isEmpty else { return }
        applePayViewModel = FrameApplePayViewModel(
            mode: .charge(amount: amount, currency: "usd"),
            owner: .account(accountId),
            merchantId: merchantId,
            completion: { result in
                switch result {
                case .success(.charge(let id)): completion(.success(id))
                case .success(.paymentMethod): break // not produced in .charge mode
                case .failure(let error): completion(.failure(error))
                }
            }
        )
        applePayViewModel?.presentApplePay()
    }

    //TODO: Integrate Google Pay
    func payWithGooglePay() { }

    func clearError(_ field: CheckoutField) {
        fieldErrors[field] = nil
    }

    var hasUsablePaymentInput: Bool {
        if selectedAccountPaymentOption != nil { return true }
        return !cardData.card.number.isEmpty && cardData.isPotentiallyValid
    }

    /// True if any address field carries a non-empty value.
    private var hasAnyAddressInput: Bool {
        !customerAddressLine1.isEmpty
            || !customerAddressLine2.isEmpty
            || !customerCity.isEmpty
            || !customerState.isEmpty
            || !customerZipCode.isEmpty
    }

    /// Whether to validate (and ultimately send) a billing address based on `addressMode`
    /// and current field state. OPTIONAL is all-or-nothing: any input promotes the block
    /// to required-shape validation.
    private var shouldValidateAddress: Bool {
        switch addressMode {
        case .required: return true
        case .optional: return hasAnyAddressInput
        case .hidden: return false
        }
    }

    /// Run all validations, populate `fieldErrors`, and return whether the form is valid.
    /// When `forSavedCard` is true, the new-card field is not validated.
    @discardableResult
    func validateAll(forSavedCard: Bool) -> Bool {
        var errors: [CheckoutField: String] = [:]

        if let err = Validators.validateFullName(customerName) {
            errors[.name] = err
        }
        if let err = Validators.validateEmail(customerEmail) {
            errors[.email] = err
        }
        if !forSavedCard {
            if let err = Validators.validateCard(cardData) {
                errors[.card] = err
            }
        }
        if shouldValidateAddress && !forSavedCard {
            if let err = Validators.validateNonEmpty(customerAddressLine1, fieldName: "Address line 1") {
                errors[.addressLine1] = err
            }
            if let err = Validators.validateNonEmpty(customerCity, fieldName: "City") {
                errors[.city] = err
            }
            if let err = Validators.validateNonEmpty(customerState, fieldName: "State") {
                errors[.state] = err
            }
            if let err = Validators.validateZipUS(customerZipCode) {
                errors[.zip] = err
            }
            if customerCountry.alpha2Code.isEmpty {
                errors[.country] = "Select a country"
            }
        }

        fieldErrors = errors
        return errors.isEmpty
    }

    func checkoutWithSelectedPaymentMethod(saveMethod: Bool) async throws -> FrameObjects.Transfer? {
        guard amount != 0 else { return nil }
        guard let accountId, !accountId.isEmpty else { return nil }
        guard !isPerformingAction else { return nil }
        isPerformingAction = true
        defer { isPerformingAction = false }

        var paymentMethodId: String?

        let usingSavedCard = selectedAccountPaymentOption != nil
        guard validateAll(forSavedCard: usingSavedCard) else { return nil }

        if !usingSavedCard {
            // Propagate the underlying networking error rather than swallowing into nil —
            // the caller's `throws` contract is the right place for the UI to render this.
            paymentMethodId = try await createPaymentMethod(accountId: accountId)
        } else {
            paymentMethodId = selectedAccountPaymentOption?.id
        }
        guard let paymentMethodId else { return nil }

        let request = TransferRequests.CreateTransferRequest(
            amount: amount,
            accountId: accountId,
            currency: "usd",
            sourcePaymentMethodId: paymentMethodId,
            destinationPaymentMethodId: nil,
            description: nil,
            metadata: nil)

        let (transfer, transferError) = try await TransfersAPI.createTransfer(request: request)
        if let transferError { throw transferError }
        return transfer
    }

    func createPaymentMethod(accountId: String) async throws -> String? {
        guard validateAll(forSavedCard: false) else { return nil }
        guard !accountId.isEmpty else { return nil }

        let billingAddress: FrameObjects.BillingAddress? = shouldValidateAddress
            ? FrameObjects.BillingAddress(city: customerCity,
                                          country: customerCountry.alpha2Code,
                                          state: customerState,
                                          postalCode: customerZipCode,
                                          addressLine1: customerAddressLine1,
                                          addressLine2: customerAddressLine2)
            : nil

        let request = PaymentMethodRequest.CreateCardPaymentMethodRequest(cardNumber: cardData.card.number,
                                                                          expMonth: cardData.card.expMonth,
                                                                          expYear: cardData.card.expYear,
                                                                          cvc: cardData.card.cvc,
                                                                          customer: nil,
                                                                          account: accountId,
                                                                          billing: billingAddress)
        let (paymentMethod, _) = try await PaymentMethodsAPI.createCardPaymentMethod(request: request, encryptData: false)
        return paymentMethod?.id
    }
}

public struct AvailableCountry: Hashable {
    public let alpha2Code: String
    public let displayName: String

    public static let defaultCountry: AvailableCountry = AvailableCountry(alpha2Code: "US", displayName: "United States")
    public static let restrictedCountries: [String] = ["Iran", "Russia", "North Korea", "Syria", "Cuba",
                                                       "Democratic Republic of Congo", "Iraq", "Libya",
                                                       "Mali", "Nicaragua", "Sudan", "Venezuela", "Yemen"]

    public static let allCountries: [AvailableCountry] = {
        Locale.Region.isoRegions.map { region in
            let name = Locale().localizedString(forRegionCode: region.identifier) ?? region.identifier
            return AvailableCountry(alpha2Code: region.identifier, displayName: name)
        }
        .sorted { $0.displayName < $1.displayName }
    }()
}
