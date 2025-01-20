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
    case getSubscriptions(perPage: Int?, page : Int?)
    case getSubscription(subscriptionId: String)
    case searchSubscriptions
    case cancelSubscription(subscriptionId: String)
    
    var endpointURL: String {
        switch self {
        case .createSubscription, .getSubscriptions:
            return "/v1/subscriptions"
        case .getSubscription(let subscriptionId), .updateSubscription(let subscriptionId):
            return "/v1/subscriptions/\(subscriptionId)"
        case .searchSubscriptions:
            return "/v1/subscriptions/search"
        case .cancelSubscription(let subscriptionId):
            return "/v1/subscriptions/\(subscriptionId)/cancel"
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
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getSubscriptions(let perPage, let page):
            var queryItems: [URLQueryItem] = []
            if let perPage { queryItems.append(URLQueryItem(name: "per_page", value: "\(perPage)")) }
            if let page { queryItems.append(URLQueryItem(name: "page", value: "\(page)")) }
            return queryItems
        default:
            return []
        }
    }
}
