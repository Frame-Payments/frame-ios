//
//  OnboardingOutcome.swift
//  Frame-iOS
//

import Foundation

/// How onboarding actually ended for the applicant.
///
/// Reaching the last step is not the same as passing verification.
public enum OnboardingOutcome: Sendable, Equatable {
    /// Every required capability is granted.
    case approved

    /// Outstanding, but no decision has been reached — a run under manual review counts here.
    case pendingReview

    /// Verification did not pass and retrying cannot change that.
    case declined(message: String?)

    /// Verification did not pass, but the applicant can still act on it.
    case actionRequired(message: String?)

    /// Whether this outcome should be reported to the host as a successful onboarding.
    public var isSuccess: Bool {
        self == .approved
    }
}

extension OnboardingOutcome {
    /// Maps a capability error's `failure_type` to the API's remediation category, mirroring
    /// `Accounts::IdentityVerifications::FailureTypes::CATEGORIES`.
    ///
    /// Unlisted codes fall through to ``unclassified``, which concludes nothing.
    private static let categoriesByFailureType: [String: String] = [
        "identity_mismatch": "retriable_with_new_data",
        "identity_not_found": "step_up",
        "verification_rejected": "terminal",
        "review_pending": "review",
        "provider_error": "transient",
        "signals_unavailable": "transient",
        "unclassified": "unclassified"
    ]

    /// Resolves the final outcome from the account's capabilities.
    ///
    /// - Parameters:
    ///   - capabilities: The capabilities returned by the account fetch.
    ///   - required: The capabilities this flow set out to satisfy; empty considers all of them.
    /// - Returns: The most demanding outcome among the outstanding capabilities.
    public static func resolve(from capabilities: [FrameObjects.Capability],
                               required: [FrameObjects.Capabilities]) -> OnboardingOutcome {
        let requiredNames = Set(required.map { $0.rawValue })
        let relevant = requiredNames.isEmpty
            ? capabilities
            : capabilities.filter { requiredNames.contains($0.name) }

        let outstanding = relevant.filter { $0.isOutstanding }
        guard !outstanding.isEmpty else { return .approved }

        // Ranked so a decline is never hidden behind a milder conclusion on another capability.
        var fallback: OnboardingOutcome = .pendingReview

        for capability in outstanding {
            guard let error = capability.errors?.first, let code = error.code else { continue }

            switch categoriesByFailureType[code] {
            case "terminal":
                return .declined(message: error.message)
            // `step_up` reports retriable: false but is not a decline — documents are the path.
            case "retriable_with_new_data", "step_up":
                fallback = .actionRequired(message: error.message)
            // `transient` and `review` are waits, not something the applicant can act on. So is an
            // unrecognized code: a type added server-side must not read as a demand for action.
            default:
                continue
            }
        }

        return fallback
    }
}
