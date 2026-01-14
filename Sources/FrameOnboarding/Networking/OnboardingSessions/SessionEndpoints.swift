//
//  SessionEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/30/25.
//

import Foundation
import Frame

enum SessionEndpoints: FrameNetworkingEndpoints {
    //MARK: Onboarding Session Endpoints
    case createOnboardingSession
    case getOnboardingSessionWithCustomer(customerId: String)
    case cancelOnboardingSession(sessionId: String)
    case updatePayoutMethod(sessionId: String)
    
    var endpointURL: String {
        switch self {
        case .createOnboardingSession, .getOnboardingSessionWithCustomer:
            return "/v1/onboarding/sessions"
        case .cancelOnboardingSession(let sessionId):
            return "/v1/onboarding/sessions/\(sessionId)"
        case .updatePayoutMethod(let sessionId):
            return "/v1/onboarding/sessions/\(sessionId)/payout"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .getOnboardingSessionWithCustomer:
            return .GET
        case .cancelOnboardingSession:
            return .PATCH
        default:
            return .POST
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getOnboardingSessionWithCustomer(let customerId):
            var queryItems: [URLQueryItem] = []
            queryItems.append(URLQueryItem(name: "customer_id", value: customerId))
            queryItems.append(URLQueryItem(name: "status", value: "in_progress"))
            queryItems.append(URLQueryItem(name: "limit", value: "1"))
            return queryItems
        default:
            return nil
        }
    }
}
