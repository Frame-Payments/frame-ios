//
//  IdentityVerificationEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments.
//
//  Identity-verification (IDV) endpoints backing the no-SSN government-ID flow.
//  The onboarding-session token (onb_sess_…) authenticates these requests via the
//  active onboarding session, so no accountId is embedded in the path.
//

import Foundation
import Frame

enum IdentityVerificationEndpoints: FrameNetworkingEndpoints {
    /// Creates a Persona inquiry server-side and returns its `inquiry_id`.
    case createSession
    /// Confirms verification for a completed Persona inquiry (JSON variant).
    case complete

    var endpointURL: String {
        switch self {
        case .createSession:
            return "/idv/session"
        case .complete:
            return "/idv/complete"
        }
    }

    var httpMethod: HTTPMethod {
        return .POST
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }

    var acceptHeader: String? {
        switch self {
        case .createSession:
            return nil
        case .complete:
            // The /idv/complete endpoint returns HTML by default; request the JSON
            // variant explicitly (see FRA-5363).
            return "application/json"
        }
    }
}
