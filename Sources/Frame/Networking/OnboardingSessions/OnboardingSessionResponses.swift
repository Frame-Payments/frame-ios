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
        @Lenient public private(set) var id: String?
        /// The account the session onboards.
        @Lenient public private(set) var accountId: String?
        /// The onboarding-session token (`onb_sess_…`) passed to ``OnboardingContainerView`` as its `clientSecret`.
        @Lenient public private(set) var clientSecret: String?
        /// Where the account holder is redirected after completion, if provided.
        @Lenient public private(set) var returnUrl: String?
        /// The ordered onboarding steps for the session.
        @Lenient public private(set) var steps: [String]?
        /// The object type. Always `"onboarding_session"`.
        @Lenient public private(set) var object: String?
        /// The Unix timestamp at which the session token expires.
        @Lenient public private(set) var expiresAt: Int?
        /// `true` for live-mode sessions, `false` in sandbox.
        @Lenient public private(set) var livemode: Bool?
        /// The hosted redirect URL for the account holder.
        @Lenient public private(set) var url: String?

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
