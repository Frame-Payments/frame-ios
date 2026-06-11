//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/8/24.
//

import Foundation
import EvervaultInputs

/// View-model that drives the Frame checkout flow, coordinating form state,
/// validation, payment-method loading, and transfer creation.
@MainActor
class FrameCheckoutViewModel: ObservableObject {
    /// Identifies each focusable or validatable field in the checkout form.
    enum CheckoutField: Hashable {
        /// The cardholder full-name field.
        case name
        /// The customer e-mail field.
        case email
        /// The first line of the billing address.
        case addressLine1
        /// The billing city field.
        case city
        /// The billing state / province field.
        case state
        /// The postal / ZIP code field.
        case zip
        /// The billing country picker.
        case country
        /// The card-number / expiry / CVC composite field.
        case card
    }

    /// Saved payment methods available to the current account, or `nil` while loading.
    @Published var accountPaymentOptions: [FrameObjects.PaymentMethod]?
    /// True once `loadAccountPaymentMethods` has returned. The view defers rendering the
    /// new-card section until this flips, so returning users don't see the Card/Billing
    /// block flash visible before the auto-selection of their first saved method.
    @Published var didLoadAccountPaymentMethods: Bool = false
    /// The cardholder name entered by the user.
    @Published var customerName: String = ""
    /// The customer e-mail address entered by the user.
    @Published var customerEmail: String = ""
    /// The first line of the customer billing address.
    @Published var customerAddressLine1: String = ""
    /// The optional second line of the customer billing address.
    @Published var customerAddressLine2: String = ""
    /// The billing city entered by the user.
    @Published var customerCity: String = ""
    /// The billing state or province entered by the user.
    @Published var customerState: String = ""
    /// The billing country selected by the user; defaults to United States.
    @Published var customerCountry: AvailableCountry = AvailableCountry.defaultCountry
    /// The billing postal / ZIP code entered by the user.
    @Published var customerZipCode: String = ""

    /// The saved payment method the user has chosen to pay with, if any.
    @Published var selectedAccountPaymentOption: FrameObjects.PaymentMethod?
    /// The raw card data captured from the secure card-input component.
    @Published var cardData = PaymentCardData()

    /// Validation error messages keyed by form field; empty when the form is valid.
    @Published var fieldErrors: [CheckoutField: String] = [:]
    /// `true` while an async action (e.g. transfer creation) is in progress.
    @Published var isPerformingAction: Bool = false

    /// The Frame account ID used to look up saved payment methods and create transfers.
    var accountId: String?
    /// The charge amount in the smallest currency unit (e.g. cents for USD).
    var amount: Int
    /// Controls whether the billing-address section is required, optional, or hidden.
    let addressMode: FrameAddressMode

    /// Creates a new checkout view-model.
    ///
    /// - Parameters:
    ///   - accountId: The Frame account ID for the payer, or `nil` for guest checkout.
    ///   - amount: Charge amount in the smallest currency unit (e.g. cents for USD).
    ///   - addressMode: Whether the billing address is `.required`, `.optional`, or `.hidden`.
    init(accountId: String?, amount: Int, addressMode: FrameAddressMode = .required) {
        self.accountId = accountId
        self.amount = amount
        self.addressMode = addressMode
    }

    /// Fetches the account profile to pre-fill name and e-mail, then loads saved payment methods.
    func loadAccountDetails() async {
        guard let accountId, !accountId.isEmpty else {
            self.didLoadAccountPaymentMethods = true
            return
        }
        do {
            let (response, error) = try await AccountsAPI.getAccountWith(accountId: accountId)
            if let error {
                FrameToastCenter.shared.show(error.toastMessage())
            }
            if let account = response?.profile?.individual {
                let name = (account.name?.firstName ?? "") + " " + (account.name?.lastName ?? "")
                self.customerName = name
                self.customerEmail = account.email ?? ""
            }
        } catch {
            FrameToastCenter.shared.show((error as? NetworkingError)?.toastMessage() ?? "Error: Something went wrong. Please try again.")
        }

        await loadAccountPaymentMethods()
    }

    /// Fetches saved payment methods for the current account and auto-selects the first one.
    func loadAccountPaymentMethods() async {
        guard let accountId, !accountId.isEmpty else {
            self.didLoadAccountPaymentMethods = true
            return
        }
        do {
            let (response, error) = try await AccountsAPI.getPaymentMethodsForAccount(accountId: accountId)
            if let error {
                FrameToastCenter.shared.show(error.toastMessage())
            }
            self.accountPaymentOptions = response?.data
            if selectedAccountPaymentOption == nil,
               cardData.card.number.isEmpty,
               let first = response?.data?.first {
                self.selectedAccountPaymentOption = first
            }
        } catch {
            FrameToastCenter.shared.show((error as? NetworkingError)?.toastMessage() ?? "Error: Something went wrong. Please try again.")
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

    /// Removes the validation error for a single field.
    ///
    /// - Parameter field: The field whose error should be cleared.
    func clearError(_ field: CheckoutField) {
        fieldErrors[field] = nil
    }

    /// `true` when the user has provided sufficient payment input to attempt a charge —
    /// either a saved payment method is selected, or the card fields are non-empty and
    /// potentially valid.
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
    ///
    /// - Parameter forSavedCard: Pass `true` when the user is paying with a saved payment
    ///   method so that card-entry and billing-address fields are skipped.
    /// - Returns: `true` if the form contains no validation errors.
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

    /// Validates the form and creates a transfer using the selected or newly tokenised payment method.
    ///
    /// - Parameter saveMethod: Whether to persist a newly entered card as a saved payment method.
    /// - Returns: The created ``FrameObjects/Transfer`` on success, or `nil` if preconditions are
    ///   not met (zero amount, missing account, action already in progress, or validation failure).
    /// - Throws: Any networking error encountered during payment-method creation or transfer creation.
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

    /// Tokenises the card data entered by the user and creates a card payment method on the given account.
    ///
    /// - Parameter accountId: The Frame account ID to attach the new payment method to.
    /// - Returns: The ID of the newly created payment method, or `nil` if validation fails.
    /// - Throws: Any networking error returned by the payment-methods API.
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
        let (paymentMethod, networkingError) = try await PaymentMethodsAPI.createCardPaymentMethod(request: request, encryptData: false)
        if let networkingError { throw networkingError }
        return paymentMethod?.id
    }
}

/// A country value used in the billing-address picker, combining an ISO 3166-1 alpha-2
/// code with a localised display name.
public struct AvailableCountry: Hashable {
    /// The ISO 3166-1 alpha-2 country code (e.g. `"US"`, `"GB"`).
    public let alpha2Code: String
    /// The localised display name of the country (e.g. `"United States"`).
    public let displayName: String

    /// The default country selection — United States (`"US"`).
    public static let defaultCountry: AvailableCountry = AvailableCountry(alpha2Code: "US", displayName: "United States")
    /// Country display names that are restricted from use on the Frame platform.
    public static let restrictedCountries: [String] = ["Iran", "Russia", "North Korea", "Syria", "Cuba",
                                                       "Democratic Republic of Congo", "Iraq", "Libya",
                                                       "Mali", "Nicaragua", "Sudan", "Venezuela", "Yemen"]

    /// All non-restricted ISO countries sorted alphabetically by localised display name.
    public static let allCountries: [AvailableCountry] = {
        Locale.Region.isoRegions.map { region in
            let name = Locale().localizedString(forRegionCode: region.identifier) ?? region.identifier
            return AvailableCountry(alpha2Code: region.identifier, displayName: name)
        }
        .sorted { $0.displayName < $1.displayName }
    }()
}
