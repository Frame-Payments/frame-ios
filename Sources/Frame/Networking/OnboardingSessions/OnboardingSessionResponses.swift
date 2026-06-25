//
//  OnboardingSessionResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 6/26/26.
//

import Foundation

/// Response model namespace for Onboarding Session API calls.
public class OnboardingSessionResponses {

    /// The onboarding session returned by `POST /v1/onboarding_sessions`.
    public struct OnboardingSession: Codable {
        /// The unique identifier of the onboarding session.
        public let id: String?
        /// The account the session onboards.
        public let accountId: String?
        /// The onboarding-session token (`onb_sess_…`) passed to ``OnboardingContainerView`` as its `clientSecret`.
        public let clientSecret: String?
        /// Where the account holder is redirected after completion, if provided.
        public let returnUrl: String?
        /// The ordered onboarding steps for the session.
        public let steps: [String]?
        /// The object type. Always `"onboarding_session"`.
        public let object: String?
        /// The Unix timestamp at which the session token expires.
        public let expiresAt: Int?
        /// `true` for live-mode sessions, `false` in sandbox.
        public let livemode: Bool?
        /// The hosted redirect URL for the account holder.
        public let url: String?

        enum CodingKeys: String, CodingKey {
            case id
            case accountId = "account_id"
            case clientSecret = "client_secret"
            case returnUrl = "return_url"
            case steps
            case object
            case expiresAt = "expires_at"
            case livemode
            case url
        }
    }
}
