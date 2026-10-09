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
    /// The host already supplied an account, so checkout does not GET one.
    private let usesSuppliedAccount: Bool
    /// The host already supplied the saved-method list, so checkout does not fetch it.
    private let usesSuppliedPaymentMethods: Bool
    /// Checkout token for the redacted account and saved-card reads. Refreshed in place when it expires.
    private let checkoutClientSecret: FrameCheckoutClientSecret?

    /// Creates a new checkout view-model.
    ///
    /// - Parameters:
    ///   - accountId: The Frame account ID for the payer, or `nil` for guest checkout.
    ///   - amount: Charge amount in the smallest currency unit (e.g. cents for USD).
    ///   - addressMode: Whether the billing address is `.required`, `.optional`, or `.hidden`.
    ///   - account: Account fetched on the host's backend. Prefills name and email. When `nil`
    ///     and a secret key is configured, checkout fetches the account itself.
    ///   - paymentMethods: Saved methods fetched on the host's backend. When `nil` and a secret
    ///     key is configured, checkout fetches the list itself.
    ///   - checkoutClientSecret: `chk_sess_` token from `POST /v1/checkout_sessions`. When set,
    ///     checkout reads the name, email, and saved cards with it instead of the secret key.
    init(accountId: String?,
         amount: Int,
         addressMode: FrameAddressMode = .required,
         account: FrameObjects.Account? = nil,
         paymentMethods: [FrameObjects.PaymentMethod]? = nil,
         checkoutClientSecret: FrameCheckoutClientSecret? = nil) {
        self.accountId = accountId
        self.amount = amount
        self.addressMode = addressMode
        self.usesSuppliedAccount = account != nil
        self.usesSuppliedPaymentMethods = paymentMethods != nil
        self.checkoutClientSecret = checkoutClientSecret
        if let account {
            applyAccount(account)
        }
        if let paymentMethods {
            applyPaymentMethods(paymentMethods)
        }
    }

    /// Prefills name and email from a supplied account, a checkout client secret, or account GET
    /// when a secret key is configured. A publishable key cannot read the profile.
    func loadAccountDetails() async {
        FrameNetworking.shared.setAccountIdIfUnset(accountId)
        AccountEventEmitter.emit(name: .checkoutStarted, screen: .paymentSheet)
        if checkoutClientSecret != nil {
            await loadWithCheckoutClientSecret()
            return
        }
        if !usesSuppliedAccount {
            await fetchAccountProfile()
        }
        await loadAccountPaymentMethods()
    }

    /// Uses the supplied saved-method list, or fetches it when a secret key is configured.
    /// A publishable key cannot list payment methods, so checkout stays on card entry.
    func loadAccountPaymentMethods() async {
        if usesSuppliedPaymentMethods {
            self.didLoadAccountPaymentMethods = true
            return
        }
        guard FrameNetworking.shared.hasSecretKey, let accountId, !accountId.isEmpty else {
            self.didLoadAccountPaymentMethods = true
            return
        }
        do {
            let (response, error) = try await AccountsAPI.getPaymentMethodsForAccount(accountId: accountId)
            if let error {
                FrameToastCenter.shared.show(error.toastMessage())
            }
            applyPaymentMethods(response?.data ?? [])
        } catch {
            FrameToastCenter.shared.show((error as? NetworkingError)?.toastMessage() ?? "Error: Something went wrong. Please try again.")
        }
        self.didLoadAccountPaymentMethods = true
    }

    private func fetchAccountProfile() async {
        guard FrameNetworking.shared.hasSecretKey, let accountId, !accountId.isEmpty else { return }
        do {
            let (response, error) = try await AccountsAPI.getAccountWith(accountId: accountId)
            if let error {
                FrameToastCenter.shared.show(error.toastMessage())
            }
            if let response {
                applyAccount(response)
            }
        } catch {
            FrameToastCenter.shared.show((error as? NetworkingError)?.toastMessage() ?? "Error: Something went wrong. Please try again.")
        }
    }

    private func loadWithCheckoutClientSecret() async {
        guard let checkoutClientSecret, let accountId, !accountId.isEmpty else {
            self.didLoadAccountPaymentMethods = true
            return
        }
        if !usesSuppliedAccount {
            let (profile, error) = await CheckoutSessionsAPI.loadAccount(accountId: accountId, secret: checkoutClientSecret)
            if let error {
                FrameToastCenter.shared.show(error.toastMessage())
            }
            if let individual = profile?.individual {
                customerName = (individual.name?.firstName ?? "") + " " + (individual.name?.lastName ?? "")
                customerEmail = individual.email ?? ""
            }
        }
        if !usesSuppliedPaymentMethods {
            let (methods, error) = await CheckoutSessionsAPI.loadPaymentMethods(accountId: accountId, secret: checkoutClientSecret)
            if let error {
                FrameToastCenter.shared.show(error.toastMessage())
            }
            applyPaymentMethods(methods)
        }
        self.didLoadAccountPaymentMethods = true
    }

    private func applyAccount(_ account: FrameObjects.Account) {
        guard let individual = account.profile?.individual else { return }
        customerName = (individual.name?.firstName ?? "") + " " + (individual.name?.lastName ?? "")
        customerEmail = individual.email ?? ""
    }

    private func applyPaymentMethods(_ methods: [FrameObjects.PaymentMethod]) {
        accountPaymentOptions = methods
        if selectedAccountPaymentOption == nil,
           cardData.card.number.isEmpty,
           let first = methods.first {
            selectedAccountPaymentOption = first
        }
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

    /// Fills the billing address fields from a picked autocomplete suggestion.
    ///
    /// Address line 2 is left alone: Mapbox does not reliably return apartment or unit, so
    /// whatever the user typed there stands. The country is only taken when the suggestion names
    /// one the picker offers, so a result cannot move the form to a country the merchant has not
    /// enabled. Errors on the filled fields are cleared, since the values they described are gone.
    func apply(_ address: FrameObjects.BillingAddress) {
        if let line1 = address.addressLine1 { customerAddressLine1 = line1 }
        if let city = address.city { customerCity = city }
        if let state = address.state { customerState = state }
        customerZipCode = address.postalCode

        if let code = address.country,
           let match = AvailableCountry.allCountries.first(where: { $0.alpha2Code == code }) {
            customerCountry = match
        }

        // One assignment: each subscript write on a published dictionary is its own change
        // notification, and the form re-renders on every one of them.
        var errors = fieldErrors
        for field in [CheckoutField.addressLine1, .city, .state, .zip, .country] {
            errors[field] = nil
        }
        fieldErrors = errors
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
            let countryCode = customerCountry.alpha2Code
            if let err = Validators.validateSubregion(customerState, countryCode: countryCode) {
                errors[.state] = err
            }
            if let err = Validators.validatePostalCode(customerZipCode, countryCode: countryCode) {
                errors[.zip] = err
            }
            if countryCode.isEmpty {
                errors[.country] = "Select a country"
            }
        }

        fieldErrors = errors
        if !errors.isEmpty {
            AccountEventEmitter.emit(name: .checkoutValidationFailed, screen: .paymentSheet,
                                     detail: errors.keys.map { "\($0)" }.joined(separator: ", "))
        }
        return errors.isEmpty
    }

    /// Validates the form and creates a transfer using the selected or newly tokenised payment method.
    ///
    /// - Parameter saveMethod: Whether to persist a newly entered card as a saved payment method.
    /// - Returns: The created ``FrameObjects/Transfer`` on success, or `nil` if preconditions are
    ///   not met (zero amount, missing account, action already in progress, or validation failure).
    /// - Throws: Any networking error encountered during payment-method creation or transfer creation.
    func checkoutWithSelectedPaymentMethod(saveMethod: Bool) async throws -> FrameObjects.TransferV2? {
        guard amount != 0 else { return nil }
        guard let accountId, !accountId.isEmpty else { return nil }
        guard !isPerformingAction else { return nil }
        isPerformingAction = true
        defer { isPerformingAction = false }

        AccountEventEmitter.emit(name: .checkoutPaymentStarted, screen: .paymentSheet, detail: AccountEventDetail.checkoutPayButtonTapped)

        var paymentMethodId: String?

        let usingSavedCard = selectedAccountPaymentOption != nil
        guard validateAll(forSavedCard: usingSavedCard) else { return nil }

        do {
            if !usingSavedCard {
                // Propagate the underlying networking error rather than swallowing into nil —
                // the caller's `throws` contract is the right place for the UI to render this.
                paymentMethodId = try await createPaymentMethod(accountId: accountId)
            } else {
                paymentMethodId = selectedAccountPaymentOption?.id
            }
        } catch {
            AccountEventEmitter.emit(name: .checkoutPaymentFailed, screen: .paymentSheet, detail: "\(error)")
            throw error
        }
        guard let paymentMethodId else { return nil }

        // Source is the payment method only; it already belongs to the account.
        var request = TransferV2Requests.CreateTransferRequest(
            amount: .init(value: amount, currency: checkoutClientSecret?.amountCurrency ?? "usd"),
            source: .init(paymentMethodId: paymentMethodId),
            confirm: false,
            authorizationMode: "automatic"
        )
        request.sonarSessionId = try await SessionManager.shared.ensureSession(accountId: accountId)

        let (transfer, transferError) = try await createCheckoutTransfer(request)
        if let transferError {
            AccountEventEmitter.emit(name: .checkoutPaymentFailed, screen: .paymentSheet, detail: "\(transferError)")
            throw transferError
        }
        guard let transfer else { return nil }

        let paymentStatus = transfer.payment?.status
        let needsConfirm = paymentStatus == "requires_confirmation"
            || paymentStatus == "requires_3d_secure"
            || paymentStatus == "requires_action"
        guard needsConfirm else {
            AccountEventEmitter.emit(name: .checkoutPaymentSucceeded, screen: .paymentSheet)
            return transfer
        }
        do {
            let confirmed = try await completeThreeDSecure(for: transfer)
            AccountEventEmitter.emit(name: .checkoutPaymentSucceeded, screen: .paymentSheet)
            return confirmed
        } catch let error as FrameCheckoutError {
            if case .declined = error {
                AccountEventEmitter.emit(name: .checkoutPaymentDeclined, screen: .paymentSheet, detail: error.toastMessage())
            } else {
                AccountEventEmitter.emit(name: .checkoutPaymentFailed, screen: .paymentSheet, detail: "\(error)")
            }
            throw error
        } catch {
            AccountEventEmitter.emit(name: .checkoutPaymentFailed, screen: .paymentSheet, detail: "\(error)")
            throw error
        }
    }

    private func createCheckoutTransfer(
        _ request: TransferV2Requests.CreateTransferRequest
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        if let secret = checkoutClientSecret {
            guard let accountId, !accountId.isEmpty,
                  let token = await CheckoutSessionsAPI.authorizationToken(accountId: accountId, secret: secret),
                  !token.isEmpty else {
                return (nil, .serverError(statusCode: 401, errorDescription: "Checkout client secret expired."))
            }
            return try await TransfersV2API.createTransfer(request: request, checkoutClientSecret: token)
        }
        return try await TransfersV2API.createTransfer(request: request)
    }

    /// Confirms a V2 transfer the API held back, running a 3D Secure challenge if needed.
    private func completeThreeDSecure(for transfer: FrameObjects.TransferV2) async throws -> FrameObjects.TransferV2 {
        let confirmation = TransferV2Confirmation(
            checkoutClientSecret: checkoutClientSecret?.clientSecret,
            challengePresenter: FrameThreeDSecureChallengePresenter()
        )

        switch try await confirmation.confirm(transferId: transfer.id) {
        case .succeeded(let confirmed):
            return confirmed
        case .failed(_, let message):
            throw FrameCheckoutError.declined(message: message)
        case .timedOut:
            throw FrameCheckoutError.unresolved
        }
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
                                          state: AddressSubregions.normalize(customerState,
                                                                             countryCode: customerCountry.alpha2Code),
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
        if let networkingError {
            AccountEventEmitter.emit(name: .cardTokenizationFailed, screen: .paymentSheet, detail: "\(networkingError)")
            throw networkingError
        }
        AccountEventEmitter.emit(name: .cardTokenized, screen: .paymentSheet)
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
