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
    case updateSubscription(subscriptionId: String)
    case getSubscriptions
    case getSubscription(subscriptionId: String)
    case searchSubscriptions
    case cancelSubscription(subscriptionId: String)
    
    var endpointURL: String {
        switch self {
        case .createSubscription, .getSubscriptions:
            return NetworkingConstants.endpoint + "/v1/subscriptions"
        case .getSubscription(let subscriptionId), .updateSubscription(let subscriptionId):
            return NetworkingConstants.endpoint + "/v1/subscriptions/\(subscriptionId)"
        case .searchSubscriptions:
            return NetworkingConstants.endpoint + "/v1/subscriptions/search"
        case .cancelSubscription(let subscriptionId):
            return NetworkingConstants.endpoint + "/v1/subscriptions/\(subscriptionId)/cancel"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .createSubscription, .cancelSubscription:
            return "POST"
        case .updateSubscription:
            return "PATCH"
        default:
            return "GET"
        }
    }
}
