//
//  OnboardingSessionEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 6/26/26.
//

import Foundation

enum OnboardingSessionEndpoints: FrameNetworkingEndpoints {
    //MARK: Onboarding Session Endpoints
    case createOnboardingSession

    var endpointURL: String {
        switch self {
        case .createOnboardingSession:
            return "/v1/onboarding_sessions"
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .createOnboardingSession:
            return .POST
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .createOnboardingSession:
            return nil
        }
    }
}
