//
//  SessionEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/30/25.
//

import Foundation
import Frame_iOS

enum SessionEndpoints: FrameNetworkingEndpoints {
    //MARK: Onboarding Session Endpoints
    case createOnboardingSession
    case getOnboardingSessionWithCustomer(customerId: String)
    case cancelOnboardingSession(sessionId: String)
    
    var endpointURL: String {
        switch self {
        case .createOnboardingSession, .getOnboardingSessionWithCustomer:
            return "/v1/onboarding/sessions"
        case .cancelOnboardingSession(let sessionId):
            return "/v1/onboarding/sessions/\(sessionId)"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .createOnboardingSession:
            return .POST
        case .cancelOnboardingSession:
            return .PATCH
        default:
            return .GET
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
