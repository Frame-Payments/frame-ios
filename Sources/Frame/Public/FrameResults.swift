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

/// Errors that can be thrown when the Frame SDK is not configured correctly.
public enum FrameConfigurationError: Error {
    /// Apple Pay was requested but no merchant identifier has been set in the SDK configuration.
    case applePayMerchantIdNotConfigured
}
