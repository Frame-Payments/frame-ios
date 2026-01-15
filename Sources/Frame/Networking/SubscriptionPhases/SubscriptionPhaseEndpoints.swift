//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

enum SubscriptionPhaseEndpoints: FrameNetworkingEndpoints {
    //MARK: Subscription Endpoints
    case createSubscriptionPhase(subscriptionId: String)
    case updateSubscriptionPhaseWith(subscriptionId: String, phaseId: String)
    case getAllSubscriptionPhases(subscriptionId: String)
    case getSubscriptionPhaseWith(subscriptionId: String, phaseId: String)
    case deleteSubscriptionPhase(subscriptionId: String, phaseId: String)
    case bulkUpdateSubscriptionPhases(subscriptionId: String)
    
    var endpointURL: String {
        switch self {
        case .createSubscriptionPhase(let subscriptionId), .getAllSubscriptionPhases(let subscriptionId):
            return "/v1/subscriptions/\(subscriptionId)/phases"
        case .getSubscriptionPhaseWith(let subscriptionId, let phaseId), .updateSubscriptionPhaseWith(let subscriptionId, let phaseId), .deleteSubscriptionPhase(let subscriptionId, let phaseId):
            return "/v1/subscriptions/\(subscriptionId)/phases/\(phaseId)"
        case .bulkUpdateSubscriptionPhases(let subscriptionId):
            return "/v1/subscriptions/\(subscriptionId)/phases/bulk_update"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .createSubscriptionPhase:
            return .POST
        case .updateSubscriptionPhaseWith, .bulkUpdateSubscriptionPhases:
            return .PATCH
        case .deleteSubscriptionPhase:
            return .DELETE
        default:
            return .GET
        }
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
}
