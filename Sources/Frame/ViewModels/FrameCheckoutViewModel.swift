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

    @Published var customerPaymentOptions: [FrameObjects.PaymentMethod]?
    @Published var customerName: String = ""
    @Published var customerEmail: String = ""
    @Published var customerAddressLine1: String = ""
    @Published var customerAddressLine2: String = ""
    @Published var customerCity: String = ""
    @Published var customerState: String = ""
    @Published var customerCountry: AvailableCountry = AvailableCountry.defaultCountry
    @Published var customerZipCode: String = ""

    @Published var selectedCustomerPaymentOption: FrameObjects.PaymentMethod?
    @Published var cardData = PaymentCardData()

    @Published var fieldErrors: [CheckoutField: String] = [:]
    @Published var isPerformingAction: Bool = false

    var customerId: String?
    var amount: Int
    var merchantId: String
    let addressMode: FrameAddressMode

    private var applePayViewModel: FrameApplePayViewModel?

    init(customerId: String?, amount: Int, merchantId: String = "", addressMode: FrameAddressMode = .required) {
        self.customerId = customerId
        self.amount = amount
        self.merchantId = merchantId
        self.addressMode = addressMode
    }

    func loadCustomerPaymentMethods(forTesting: Bool = false) async {
        guard let customerId else { return }

        let customer = try? await CustomersAPI.getCustomerWith(customerId: customerId, forTesting: forTesting).0
        self.customerPaymentOptions = customer?.paymentMethods
        self.customerName = customer?.name ?? ""
        self.customerEmail = customer?.email ?? ""
    }

    func payWithApplePay(completion: @escaping (Result<FrameObjects.ChargeIntent, Error>) -> Void) {
        guard !merchantId.isEmpty else { return }
        applePayViewModel = FrameApplePayViewModel(
            mode: .charge(amount: amount, currency: "usd"),
            owner: customerId.map { .customer($0) } ?? .customer(""),
            merchantId: merchantId,
            completion: { result in
                switch result {
                case .success(.charge(let intent)): completion(.success(intent))
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
        if selectedCustomerPaymentOption != nil { return true }
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
        if shouldValidateAddress {
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

    func checkoutWithSelectedPaymentMethod(saveMethod: Bool) async throws -> FrameObjects.ChargeIntent? {
        guard amount != 0 else { return nil }
        guard !isPerformingAction else { return nil }
        isPerformingAction = true
        defer { isPerformingAction = false }

        var paymentMethodId: String?

        let usingSavedCard = selectedCustomerPaymentOption != nil
        guard validateAll(forSavedCard: usingSavedCard) else { return nil }

        if !usingSavedCard {
            let customerInfo = try? await createPaymentMethod(customerId: customerId)
            paymentMethodId = customerInfo?.paymentId
            customerId = customerInfo?.customerId
        } else {
            paymentMethodId = selectedCustomerPaymentOption?.id
        }
        guard paymentMethodId != nil else { return nil }

        //TODO: Allow developers to pass description here of charge.
        let request = ChargeIntentsRequests.CreateChargeIntentRequest(amount: amount,
                                                                      currency: "usd",
                                                                      customer: customerId,
                                                                      description: "",
                                                                      paymentMethod: paymentMethodId,
                                                                      confirm: true,
                                                                      receiptEmail: customerEmail,
                                                                      authorizationMode: .automatic,
                                                                      customerData: nil,
                                                                      paymentMethodData: nil)

        // Create Charge Intent, return this on completion.
        let (chargeIntent, chargeError) = try await ChargeIntentsAPI.createChargeIntent(request: request)
        if let chargeError { throw chargeError }
        return chargeIntent
    }

    func createPaymentMethod(customerId: String? = nil) async throws -> (paymentId: String?, customerId: String?)  {
        guard validateAll(forSavedCard: false) else { return (nil, nil) }

        let billingAddress: FrameObjects.BillingAddress? = shouldValidateAddress
            ? FrameObjects.BillingAddress(city: customerCity,
                                          country: customerCountry.alpha2Code,
                                          state: customerState,
                                          postalCode: customerZipCode,
                                          addressLine1: customerAddressLine1,
                                          addressLine2: customerAddressLine2)
            : nil

        var currentCustomerId: String = ""
        if customerId == nil {
            //1. Create the new user to assign the payment method to.
            let customerRequest = CustomerRequest.CreateCustomerRequest(billingAddress: billingAddress, name: customerName, email: customerEmail)
            let customer = try? await CustomersAPI.createCustomer(request: customerRequest, forTesting: true).0
            currentCustomerId = customer?.id ?? ""
            guard currentCustomerId != "" else { return (nil, nil) }
        } else if let customerId {
            currentCustomerId = customerId
        }

        //2. Create the payment method
        let request = PaymentMethodRequest.CreateCardPaymentMethodRequest(cardNumber: cardData.card.number,
                                                                          expMonth: cardData.card.expMonth,
                                                                          expYear: cardData.card.expYear,
                                                                          cvc: cardData.card.cvc,
                                                                          customer: currentCustomerId,
                                                                          account: nil,
                                                                          billing: billingAddress)
        let (paymentMethod, _) = try await PaymentMethodsAPI.createCardPaymentMethod(request: request, encryptData: false)
        guard let paymentMethodId = paymentMethod?.id else { return (nil, currentCustomerId) }
        return (paymentMethodId, currentCustomerId)
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
