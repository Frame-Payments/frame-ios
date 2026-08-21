//
//  FrameResults.swift
//  Frame-iOS
//

import Foundation

/// Outcome of a Frame UI flow (checkout, cart, onboarding).
///
/// `completed(id:)` carries the resource id produced by the flow:
/// - `FrameCheckoutView` / `FrameCartView` → Transfer id
/// - `OnboardingContainerView` → the selected PaymentMethod id, or empty string if the flow
///   completed without one
public enum FrameResult {
    /// The flow finished successfully.
    ///
    /// - Parameter id: The resource identifier produced by the flow (e.g. a Transfer id or
    ///   PaymentMethod id). May be an empty string when no resource was created.
    case completed(id: String)

    /// The user dismissed the flow before it could finish.
    case cancelled

    /// The flow encountered an unrecoverable error.
    ///
    /// - Parameter error: The underlying error that caused the failure.
    case failed(Error)
}

/// Errors surfaced by the checkout flow that are not transport or server failures.
public enum FrameCheckoutError: Error {
    /// The issuer declined the charge, optionally with a message safe to show the cardholder.
    case declined(message: String?)

    /// The charge did not reach a terminal state in time.
    ///
    /// Not a decline: it may still settle, so the cardholder should check before retrying.
    case unresolved

    /// A 3D Secure challenge was required but could not be started.
    case threeDSecureUnavailable

    /// User-facing message for the toast surface, prefixed to match ``NetworkingError``.
    public func toastMessage() -> String {
        switch self {
        case .declined(let message):
            return "Error: \(message ?? "Your card was declined. Try another payment method.")"
        case .unresolved:
            return "Error: We could not confirm this payment. Check your bank before trying again."
        case .threeDSecureUnavailable:
            return "Error: Card verification could not be started. Please try again."
        }
    }
}

/// Errors that can be thrown when the Frame SDK is not configured correctly.
public enum FrameConfigurationError: Error {
    /// Apple Pay was requested but no merchant identifier has been set in the SDK configuration.
    case applePayMerchantIdNotConfigured
}
