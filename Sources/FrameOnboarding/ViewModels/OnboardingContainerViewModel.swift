//
//  OnboardingContainerViewModel.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/6/26.
//

import Foundation
import SwiftUI
import Frame
import EvervaultInputs
import CoreLocation
import LinkKit

enum OnboardingField: Hashable {
    case authPhone, authBirthMonth, authBirthDay, authBirthYear
    case docFront, docBack, docSelfie

    /// Which screen / surface this field belongs to. Drives error-dictionary partitioning so
    /// validating one screen doesn't clobber errors on another.
    var group: OnboardingFieldGroup {
        switch self {
        case .authPhone, .authBirthMonth, .authBirthDay, .authBirthYear:
            return .phoneAuth
        case .docFront, .docBack, .docSelfie:
            return .docs
        }
    }
}

enum OnboardingFieldGroup {
    case phoneAuth, docs
}

@MainActor
class OnboardingContainerViewModel: ObservableObject {
    @Published var onboardingFlow: [OnboardingFlow] = []
    @Published var progressiveSteps: [OnboardingFlow] = []
    @Published var currentStep: OnboardingFlow = .personalInformation
    @Published var requiredCapabilities: [FrameObjects.Capabilities]

    @Published var cardData = PaymentCardData()
    @Published var bankAccount = FrameObjects.BankAccount(accountType: .checking)
    @Published var paymentMethodVerification: ThreeDSecureVerification?
    @Published var selectedPaymentMethod: FrameObjects.PaymentMethod?
    @Published var selectedPayoutMethod: FrameObjects.PaymentMethod?
    @Published var createdBillingAddress = FrameObjects.BillingAddress(country: AvailableCountry.defaultCountry.alpha2Code, postalCode: "")
    @Published var paymentMethods: [FrameObjects.PaymentMethod] = []
    @Published var payoutMethods: [FrameObjects.PaymentMethod] = []
    /// ID of the payment method currently elected as the account's payout destination, so the
    /// payout list can mark which row is primary.
    @Published var primaryPayoutMethodId: String?
    @Published var customerIdentity: FrameObjects.CustomerIdentity?
    @Published var filesToUpload: [FileUpload] = []
    @Published var ipAddress: String?
    @Published var userCoordinates: CLLocationCoordinate2D?
    @Published var termsOfServiceToken: String?

    @Published var fieldErrors: [OnboardingField: String] = [:]
    @Published var phoneCountry: PhoneCountrySelection = .default
    @Published var authPhoneNumber: String = ""
    @Published var authBirthMonth: String = ""
    @Published var authBirthDay: String = ""
    @Published var authBirthYear: String = ""

    @Published var proveUserInfo: ProveUserInfo?
    @Published var showProveOTPEntry: Bool = false
    @Published var pendingTwilioVerificationId: String?
    @Published var pendingTwilioVerificationAccountId: String?
    @Published var isPerformingAction: Bool = false

    /// Set when Prove fails after its OTP sheet was used and the Twilio fallback takes over. The
    /// sheet is (re)presented as `.phone`, so the applicant keeps a code-entry screen in front of
    /// them instead of being dropped back to the phone form.
    @Published var proveSheetFellBackToTwilio: Bool = false

    /// Set once the applicant has been asked for a Prove OTP on this attempt. `showProveOTPEntry`
    /// cannot answer that at failure time: `submitProveOTP` lowers it to dismiss the sheet before
    /// Prove has judged the code, so by the time the rejection arrives the sheet is already gone.
    private var proveOTPWasRequested: Bool = false

    /// Set when the applicant dismisses the Prove OTP sheet. The Prove SDK reports that
    /// cancellation as an ordinary auth error, so this distinguishes "user backed out" from
    /// "Prove failed" and keeps `sendOTPVerification` from toasting on a deliberate dismiss.
    private var proveOTPCancelledByUser: Bool = false

    /// Set to `true` once the applicant has verified identity with a government ID via Persona
    /// (the no-SSN path). While `true`, the SSN input and the "I don't have a social security
    /// number" button are hidden, SSN validation is skipped, and no SSN is sent to the API.
    @Published var identityVerifiedViaGovId: Bool = false
    /// Set to `true` when a capability lists `individual.identity_document` as due — a step-up on an
    /// account that carries no `idv` capability.
    @Published var identityDocumentRequired: Bool = false
    /// The Persona inquiry id used for the successful government-ID verification, if any.
    @Published var personaInquiryId: String?

    /// Either signal alone requires Persona: the merchant asked for `idv`, or the backend stepped
    /// this account up via `currently_due`.
    var governmentIdRequired: Bool {
        requiredCapabilities.contains(.idv) || identityDocumentRequired
    }

    private var plaidHandler: Handler?
    private var personaService: PersonaService?

    private var proveOTPContinuation: CheckedContinuation<String?, Never>?

    @Published var createdCustomerIdentity = CustomerIdentityRequest.CreateCustomerIdentityRequest(firstName: "", lastName: "", dateOfBirth: "", email: "", phoneNumber: "",
                                                                                                   ssn: "", address: FrameObjects.BillingAddress(postalCode: ""))

    var accountId: String?
    var existingAccountHasTOS: Bool = false
    let formatter = ISO8601DateFormatter()

    /// True when this flow began the active onboarding session — either from a host-supplied client
    /// secret or a self-minted one — and is therefore responsible for ending it on completion/dismiss.
    private(set) var ownsOnboardingSession = false

    /// Set once this flow has torn its session down, so a mint that was already in flight doesn't
    /// install a token after the fact. Without it, a self-mint that returns after the flow resolved
    /// leaves an `onb_sess_` active with nothing left to end it — the standalone-screen leak.
    private var hasEndedOnboardingSession = false

    init(accountId: String?,
         requiredCapabilities: [FrameObjects.Capabilities]) {
        self.accountId = accountId
        self.requiredCapabilities = requiredCapabilities
    }
    
    // Load existing account object to show on account page.
    func checkExistingAccount(updateCapabilies: Bool = false) async {
        guard let accountId else { return }
        // A host that launches onboarding with an existing accountId but no clientSecret has no
        // account-creation step to mint from, so bind a session here too — otherwise IDV and other
        // account-scoped requests fall back to the configured key. No-ops if a session is already active.
        await beginOnboardingSessionIfNeeded()
        do {
            let (account, error) = try await AccountsAPI.getAccountWith(accountId: accountId)
            reportError(error)

            // A previously completed government-ID verification leaves the idv capability active.
            // Seed the session flag so the applicant isn't asked to verify a second time. Read
            // before the profile guard below: capabilities aren't PII-gated, but `profile` is
            // withheld unless the request carries a secret key or a matching onboarding session,
            // so a legacy publishable-key host would otherwise never reach this.
            if account?.capabilities?.contains(where: { $0.name == FrameObjects.Capabilities.idv.rawValue
                                                        && $0.status == "active" }) == true {
                self.identityVerifiedViaGovId = true
            }

            // Withheld unless the request carries a matching onboarding session or a secret key.
            self.primaryPayoutMethodId = account?.payoutPaymentMethodId

            // Seeded here too, not just in `updateCapabilitiesBasedOnCompletion` — that runs only
            // when the caller passes `updateCapabilies: true`.
            if let capabilities = account?.capabilities {
                self.identityDocumentRequired = Self.requiresIdentityDocument(capabilities)
            }

            guard let profile = account?.profile?.individual else { return }
            let profileAddress = FrameObjects.BillingAddress(city: profile.address?.city, country: profile.address?.country,
                                                             state: profile.address?.state, postalCode: profile.address?.postalCode ?? "",
                                                             addressLine1: profile.address?.addressLine1, addressLine2: profile.address?.addressLine2)
            self.createdCustomerIdentity = CustomerIdentityRequest.CreateCustomerIdentityRequest(firstName: profile.name?.firstName ?? "",
                                                                                                 lastName: profile.name?.lastName ?? "",
                                                                                                 dateOfBirth: profile.birthdate ?? "",
                                                                                                 email: profile.email ?? "",
                                                                                                 phoneNumber: profile.phone?.number ?? profile.phoneNumber ?? "",
                                                                                                 ssn: profile.ssnLastFour ?? "",
                                                                                                 address: profileAddress)
            self.existingAccountHasTOS = account?.termsOfService?.acceptedAt != nil

            guard updateCapabilies else { return }
            if let capabilities = account?.capabilities {
                let accountCapabilities = capabilities.compactMap({ FrameObjects.Capabilities(rawValue: $0.name) })
                if Set(accountCapabilities).isSuperset(of: Set(requiredCapabilities)) {
                    // Check what needs to be completed
                    self.updateCapabilitiesBasedOnCompletion(accountCapabilities: capabilities)
                } else {
                    // Update capabilities to match what is required by merchant
                    let request = CapabilityRequest.RequestCapabilitiesRequest(capabilities: requiredCapabilities)
                    let (_, _) = try await CapabilitiesAPI.requestCapabilities(accountId: accountId, request: request)
                    // Then recheck account.
                    await self.checkExistingAccount()
                }
            }
        } catch let error {
            print(error)
        }
    }
    
    /// Scans every capability, not just `kyc` — a payout-only account gets the same key on
    /// `bank_account_receive`.
    static func requiresIdentityDocument(_ capabilities: [FrameObjects.Capability]) -> Bool {
        capabilities.contains { capability in
            capability.currentlyDue?.contains(FrameObjects.CapabilityRequirementKey.identityDocument) == true
        }
    }

    func updateCapabilitiesBasedOnCompletion(accountCapabilities: [FrameObjects.Capability]) {
        self.identityDocumentRequired = Self.requiresIdentityDocument(accountCapabilities)

        // Check to see which capabilites are completed, skip any that are not needed.
        accountCapabilities.forEach { capability in
            let requiredCapability = FrameObjects.Capabilities(rawValue: capability.name)
            guard capability.currentlyDue?.isEmpty == true else { return }
            // idv's requirement is event-driven and declares no field keys, so its currently_due is
            // empty even before verification happens. Status is the only signal that it's satisfied.
            if requiredCapability == .idv, capability.status != "active" { return }
            self.requiredCapabilities.removeAll(where: { $0 == requiredCapability })
        }
        self.updateOnboardingFlow()
    }
    
    func updateOnboardingFlow() {
        let onboardingSet = Set(requiredCapabilities.map { $0.onboardingStep })
        var onboardingArray = Array(onboardingSet).sorted(by: { $0.rawValue < $1.rawValue })
        onboardingArray.append(.verificationSubmitted)
        
        self.onboardingFlow = onboardingArray
        self.currentStep = onboardingArray.first ?? .personalInformation
    }
    
    /// Mints an account-scoped onboarding session (`onb_sess_…`) for the just-created account and
    /// binds every subsequent onboarding request to it, so calls like IDV authenticate as the
    /// session instead of falling back to the configured `pk_`/`sk_`. Uses the publishable key,
    /// which `POST /v1/onboarding_sessions` accepts, so no secret key leaves the device.
    ///
    /// Idempotent and safe to call after each account-creation path: it does nothing when the host
    /// already supplied a `clientSecret` (a session is active) or when no account exists yet.
    private func beginOnboardingSessionIfNeeded() async {
        guard !FrameNetworking.shared.hasActiveOnboardingSession else { return }
        guard let accountId else { return }

        let request = OnboardingSessionRequest.CreateOnboardingSessionRequest(accountId: accountId)
        do {
            let (session, error) = try await OnboardingSessionsAPI.createOnboardingSessionWithPublishableKey(request: request)
            reportError(error)
            guard let clientSecret = session?.clientSecret else { return }
            // The flow resolved while this mint was in flight; installing the token now would leak it.
            guard !hasEndedOnboardingSession else { return }
            FrameNetworking.shared.beginOnboardingSession(clientSecret: clientSecret)
            ownsOnboardingSession = true
        } catch let error {
            print(error)
        }
    }

    /// Binds every onboarding request to a host-supplied session token and records that this flow
    /// owns the session, so it's ended when the flow completes or is dismissed.
    func beginOnboardingSession(clientSecret: String) {
        FrameNetworking.shared.beginOnboardingSession(clientSecret: clientSecret)
        ownsOnboardingSession = true
    }

    /// Ends the onboarding session only when this flow began it, so later SDK calls revert to
    /// `pk_`/`sk_` authentication. Guarding on ownership keeps a container that never started a
    /// session from wiping one another flow may own.
    func endOnboardingSessionIfOwned() {
        // Latched before the ownership guard: a mint still in flight must be refused even when this
        // flow doesn't own a session yet, which is exactly the case that leaked.
        hasEndedOnboardingSession = true
        guard ownsOnboardingSession else { return }
        FrameNetworking.shared.endOnboardingSession()
        ownsOnboardingSession = false
    }

    // Create new individual account if no ID was previously provided to start onboarding.
    /// - Returns: The created account, or `nil` when the request failed.
    func createIndividualAccount() async -> FrameObjects.Account? {
        guard beginAction() else { return nil }
        defer { endAction() }
        do {
            let individualAccount = AccountRequest.CreateIndividualAccount(name: FrameObjects.AccountNameInfo(firstName: createdCustomerIdentity.firstName,
                                                                                                              lastName: createdCustomerIdentity.lastName),
                                                                           email: createdCustomerIdentity.email,
                                                                           phone: FrameObjects.AccountPhoneNumber(number: createdCustomerIdentity.phoneNumber,
                                                                                                                  countryCode: phoneCountry.dialCode),
                                                                           address: createdCustomerIdentity.address,
                                                                           birthdate: createdCustomerIdentity.dateOfBirth,
                                                                           ssn: identityVerifiedViaGovId ? nil : createdCustomerIdentity.ssn)
            let termsOfService = FrameObjects.AccountTermsOfService(token: termsOfServiceToken, ipAddress: SiftManager.getIPAddress(), acceptedAt: formatter.string(from: Date()))
            let profile = AccountRequest.CreateAccountProfile(business: nil, individual: individualAccount)
            let request = AccountRequest.CreateAccountRequest(accountType: .individual, termsOfService: termsOfService, profile: profile, capabilities: requiredCapabilities)
            let (account, error) = try await AccountsAPI.createAccount(request: request)
            reportError(error)

            guard let account else { return nil }
            self.accountId = account.id
            await beginOnboardingSessionIfNeeded()
            return account
        } catch let error {
            print(error)
        }
        return nil
    }

    func createEmptyIndividualAccount(phoneNumber: String, dateOfBirth: String) async {
        // Note: callers (e.g. sendOTPVerification) already hold the action guard. Don't double-guard.
        do {
            let individualAccount = AccountRequest.CreateIndividualAccount(name: FrameObjects.AccountNameInfo(firstName: "", lastName: ""),
                                                                           email: "",
                                                                           phone: FrameObjects.AccountPhoneNumber(number: phoneNumber, countryCode: phoneCountry.dialCode),
                                                                           address: nil, birthdate: dateOfBirth, ssn: nil)
            let profile = AccountRequest.CreateAccountProfile(business: nil, individual: individualAccount)
            let termsOfService = FrameObjects.AccountTermsOfService(token: termsOfServiceToken, ipAddress: SiftManager.getIPAddress(), acceptedAt:formatter.string(from: Date()))
            let request = AccountRequest.CreateAccountRequest(accountType: .individual, termsOfService: termsOfService, profile: profile, capabilities: requiredCapabilities)
            let (account, error) = try await AccountsAPI.createAccount(request: request)
            reportError(error)

            guard let account else { return }
            self.accountId = account.id
            await beginOnboardingSessionIfNeeded()
            return
        } catch let error {
            print(error)
        }
    }
    
    // Create new business account if no ID was previously provided to start onboarding.
    func createNewBusinessAccount() async { }

    // Update individual account if ID was provided at the start of onboarding.
    /// - Returns: The updated account, or `nil` when the request failed.
    func updateExistingIndividualAccount() async -> FrameObjects.Account? {
        guard let accountId else { return nil }
        guard beginAction() else { return nil }
        defer { endAction() }

        do {
            let individualAccount = AccountRequest.UpdateIndividualAccount(name: FrameObjects.AccountNameInfo(firstName: createdCustomerIdentity.firstName,
                                                                                                              lastName: createdCustomerIdentity.lastName),
                                                                           email: createdCustomerIdentity.email,
                                                                           phone: FrameObjects.AccountPhoneNumber(number: createdCustomerIdentity.phoneNumber,
                                                                                                                  countryCode: phoneCountry.dialCode),
                                                                           address: createdCustomerIdentity.address,
                                                                           birthdate: createdCustomerIdentity.dateOfBirth,
                                                                           ssnLastFour: identityVerifiedViaGovId ? nil : createdCustomerIdentity.ssn)
            let profile = AccountRequest.UpdateAccountProfile(business: nil, individual: individualAccount)
            let termsOfService = FrameObjects.AccountTermsOfService(token: termsOfServiceToken, ipAddress: SiftManager.getIPAddress(), acceptedAt:formatter.string(from: Date()))
            let request = AccountRequest.UpdateAccountRequest(termsOfService: existingAccountHasTOS ? nil : termsOfService, profile: profile)
            let (account, error) = try await AccountsAPI.updateAccountWith(accountId: accountId, request: request)
            reportError(error)
            return account
        } catch let error {
            print(error)
        }
        return nil
    }

    func generateTermsOfServiceToken() async {
        do {
            let (response, _) = try await TermsOfServiceAPI.createToken()
            self.termsOfServiceToken = response?.token
        } catch let error {
            print(error)
        }
    }

    // Start Phone Verification OTP Flow (Prove or Twilio)
    func sendOTPVerification(phoneNumber: String, dateOfBirth: String) async {
        guard beginAction() else { return }
        defer { endAction() }

        if accountId == nil {
            await createEmptyIndividualAccount(phoneNumber: phoneNumber, dateOfBirth: dateOfBirth)
        }
        guard let accountId else { return }

        do {
            guard let response = try await createPhoneVerification(accountId: accountId, phoneNumber: phoneNumber, dateOfBirth: dateOfBirth) else { return }

            guard let proveAuthToken = response.proveAuthToken else {
                // Twilio flow: SMS sent, show OTP entry screen
                pendingTwilioVerificationId = response.id
                pendingTwilioVerificationAccountId = accountId
                return
            }

            // Prove flow: run SDK, then confirm with verificationId from create response
            proveOTPCancelledByUser = false
            proveOTPWasRequested = false
            do {
                _ = try await runProveAuth(accountId: accountId, verificationId: response.id, authToken: proveAuthToken)
            } catch let proveError {
                await fallBackToTwilio(after: proveError, accountId: accountId, phoneNumber: phoneNumber, dateOfBirth: dateOfBirth)
                return
            }
            self.proveUserInfo = ProveUserInfo(firstName: "", lastName: "")
            await checkExistingAccount()
        } catch let error {
            print(error)
            reportError(.unknownError)
        }
    }

    /// Creates a phone verification, reporting any returned error to the applicant.
    /// - Returns: The created verification, or `nil` when the request failed.
    private func createPhoneVerification(accountId: String, phoneNumber: String, dateOfBirth: String) async throws -> PhoneOTPVerificationCreateResponse? {
        let (response, error) = try await PhoneOTPVerificationAPI.createVerification(accountId: accountId, phoneNumber: phoneNumber, dateOfBirth: dateOfBirth)
        reportError(error)
        return response
    }

    /// Runs the Prove SDK against `authToken`, confirming with the backend on success.
    private func runProveAuth(accountId: String, verificationId: String, authToken: String) async throws -> Bool {
        let confirmHandler: ProveConfirmHandler = { accountId, verificationId in
            let (_, networkingError) = try await PhoneOTPVerificationAPI.confirmVerification(accountId: accountId, verificationId: verificationId)
            if let networkingError { throw networkingError }
        }
        let proveService = ProveAuthService(accountId: accountId, verificationId: verificationId, confirmHandler: confirmHandler, otpProvider: { [weak self] in
            await self?.requestProveOTP()
        })
        return try await proveService.authenticateWith(authToken: authToken)
    }

    /// Recovers from a failed Prove attempt by creating a second verification, which the backend
    /// routes to Twilio.
    ///
    /// The fallback is decided server-side at create: a recent Prove attempt on this number that
    /// never verified sends the retry to Twilio with no `prove_auth_token`, so the recovery is
    /// simply to create again rather than to interpret the failure. Re-creating is what the
    /// backend's own end-to-end contract expects — create → refused confirm → create → confirm.
    ///
    /// A cancel is not a failure to recover from: the applicant dismissed the sheet and is
    /// returned to the phone form, where tapping Continue starts this over.
    private func fallBackToTwilio(after proveError: Error, accountId: String, phoneNumber: String, dateOfBirth: String) async {
        guard !proveOTPCancelledByUser else {
            proveOTPCancelledByUser = false
            return
        }

        // An applicant who was asked for a Prove code is looking at a code-entry screen (or just
        // watched it dismiss on submit). Keeping them on one is what makes this read as "that
        // code failed, here's a new one" rather than as the screen disappearing on them.
        let applicantWasEnteringACode = proveOTPWasRequested
        let retry = try? await createPhoneVerification(accountId: accountId, phoneNumber: phoneNumber, dateOfBirth: dateOfBirth)

        // Only a Twilio verification can be confirmed with a typed code. A retry that comes back
        // on Prove again (or not at all) has no code-entry path, so report the original failure
        // rather than stranding the applicant on a screen that cannot succeed.
        guard let retry, retry.proveAuthToken == nil else {
            dismissProveOTPSheet()
            reportProveFailure(proveError)
            return
        }

        pendingTwilioVerificationId = retry.id
        pendingTwilioVerificationAccountId = accountId

        // Re-present the sheet as Twilio entry for an applicant already mid-code. One who never
        // saw it (silent Prove auth) has no sheet to keep, and reaches the same code screen via
        // the phone form's existing `pendingTwilioVerificationId` branch.
        if applicantWasEnteringACode {
            proveSheetFellBackToTwilio = true
            showProveOTPEntry = true
        }

        FrameToastCenter.shared.show("Phone verification service failed. We've sent a second code — please try again.")
    }

    /// Closes the Prove OTP sheet without resuming a continuation — the flow, not the applicant,
    /// is ending the Prove attempt. ``cancelProveOTP`` is the applicant-driven counterpart, and
    /// the one that must resume the continuation the Prove SDK is waiting on.
    func dismissProveOTPSheet() {
        showProveOTPEntry = false
        proveSheetFellBackToTwilio = false
    }

    /// Surfaces a failed Prove authentication to the applicant.
    ///
    /// Prove failure previously fell into a `print`-only `catch`, which left the screen on the
    /// phone form with no message and no way forward but to re-tap Continue. Reached only when
    /// the Twilio fallback could not be established, so this is the applicant's last word on the
    /// attempt. A `NetworkingError` came from the confirm call inside ``ProveConfirmHandler`` and
    /// already carries a server message; anything else is a Prove SDK error and gets generic copy.
    private func reportProveFailure(_ error: Error) {
        print(error)
        // A Prove SDK error isn't a NetworkingError, so it falls through to the generic copy.
        let networkingError = (error as? NetworkingError) ?? .unknownError
        FrameToastCenter.shared.show(networkingError.toastMessage(fallback: "We couldn't verify your phone number. Please try again."))
    }

    /// Confirm Twilio OTP when user submits code on SecurePMVerificationView (phone type).
    ///
    /// On failure the pending verification is left intact so the applicant can retry the same
    /// verification with a corrected code rather than being sent back to start a new one.
    ///
    /// - Returns: `true` when the code was accepted.
    func confirmTwilioOTP(code: String) async -> Bool {
        guard let accountId = pendingTwilioVerificationAccountId,
              let verificationId = pendingTwilioVerificationId else { return false }
        guard beginAction() else { return false }
        defer { endAction() }

        do {
            let (_, networkingError) = try await PhoneOTPVerificationAPI.confirmVerification(accountId: accountId, verificationId: verificationId, code: code)
            if let networkingError {
                reportError(networkingError)
                return false
            }
            self.proveUserInfo = ProveUserInfo(firstName: "", lastName: "")
            self.pendingTwilioVerificationId = nil
            self.pendingTwilioVerificationAccountId = nil
            await checkExistingAccount()
            return true
        } catch let error {
            print(error)
            reportError(.unknownError)
            return false
        }
    }
    
    /// Called by otpProvider when Prove needs OTP. Suspends until user submits or cancels.
    /// Releases `isPerformingAction` while the OTP sheet is up so the submit button isn't
    /// stuck in loading state, then re-acquires it on submit/cancel.
    func requestProveOTP() async -> String? {
        endAction()
        let code = await withCheckedContinuation { continuation in
            self.proveOTPContinuation = continuation
            self.proveOTPWasRequested = true
            self.showProveOTPEntry = true
        }
        _ = beginAction()
        return code
    }

    /// Called when user submits OTP from the Prove OTP sheet.
    func submitProveOTP(_ code: String) {
        proveOTPContinuation?.resume(returning: code)
        proveOTPContinuation = nil
        showProveOTPEntry = false
    }

    /// Called when user cancels the Prove OTP sheet.
    func cancelProveOTP() {
        guard proveOTPContinuation != nil else { return }
        proveOTPCancelledByUser = true
        proveOTPContinuation?.resume(returning: nil)
        proveOTPContinuation = nil
        showProveOTPEntry = false
    }
    
    // Load existing Payment Methods for customer
    func loadExistingPaymentMethods() async {
        guard let accountId else { return }

        do {
            let (paymentMethodResponse, error) = try await PaymentMethodsAPI.getPaymentMethodsWithAccount(accountId: accountId)
            reportError(error)
            if let methods = paymentMethodResponse?.data {
                self.paymentMethods = methods.filter({ $0.card != nil })
                self.payoutMethods = methods.filter({ $0.ach != nil })
            }
        } catch let error {
            print(error)
        }
    }
    
    // Add new payment method to customer object
    func addNewPaymentMethod() async {
        guard beginAction() else { return }
        defer { endAction() }

        do {
            let request = PaymentMethodRequest.CreateCardPaymentMethodRequest(cardNumber: cardData.card.number,
                                                                              expMonth: cardData.card.expMonth,
                                                                              expYear: cardData.card.expYear,
                                                                              cvc: cardData.card.cvc,
                                                                              customer: nil,
                                                                              account: accountId,
                                                                              billing: createdBillingAddress)
            let (paymentMethod, error) = try await PaymentMethodsAPI.createCardPaymentMethod(request: request, encryptData: false)
            reportError(error)

            if let paymentMethod {
                self.selectedPaymentMethod = paymentMethod
                self.paymentMethods.append(paymentMethod)

                self.clearAccountDetails()
            }
        } catch let error {
            print(error)
        }
    }

    // Update an existing payment method with a billing address
    func updatePaymentMethod() async {
        guard let paymentMethodId = selectedPaymentMethod?.id else { return }
        guard beginAction() else { return }
        defer { endAction() }

        do {
            let request = PaymentMethodRequest.UpdatePaymentMethodRequest(billing: createdBillingAddress)
            let (paymentMethod, error) = try await PaymentMethodsAPI.updatePaymentMethodWith(paymentMethodId: paymentMethodId, request: request)
            reportError(error)

            if let paymentMethod {
                self.selectedPaymentMethod = paymentMethod
                self.paymentMethods.append(paymentMethod)
                
                self.clearAccountDetails()
            }
        } catch let error {
            print(error)
        }
    }
    
    /// Elects `payoutMethod` as the account's payout destination (its "primary" bank).
    ///
    /// Callers already hold `beginAction()`, so this does not re-acquire it — it is not reentrant
    /// and would refuse.
    ///
    /// - Parameter payoutMethod: The ACH payment method to make primary.
    /// - Returns: `true` when the election succeeded.
    @discardableResult
    func electPayoutMethod(_ payoutMethod: FrameObjects.PaymentMethod) async -> Bool {
        guard let accountId else { return false }

        do {
            let request = AccountRequest.ElectPayoutMethodRequest(paymentMethodId: payoutMethod.id)
            let (account, error) = try await AccountsAPI.electPayoutMethod(accountId: accountId, request: request)
            reportError(error)

            // A failure must not leave the UI showing this bank as primary.
            guard error == nil, let account else { return false }

            self.primaryPayoutMethodId = account.payoutPaymentMethodId ?? payoutMethod.id
            return true
        } catch let error {
            print(error)
            return false
        }
    }

    // Add new payout method to customer object
    func addNewPayoutMethod() async {
        guard beginAction() else { return }
        defer { endAction() }

        do {
            let request = PaymentMethodRequest.CreateACHPaymentMethodRequest(accountType: bankAccount.accountType ?? .checking,
                                                                             accountNumber: bankAccount.accountNumber ?? "",
                                                                             routingNumber: bankAccount.routingNumber ?? "",
                                                                             customer: nil,
                                                                             account: accountId,
                                                                             billing: createdBillingAddress)
            let (payoutMethod, error) = try await PaymentMethodsAPI.createACHPaymentMethod(request: request)
            reportError(error)

            if let payoutMethod {
                self.selectedPayoutMethod = payoutMethod
                self.payoutMethods.append(payoutMethod)

                await self.electPayoutMethod(payoutMethod)

                self.clearAccountDetails()
            }
        } catch let error {
            print(error)
        }
    }
    
    // Fetch Plaid link token and open the Plaid Link UI
    func openPlaidLink(from viewController: UIViewController, onSuccess: @escaping () -> Void) async {
        guard let accountId else { return }
        guard beginAction() else { return }
        // The action stays active until Plaid's onSuccess/onExit/error callback resolves the flow.
        do {
            let (response, error) = try await AccountsAPI.getPlaidLinkToken(accountId: accountId)
            reportError(error)
            guard let token = response?.linkToken else {
                endAction()
                return
            }
            var config = LinkTokenConfiguration(token: token) { [weak self] success in
                Task { @MainActor in
                    guard let self,
                          let account = success.metadata.accounts.first,
                          !account.id.isEmpty else {
                        self?.endAction()
                        return
                    }
                    // handlePlaidSuccess re-enters; clear the flag first so it can re-acquire.
                    self.endAction()
                    await self.handlePlaidSuccess(
                        publicToken: success.publicToken,
                        plaidAccountId: account.id,
                        institutionName: success.metadata.institution.name,
                        subtype: account.subtype.description
                    )
                    onSuccess()
                }
            }
            config.onExit = { [weak self] (exit: LinkExit) in
                Task { @MainActor in
                    self?.endAction()
                }
                if let error = exit.error {
                    print("Plaid Link exited with error: \(error.displayMessage ?? String(describing: error.errorCode))")
                }
            }
            let result = Plaid.create(config)
            switch result {
            case .success(let handler):
                self.plaidHandler = handler
                handler.open(presentUsing: .viewController(viewController))
            case .failure(let error):
                endAction()
                print("Plaid.create failed: \(error.localizedDescription)")
            }
        } catch let error {
            endAction()
            print(error)
        }
    }

    // Handle successful Plaid bank connection
    func handlePlaidSuccess(publicToken: String, plaidAccountId: String, institutionName: String?, subtype: String?) async {
        guard let accountId else { return }
        guard beginAction() else { return }
        defer { endAction() }
        do {
            let request = PaymentMethodRequest.ConnectPlaidBankAccountRequest(
                account: accountId,
                publicToken: publicToken,
                accountId: plaidAccountId,
                institutionName: institutionName,
                subtype: subtype
            )
            let (payoutMethod, error) = try await PaymentMethodsAPI.connectPlaidBankAccount(request: request)
            reportError(error)
            if let payoutMethod {
                self.selectedPayoutMethod = payoutMethod
                self.payoutMethods.append(payoutMethod)
                await self.electPayoutMethod(payoutMethod)
                self.clearAccountDetails()
            }
        } catch let error {
            print(error)
        }
    }

    /// Submits the personal-information step, running government-ID verification first when the
    /// account requires it.
    ///
    /// See `governmentIdRequired` for what makes it required. Skipped when the applicant already
    /// verified this session or on a previous visit.
    ///
    /// - Parameter viewController: The view controller to present the Persona UI from.
    /// - Returns: `true` when the step is complete and the flow may advance.
    func submitPersonalInformation(from viewController: UIViewController) async -> Bool {
        let account = accountId == nil
            ? await createIndividualAccount()
            : await updateExistingIndividualAccount()

        if let capabilities = account?.capabilities {
            self.identityDocumentRequired = Self.requiresIdentityDocument(capabilities)
        }

        // Submission failed — the create/update path already surfaced a toast. Stay on the step
        // rather than advancing past data the API never accepted.
        guard account != nil else { return false }

        guard governmentIdRequired, !identityVerifiedViaGovId else { return true }

        // Persona runs under its own beginAction() guard, which the submission above has released.
        // Awaited back to back on the main actor so `isPerformingAction` is never observably false
        // while Persona covers the container — see the cancel guard in OnboardingContainerView's
        // .onDisappear.
        await verifyIdentityWithoutSsn(from: viewController)

        // Cancel, decline, pending, and error all leave the flag false and have already toasted.
        return identityVerifiedViaGovId
    }

    /// No-SSN identity verification: create a Persona inquiry server-side, present the Persona SDK
    /// against it, then confirm the result with the Frame backend.
    ///
    /// Persona's client-side completion is best-effort, so the `/idv/complete` response is treated
    /// as the source of truth for flipping `identityVerifiedViaGovId`. A cancel, a Persona error,
    /// or a non-verified / pending server response leaves the applicant un-verified so they can
    /// retry or fall back to entering an SSN.
    ///
    /// - Parameter viewController: The view controller to present the Persona UI from.
    func verifyIdentityWithoutSsn(from viewController: UIViewController) async {
        guard beginAction() else { return }
        defer { endAction() }

        do {
            // 1. Server pre-creates the Persona inquiry and returns its id. On error, surface the
            //    toast and stop — don't launch Persona against a possibly-invalid inquiry.
            let (session, sessionError) = try await IdentityVerificationAPI.createSession()
            guard sessionError == nil, let inquiryId = session?.inquiryId else {
                reportError(sessionError)
                return
            }

            // 1a. Pre-existing accounts may already have an approved inquiry. An approved inquiry is
            //     terminal — the Persona SDK can't open a session on it and errors out. Ask the
            //     backend first (it reads status from Persona's API, which works on terminal
            //     inquiries); if already verified, skip Persona entirely. A nil/false result means
            //     not-yet-verified, so fall through and run the Persona flow as normal.
            let (existing, existingError) = try await IdentityVerificationAPI.complete(inquiryId: inquiryId)
            if existingError == nil, existing?.verified == true {
                self.personaInquiryId = inquiryId
                self.identityVerifiedViaGovId = true
                return
            }

            // 2. Launch the Persona SDK against the pre-created inquiry.
            let service = PersonaService(inquiryId: inquiryId)
            self.personaService = service
            let outcome = try await service.start(from: viewController)
            self.personaService = nil

            // A cancel is a normal, non-error exit — leave the applicant un-verified. Every other
            // exit from this method toasts, so say something here too: when verification is
            // required, a silent return leaves the Continue button looking dead.
            guard case .completed = outcome else {
                FrameToastCenter.shared.show("Identity verification was cancelled.")
                return
            }

            // 3. Confirm with the backend — the authoritative verification result. A non-JSON or
            //    error response decodes to nil (endpoint may not exist yet, FRA-5363); treat that
            //    as pending rather than verified.
            let (completion, completeError) = try await IdentityVerificationAPI.complete(inquiryId: inquiryId)
            guard completeError == nil else {
                reportError(completeError)
                return
            }
            if completion?.verified == true {
                self.personaInquiryId = inquiryId
                self.identityVerifiedViaGovId = true
            } else {
                // The Persona flow finished but the backend didn't confirm verification (declined
                // or still pending). Tell the applicant so they can retry or enter an SSN instead.
                FrameToastCenter.shared.show("We couldn't verify your identity. Please try again or enter your Social Security Number.")
            }
        } catch let error {
            self.personaService = nil
            print(error)
            // A throw here (Persona SDK failure, transport error) is otherwise invisible. When
            // verification gates the step, the applicant needs to know why they can't continue.
            FrameToastCenter.shared.show("We couldn't verify your identity. Please try again or enter your Social Security Number.")
        }
    }

    /// Clears the government-ID verified state so the applicant can re-enter an SSN or re-run
    /// verification. Restores the SSN row and the "I don't have a social security number" button.
    func resetIdentityVerification() {
        identityVerifiedViaGovId = false
        personaInquiryId = nil
    }

    /// Opens a 3D Secure verification for the selected card, recovering the in-flight one when
    /// the API reports a verification already exists.
    func start3DSecureProcess() async {
        guard let paymentMethodId = selectedPaymentMethod?.id else { return }
        guard beginAction() else { return }
        defer { endAction() }

        let request = ThreeDSecureRequests.CreateThreeDSecureVerification(paymentMethodId: paymentMethodId)

        do {
            let (verification, verificationError, _) = try await ThreeDSecureVerificationsAPI.create3DSecureVerification(request: request)
            if let verification {
                paymentMethodVerification = verification
            } else if let verificationError, let verificationId = verificationError.error.existingIntentId {
                await retrieveExistingThreeDSecureVerification(verificationId: verificationId)
            }
        } catch let error {
            print(error)
        }
    }

    /// Loads the current state of an in-flight verification, including the challenge URL the
    /// cardholder is sent to.
    private func retrieveExistingThreeDSecureVerification(verificationId: String) async {
        do {
            let (verification, _) = try await ThreeDSecureVerificationsAPI.retrieve3DSecureVerification(verificationId: verificationId)
            if let verification {
                paymentMethodVerification = verification
            }
        } catch let error {
            print(error)
        }
    }

    func createCustomerIdentity() async {
        guard beginAction() else { return }
        defer { endAction() }

        do {
            let (identity, error) = try await CustomerIdentityAPI.createCustomerIdentity(request: createdCustomerIdentity)
            reportError(error)
            if let identity {
                self.customerIdentity = identity
            }
        } catch let error {
            print(error)
        }
    }

    // Upload ID and selfie documents
    func uploadIdentificationDocuments() async {
        guard filesToUpload.count == 3, let customerIdentityId = customerIdentity?.id else { return }
        guard beginAction() else { return }
        defer { endAction() }

        do {
            let (identity, error) = try await CustomerIdentityAPI.uploadIdentityDocuments(customerIdentityId: customerIdentityId, identityImages: filesToUpload)
            reportError(error)
            if let identity {
                self.customerIdentity = identity
            }
        } catch let error {
            print(error)
        }
    }
    
    func errorBinding(_ field: OnboardingField) -> Binding<String?> {
        Binding(
            get: { [weak self] in self?.fieldErrors[field] },
            set: { [weak self] new in self?.fieldErrors[field] = new }
        )
    }

    /// Replaces all errors for the given group with `errors`, leaving fields in other groups
    /// untouched. Returns whether `errors` is empty.
    @discardableResult
    private func applyValidation(group: OnboardingFieldGroup, errors: [OnboardingField: String]) -> Bool {
        var merged = fieldErrors.filter { $0.key.group != group }
        merged.merge(errors) { _, new in new }
        fieldErrors = merged
        return errors.isEmpty
    }

    @discardableResult
    func validateAllPhoneAuth() -> Bool {
        var errors: [OnboardingField: String] = [:]

        if let err = Validators.validatePhoneE164(authPhoneNumber, regionCode: phoneCountry.alpha2) {
            errors[.authPhone] = err
        }

        if requiredCapabilities.contains(.kycPrefill) {
            if let err = Validators.validateDateOfBirth(year: authBirthYear, month: authBirthMonth, day: authBirthDay) {
                errors[.authBirthMonth] = err
                errors[.authBirthDay] = err
                errors[.authBirthYear] = err
            }
        }

        return applyValidation(group: .phoneAuth, errors: errors)
    }

    @discardableResult
    func validateAllDocs() -> Bool {
        var errors: [OnboardingField: String] = [:]
        if !filesToUpload.contains(where: { $0.fieldName == .front }) { errors[.docFront] = "Front of ID is required" }
        if !filesToUpload.contains(where: { $0.fieldName == .back }) { errors[.docBack] = "Back of ID is required" }
        if !filesToUpload.contains(where: { $0.fieldName == .selfie }) { errors[.docSelfie] = "Selfie is required" }

        return applyValidation(group: .docs, errors: errors)
    }

    func clearAccountDetails() {
        self.cardData = PaymentCardData()
        self.bankAccount = FrameObjects.BankAccount()
        self.createdBillingAddress = FrameObjects.BillingAddress(country: AvailableCountry.defaultCountry.alpha2Code, postalCode: "")
    }

    /// Append a wallet-created payment method (Apple Pay) to the in-memory list and select it.
    /// Used by `AddPaymentMethodView` after a successful `FrameApplePayButton` `.addToOwner` flow.
    func appendNewlyAddedPaymentMethod(_ paymentMethod: FrameObjects.PaymentMethod) {
        self.selectedPaymentMethod = paymentMethod
        self.paymentMethods.append(paymentMethod)
    }

    /// Re-entrancy guard for user-initiated network actions. Returns false when an action is
    /// already in flight; otherwise flips `isPerformingAction` to true so the caller can begin.
    /// Callers must pair every successful `beginAction()` call with `endAction()` (use defer).
    @discardableResult
    private func beginAction() -> Bool {
        guard !isPerformingAction else { return false }
        isPerformingAction = true
        return true
    }

    private func endAction() {
        isPerformingAction = false
    }

    /// Surface a networking failure as a toast. For server errors, the parsed
    /// `error_details.message` from the Frame envelope is shown when present. Onboarding API
    /// calls don't have a per-field inline error UI, so every failure routes through the toast.
    func reportError(_ error: NetworkingError?) {
        guard let error else { return }
        FrameToastCenter.shared.show(error.toastMessage())
    }
}
