//
//  AccountEventCatalog.swift
//  Frame-iOS
//

import Foundation

/// The screen/flow an account event happened on. Values must match the shared cross-SDK
/// naming contract in `docs/ACCOUNT_EVENTS.md` (FRA-6548) — do not rename a case's `rawValue`
/// without updating that catalog too.
public enum AccountEventScreen: String {
    case applePay = "ApplePay"
    case checkout = "Checkout"
    case compliance = "Compliance"
    case identityVerification = "IdentityVerification"
    case onboarding = "Onboarding"
    case paymentMethod = "PaymentMethod"
    case paymentSheet = "PaymentSheet"
    case payoutMethod = "PayoutMethod"
    case personalInformation = "PersonalInformation"
    case phoneVerification = "PhoneVerification"
    case termsOfService = "TermsOfService"
}

/// The wire `name` for an account event. Values must match the shared cross-SDK naming
/// contract in `docs/ACCOUNT_EVENTS.md` (FRA-6548) — do not rename a case's `rawValue`
/// without updating that catalog too.
public enum AccountEventName: String {

    // MARK: Onboarding — Session
    case onboardingStarted = "onboarding_started"
    case onboardingStepViewed = "onboarding_step_viewed"
    case onboardingStepCompleted = "onboarding_step_completed"
    case onboardingCompleted = "onboarding_completed"
    case onboardingDeclined = "onboarding_declined"
    case onboardingNeedsReview = "onboarding_needs_review"
    case onboardingActionRequired = "onboarding_action_required"
    case onboardingCancelled = "onboarding_cancelled"
    case onboardingBlocked = "onboarding_blocked"
    case onboardingSessionStartFailed = "onboarding_session_start_failed"

    // MARK: Onboarding — Phone Verification
    case phoneVerificationStarted = "phone_verification_started"
    case phoneCodeSent = "phone_code_sent"
    case phoneCodeSendFailed = "phone_code_send_failed"
    case phoneCodeEntryStarted = "phone_code_entry_started"
    case phoneVerified = "phone_verified"
    case phoneCodeIncorrect = "phone_code_incorrect"
    case phoneCodeEntryCancelled = "phone_code_entry_cancelled"
    case silentPhoneAuthStarted = "silent_phone_auth_started"
    case silentPhoneAuthCompleted = "silent_phone_auth_completed"
    case silentPhoneAuthFallback = "silent_phone_auth_fallback"
    case silentPhoneAuthFailed = "silent_phone_auth_failed"

    // MARK: Onboarding — Profile
    case profileStepStarted = "profile_step_started"
    case profileUpdated = "profile_updated"
    case profileUpdateFailed = "profile_update_failed"
    case profileValidationFailed = "profile_validation_failed"

    // MARK: Onboarding — Identity Verification / Step-Up
    case stepUpStarted = "step_up_started"
    case stepUpCompleted = "step_up_completed"
    case stepUpAlreadyVerified = "step_up_already_verified"
    case stepUpFailed = "step_up_failed"
    case stepUpNeedsReview = "step_up_needs_review"
    case stepUpDataMismatch = "step_up_data_mismatch"
    case stepUpEscalated = "step_up_escalated"
    case stepUpDeclined = "step_up_declined"
    case stepUpUnavailable = "step_up_unavailable"
    case stepUpCancelled = "step_up_cancelled"

    // MARK: Onboarding — Payment Method
    case paymentMethodStepStarted = "payment_method_step_started"
    case savedPaymentMethodSelected = "saved_payment_method_selected"
    case addPaymentMethodStarted = "add_payment_method_started"
    case paymentMethodAdded = "payment_method_added"
    case paymentMethodAddFailed = "payment_method_add_failed"
    case cardValidationFailed = "card_validation_failed"
    case billingAddressUpdated = "billing_address_updated"
    case billingAddressUpdateFailed = "billing_address_update_failed"
    case savedPaymentMethodsLoadFailed = "saved_payment_methods_load_failed"

    // MARK: Onboarding — Payout Method
    case payoutMethodStepStarted = "payout_method_step_started"
    case savedPayoutMethodSelected = "saved_payout_method_selected"
    case addPayoutMethodStarted = "add_payout_method_started"
    case payoutMethodAdded = "payout_method_added"
    case payoutMethodAddFailed = "payout_method_add_failed"
    case bankLinkStarted = "bank_link_started"
    case bankLinkCompleted = "bank_link_completed"
    case bankLinkCancelled = "bank_link_cancelled"
    case bankLinkFailed = "bank_link_failed"
    case payoutMethodElected = "payout_method_elected"
    case payoutMethodElectionFailed = "payout_method_election_failed"

    // MARK: Onboarding — Compliance Check
    case complianceCheckStarted = "compliance_check_started"
    case complianceCheckPassed = "compliance_check_passed"
    case complianceCheckVpnDetected = "compliance_check_vpn_detected"
    case complianceCheckVpnBypassed = "compliance_check_vpn_bypassed"

    // MARK: Onboarding — Terms of Service
    case termsOfServiceShown = "terms_of_service_shown"
    case termsOfServiceAccepted = "terms_of_service_accepted"
    case termsOfServiceTokenFailed = "terms_of_service_token_failed"

    // MARK: Checkout / Payment Confirmation
    case checkoutStarted = "checkout_started"
    case checkoutPaymentMethodSelected = "checkout_payment_method_selected"
    case checkoutValidationFailed = "checkout_validation_failed"
    case checkoutPaymentStarted = "checkout_payment_started"
    case cardTokenized = "card_tokenized"
    case cardTokenizationFailed = "card_tokenization_failed"
    case checkoutPaymentSucceeded = "checkout_payment_succeeded"
    case checkoutPaymentDeclined = "checkout_payment_declined"
    case checkoutPaymentFailed = "checkout_payment_failed"
    case checkoutCancelled = "checkout_cancelled"
    case stepUpChallengeStarted = "step_up_challenge_started"
    case stepUpChallengeCompleted = "step_up_challenge_completed"
    case stepUpChallengeAbandoned = "step_up_challenge_abandoned"
    case stepUpChallengeUnavailable = "step_up_challenge_unavailable"
    /// Predates the shared catalog's `step_up_challenge_timed_out` name — left as-is rather
    /// than rename an already-shipped event; align on the next touch to this call site.
    case chargeIntentConfirmationPollingExhausted = "charge_intent_confirmation_polling_exhausted"

    // MARK: Apple Pay
    case applePayStarted = "apple_pay_started"
    case applePayUnavailable = "apple_pay_unavailable"
    case applePayAuthorized = "apple_pay_authorized"
    case applePayFailed = "apple_pay_failed"
    case applePayCancelled = "apple_pay_cancelled"
    case applePayCardAdded = "apple_pay_card_added"
    case applePayAssertionRejected = "apple_pay_assertion_rejected"

    // MARK: Device Attestation
    case attestationStarted = "attestation_started"
    case attestationCompleted = "attestation_completed"
    case attestationNotSupported = "attestation_not_supported"
    case attestationFailed = "attestation_failed"
    /// Predates the shared catalog's `attestation_reset` name — left as-is rather than rename
    /// an already-shipped event; align on the next touch to this call site.
    case attestationResetAndRetry = "attestation_reset_and_retry"
    case attestationAssertionRetried = "attestation_assertion_retried"

    // MARK: Fraud Session (Sonar)
    case fraudSessionStarted = "fraud_session_started"
    case fraudSessionRefreshed = "fraud_session_refreshed"
    case fraudSessionRecreated = "fraud_session_recreated"
    /// Predates the shared catalog's `fraud_session_failed` name — left as-is rather than
    /// rename an already-shipped event; align on the next touch to this call site.
    case sonarSessionFailed = "sonar_session_failed"
    case fraudSessionAdopted = "fraud_session_adopted"
}

/// Fixed developer-facing `detail` strings reused across account events. Dynamic details
/// (e.g. `"\(error)"`) stay inline at the call site — only static, repeated literals live here.
public enum AccountEventDetail {
    /// For ``AccountEventName/applePayAssertionRejected``.
    public static let applePayAssertionRejected = "attestation-linked failure, triggers an attestation reset"
    /// For ``AccountEventName/applePayCardAdded``.
    public static let applePayAddToOwnerMode = "mode: add-to-owner (onboarding wallet-card save, no charge)"
    /// For ``AccountEventName/applePayCancelled``.
    public static let applePaySheetDismissedNoResult = "sheet dismissed with no result"
    /// For ``AccountEventName/checkoutPaymentStarted``.
    public static let checkoutPayButtonTapped = "pay button tapped"
    /// For ``AccountEventName/checkoutPaymentMethodSelected``.
    public static let checkoutSavedPaymentMethod = "saved"
    /// For ``AccountEventName/checkoutPaymentMethodSelected``.
    public static let checkoutNewPaymentMethod = "new"
    /// For ``AccountEventName/fraudSessionAdopted``.
    public static let fraudSessionAdoptedFromAnonymous = "pre-account anonymous session migrated to account-scoped"
    /// For ``AccountEventName/fraudSessionRecreated``.
    public static let fraudSessionRefreshFellBackToRecreate = "refresh failed, fell back to creating fresh — self-healing, not a hard failure"
    /// For ``AccountEventName/attestationNotSupported``.
    public static let attestationNotSupportedReason = "simulator or unsupported OS version"
    /// For ``AccountEventName/attestationCompleted``.
    public static let attestationOneTimePerDevice = "one-time per device"
    /// For ``AccountEventName/attestationAssertionRetried``.
    public static let attestationAssertionRetriedContext = "per-payment assertion, distinct from the one-time attestation above"
    /// For ``AccountEventName/stepUpChallengeStarted``.
    public static let stepUpChallengeIs3DS = "3DS"
    /// For ``AccountEventName/stepUpChallengeUnavailable``.
    public static let stepUpChallengeNeverLoaded = "challenge page never loaded"
    /// For ``AccountEventName/stepUpChallengeCompleted``.
    public static let stepUpChallengeCompletedContext = "cardholder finished the UI — not itself a verdict"
    /// For ``AccountEventName/stepUpChallengeAbandoned``.
    public static let stepUpChallengeCardholderDismissed = "cardholder cancelled/dismissed"
    /// For ``AccountEventName/silentPhoneAuthStarted`` and ``AccountEventName/silentPhoneAuthCompleted``.
    public static let proveProvider = "provider: prove"
    /// For ``AccountEventName/stepUpStarted``.
    public static let personaProvider = "provider: persona"
    /// For ``AccountEventName/bankLinkStarted`` and ``AccountEventName/bankLinkCompleted``.
    public static let plaidProvider = "provider: plaid"
    /// For ``AccountEventName/bankLinkCancelled``.
    public static let plaidUserDismissed = "user dismissed Plaid"
    /// For ``AccountEventName/billingAddressUpdated``.
    public static let billingAddressOnlyVerificationPath = "address-only verification path"
    /// For ``AccountEventName/payoutMethodElected``.
    public static let payoutMethodSetAsPrimary = "set as primary"
    /// For ``AccountEventName/payoutMethodAdded``.
    public static let payoutMethodManualACHPath = "manual/ACH path"
    /// For ``AccountEventName/addPayoutMethodStarted``.
    public static let payoutMethodAddStartedManualOrPlaid = "manual or plaid"
    /// For ``AccountEventName/onboardingBlocked``.
    public static let onboardingBlockedNothingActionable = "capability outstanding, nothing actionable"
    /// For ``AccountEventName/stepUpAlreadyVerified``.
    public static let stepUpAlreadyVerifiedShortCircuit = "pre-check short-circuit, Persona never launched"
    /// For ``AccountEventName/stepUpCancelled``.
    public static let stepUpCancelledByUser = "user closed the verification UI"
    /// For ``AccountEventName/stepUpDeclined``.
    public static let stepUpCategoryTerminal = "category: terminal"
    /// For ``AccountEventName/stepUpNeedsReview``.
    public static let stepUpCategoryReview = "category: review"
    /// For ``AccountEventName/stepUpDataMismatch``.
    public static let stepUpCategoryRetriableWithNewData = "category: retriable_with_new_data"
    /// For ``AccountEventName/stepUpEscalated``.
    public static let stepUpCategoryStepUpEscalated = "category: step_up (e.g. SSN path failed, now needs gov ID)"
    /// For ``AccountEventName/stepUpUnavailable``.
    public static let stepUpCategoryTransientProviderError = "category: transient / provider_error"
    /// For ``AccountEventName/onboardingCompleted``.
    public static let onboardingCompletedApproved = "approved"
}
