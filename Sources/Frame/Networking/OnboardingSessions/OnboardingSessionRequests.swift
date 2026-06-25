//
//  OnboardingSessionRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 6/26/26.
//

import Foundation

/// Request body namespace for Onboarding Session API calls.
///
/// - Warning: Creating an onboarding session is a **server-only** operation that requires your
///   secret key (`sk_`). It is exposed here only so the example app can mint a session token for
///   end-to-end testing. Production integrations must mint the token from their backend
///   (`POST /v1/onboarding_sessions`) and hand the resulting `onb_sess_…` to the app.
public class OnboardingSessionRequest {

    /// Request body for creating an onboarding session.
    public struct CreateOnboardingSessionRequest: Codable {
        /// The existing Frame account the session onboards.
        public let accountId: String
        /// The ordered onboarding steps to present, or `nil` to use the account's defaults.
        public let steps: [OnboardingSessionStep]?
        /// Where the account holder is redirected after completing the flow, or `nil`.
        public let returnUrl: String?

        enum CodingKeys: String, CodingKey {
            case accountId = "account_id"
            case steps
            case returnUrl = "return_url"
        }

        /// Creates a new onboarding-session request body.
        /// - Parameters:
        ///   - accountId: The existing Frame account the session onboards.
        ///   - steps: The ordered onboarding steps to present, or `nil` for the account defaults.
        ///   - returnUrl: Redirect destination after completion, or `nil`.
        public init(accountId: String, steps: [OnboardingSessionStep]? = nil, returnUrl: String? = nil) {
            self.accountId = accountId
            self.steps = steps
            self.returnUrl = returnUrl
        }
    }

    /// An onboarding step the session can require.
    public enum OnboardingSessionStep: String, Codable {
        /// Identity verification (KYC).
        case idVerification = "id_verification"
        /// Geographic-compliance verification.
        case geoCompliance = "geo_compliance"
        /// Payment-method collection.
        case paymentMethod = "payment_method"
    }
}
