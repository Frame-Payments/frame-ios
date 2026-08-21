//
//  ChargeIntentClientSecret.swift
//  Frame-iOS
//

import Foundation

/// A charge intent's `client_secret`, split into the pieces the API expects separately.
///
/// The confirm and retrieve calls need the bare resource id for the URL path and the full
/// secret for the request body. The `ci_` prefix belongs to the secret, not to the charge
/// intent, and a URL built from the unstripped string 404s.
public struct ChargeIntentClientSecret: Sendable, Equatable {
    /// The secret exactly as issued. A credential authorizing one confirmation: never log it.
    public let value: String

    /// The bare charge-intent resource id, for the URL path.
    public let chargeIntentID: String

    /// Parses a `client_secret` of the form `ci_<id>_secret_<token>`.
    ///
    /// - Parameter value: The secret as issued by the Frame API.
    /// - Throws: ``FrameChargeIntentError/invalidClientSecret`` when `value` is not a
    ///   charge-intent secret, so a mistyped one fails here rather than as a later 404.
    public init(_ value: String) throws {
        guard value.hasPrefix("ci_") else {
            throw FrameChargeIntentError.invalidClientSecret
        }

        // A secret without the marker is treated as the id alone, matching the browser SDK.
        let withoutSecret: String
        if let marker = value.range(of: "_secret_"), marker.lowerBound > value.startIndex {
            withoutSecret = String(value[value.startIndex..<marker.lowerBound])
        } else {
            withoutSecret = value
        }

        let id = String(withoutSecret.dropFirst("ci_".count))
        guard !id.isEmpty else {
            throw FrameChargeIntentError.invalidClientSecret
        }

        self.value = value
        self.chargeIntentID = id
    }
}

/// Errors raised while confirming a charge intent from the app.
public enum FrameChargeIntentError: Error, Equatable {
    /// The string is not a charge-intent `client_secret` (`ci_<id>_secret_…`).
    case invalidClientSecret

    /// The intent requires 3D Secure but carried no challenge session to present.
    case missingThreeDSecureChallenge

    /// The challenge never ran. Distinct from the cardholder failing one that did, and retryable.
    case threeDSecureUnavailable(underlying: Error?)

    /// The status could not be read after every attempt, so the charge's state is unknown.
    case statusUnavailable(attempts: Int, underlying: Error?)

    public static func == (lhs: FrameChargeIntentError, rhs: FrameChargeIntentError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidClientSecret, .invalidClientSecret),
             (.missingThreeDSecureChallenge, .missingThreeDSecureChallenge),
             (.threeDSecureUnavailable, .threeDSecureUnavailable):
            return true
        case (.statusUnavailable(let l, _), .statusUnavailable(let r, _)):
            return l == r
        default:
            return false
        }
    }
}

/// The result of confirming a charge intent from the app.
///
/// Replaces the browser SDK's `PaymentCompletion`, whose `hasError` flag sits beside an
/// optional error that can be absent even when the flag is set.
public enum FrameChargeIntentOutcome: Sendable, Equatable {
    /// Captured, or authorized and awaiting a merchant-initiated capture.
    case succeeded(FrameObjects.ChargeIntent)

    /// A terminal failure. `reason` is absent when the API gave no `latest_charge`.
    case failed(FrameObjects.ChargeIntent, reason: FrameChargeFailureReason?)

    /// Every attempt returned a non-terminal status. The charge may still settle.
    case timedOut

    static func terminalOutcome(for intent: FrameObjects.ChargeIntent) -> FrameChargeIntentOutcome? {
        switch intent.status {
        case .succeeded, .requiresCapture:
            return .succeeded(intent)
        case .failed:
            return .failed(intent, reason: FrameChargeFailureReason(intent: intent))
        default:
            return nil
        }
    }
}

/// Why a charge failed, as reported by the API's `latest_charge`.
public struct FrameChargeFailureReason: Sendable, Equatable {
    /// A machine-readable failure code (e.g. `"card_declined"`).
    public let code: String?
    /// A human-readable message safe to show the cardholder.
    public let message: String?

    /// Returns `nil` for a terminal failure that carried no reason at all, which the API does send.
    init?(intent: FrameObjects.ChargeIntent) {
        let code = intent.latestCharge?.failureCode
        let message = intent.latestCharge?.failureMessage ?? intent.failureDescription
        guard code != nil || message != nil else { return nil }
        self.code = code
        self.message = message
    }
}
