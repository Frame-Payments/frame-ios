//
//  ChargeIntentClientSecret.swift
//  Frame-iOS
//

import Foundation

/// A charge intent's `client_secret`, parsed into the pieces the API expects separately.
///
/// The secret is a single opaque string to integrators (`ci_<id>_secret_<token>`), but the
/// confirm and retrieve calls need the bare resource id for the URL path and the full secret
/// for the request body. Parsing once, at the boundary, keeps that split in one place.
///
/// The resource id is the bare UUID: the `ci_` prefix belongs to the secret, not to the
/// charge intent, and a URL built from the unstripped string 404s.
public struct ChargeIntentClientSecret: Sendable, Equatable {
    /// The secret exactly as issued, for the request body.
    ///
    /// A credential authorizing one charge confirmation. Never log or persist it.
    public let value: String

    /// The bare charge-intent resource id, for the URL path.
    public let chargeIntentID: String

    /// Parses a `client_secret` issued by the Frame API.
    ///
    /// - Parameter value: The secret, in the form `ci_<id>_secret_<token>`.
    /// - Throws: ``FrameChargeIntentError/invalidClientSecret`` when the string is not a
    ///   charge-intent secret. Failing here, at the call site, beats a confusing 404 or 401
    ///   several calls later.
    public init(_ value: String) throws {
        guard value.hasPrefix("ci_") else {
            throw FrameChargeIntentError.invalidClientSecret
        }

        // Everything before "_secret_" is the prefixed id; a secret without the marker is
        // treated as the id alone, matching the browser SDK.
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
    /// The supplied string is not a charge-intent `client_secret` (`ci_<id>_secret_…`).
    case invalidClientSecret

    /// The charge intent reported that a 3D Secure challenge is required, but the response
    /// carried no challenge session to present.
    case missingThreeDSecureChallenge

    /// The 3D Secure challenge could not be loaded or presented.
    ///
    /// Distinct from the cardholder failing a challenge that did run: this means the challenge
    /// never ran, which is worth retrying.
    case threeDSecureUnavailable(underlying: Error?)

    /// The charge intent's status could not be retrieved after exhausting every attempt.
    ///
    /// Distinct from ``FrameChargeIntentOutcome/timedOut``: here the API was unreachable, so
    /// the charge's state is unknown for a different reason.
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
/// Replaces the browser SDK's `PaymentCompletion` (a `hasError` flag beside an optional
/// error, where the error can be absent even when `hasError` is true). The cases below carry
/// the same information without letting a caller branch on the wrong field:
///
/// - `succeeded` covers both `succeeded` and `requires_capture`, which the browser SDK also
///   treats as terminal-success.
/// - `failed` carries the intent plus an *optional* reason, because a terminal `failed` with
///   no `latest_charge` is a real response.
/// - `timedOut` is the browser SDK's `confirmation_timeout` completion: returned, not thrown,
///   because the charge may still settle and the caller should re-check rather than retry.
public enum FrameChargeIntentOutcome: Sendable, Equatable {
    /// The charge was captured, or authorized and awaiting a merchant-initiated capture.
    case succeeded(FrameObjects.ChargeIntent)

    /// The charge reached a terminal failure.
    ///
    /// - Parameters:
    ///   - intent: The failed charge intent.
    ///   - reason: The decline reason from `latest_charge`, absent when the API gave none.
    case failed(FrameObjects.ChargeIntent, reason: FrameChargeFailureReason?)

    /// Every attempt returned a non-terminal status.
    ///
    /// The charge is not known to have failed — it may still settle server-side.
    case timedOut

    /// Builds the outcome for an intent already known to be in a terminal state.
    ///
    /// - Parameter intent: A charge intent whose status satisfies
    ///   ``FrameObjects/ChargeIntentStatus/isTerminal``.
    /// - Returns: The matching outcome, or `nil` if the status is not terminal.
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
    /// A machine-readable failure code (e.g. `"card_declined"`), when the API supplied one.
    public let code: String?
    /// A human-readable message safe to show the cardholder.
    public let message: String?

    /// Extracts the failure reason from a charge intent, if it carries one.
    ///
    /// - Parameter intent: The failed charge intent.
    /// - Returns: `nil` when the intent has no `latest_charge` and no failure description,
    ///   which the API does return for some terminal failures.
    init?(intent: FrameObjects.ChargeIntent) {
        let code = intent.latestCharge?.failureCode
        let message = intent.latestCharge?.failureMessage ?? intent.failureDescription
        // A terminal `failed` can arrive with neither, which is why the caller sees an optional
        // reason rather than a placeholder one.
        guard code != nil || message != nil else { return nil }
        self.code = code
        self.message = message
    }
}
