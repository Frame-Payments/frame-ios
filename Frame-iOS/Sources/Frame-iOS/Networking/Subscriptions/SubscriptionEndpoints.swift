//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/27/24.
//

import Foundation

enum SubscriptionEndpoints: FrameNetworkingEndpoints {
    //MARK: Subscription Endpoints
    case createSubscription
    case updateSubscription(id: String)
    case getSubscriptions
    case getSubscription(id: String)
    case searchSubscriptions
    case cancelSubscription(id: String)
    
    var endpointURL: String {
        switch self {
        case .createSubscription, .getSubscriptions:
            return NetworkingConstants.endpoint + "/v1/subscriptions"
        case .getSubscription(let id), .updateSubscription(let id):
            return NetworkingConstants.endpoint + "/v1/subscriptions/\(id)"
        case .searchSubscriptions:
            return NetworkingConstants.endpoint + "/v1/subscriptions/search"
        case .cancelSubscription(let id):
            return NetworkingConstants.endpoint + "/v1/subscriptions/\(id)/cancel"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .createSubscription, .cancelSubscription:
            return "POST"
        case .updateSubscription(let id):
            return "PATCH"
        default:
            return "GET"
        }
    }
}
