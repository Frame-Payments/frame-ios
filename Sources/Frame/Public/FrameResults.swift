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
    case completed(id: String)
    case cancelled
    case failed(Error)
}

public enum FrameConfigurationError: Error {
    case applePayMerchantIdNotConfigured
}
