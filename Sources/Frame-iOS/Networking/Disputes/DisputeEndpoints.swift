//
//  DisputeEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/5/25.
//

import Foundation

enum DisputeEndpoints: FrameNetworkingEndpoints {
    case updateDispute(disputeId: String)
    case getDispute(disputeId: String)
    case getDisputes(chargeId: String?, chargeIntentId: String?, perPage: Int?, page: Int?)
    case closeDispute(disputeId: String)
    
    var endpointURL: String {
        switch self {
        case .updateDispute(let disputeId), .getDispute(let disputeId):
            return "/v1/disputes/\(disputeId)"
        case .getDisputes:
            return "/v1/disputes/"
        case .closeDispute(let disputeId):
            return "/v1/disputes/\(disputeId)/close"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .updateDispute:
            return "PATCH"
        case .closeDispute:
            return "POST"
        default:
            return "GET"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getDisputes(let chargeId, let chargeIntentId, let perPage, let page):
            var queryItems: [URLQueryItem] = []
            
            if let chargeId { queryItems.append(URLQueryItem(name: "charge", value: chargeId)) }
            if let chargeIntentId { queryItems.append(URLQueryItem(name: "charge_intent", value: chargeIntentId)) }
            if let perPage { queryItems.append(URLQueryItem(name: "per_page", value: "\(perPage)")) }
            if let page { queryItems.append(URLQueryItem(name: "page", value: "\(page)")) }
            
            return queryItems
        default:
            return nil
        }
    }
}
