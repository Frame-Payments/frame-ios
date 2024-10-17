//
//  RefundEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

enum RefundEndpoints: FrameNetworkingEndpoints {
    //MARK: Customer Endpoints
    case createRefund
    case cancelRefund(refundId: String)
    case getRefunds(chargeId: String?, chargeIntentId: String?, perPage: Int?, page : Int?)
    case getRefundWith(refundId: String)
    
    var endpointURL: String {
        switch self {
        case .createRefund, .getRefunds:
            return "/v1/refunds"
        case .getRefundWith(let id):
            return "/v1/refunds/\(id)"
        case .cancelRefund(let id):
            return "/v1/refunds/\(id)/cancel"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .createRefund, .cancelRefund:
            return "POST"
        default:
            return "GET"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getRefunds(let chargeId, let chargeIntentId, let perPage, let page):
            var queryItems: [URLQueryItem] = []
            
            if let chargeId { queryItems.append(URLQueryItem(name: "charge", value: chargeId)) }
            if let chargeIntentId { queryItems.append(URLQueryItem(name: "charge_intent", value: chargeIntentId)) }
            if let perPage { queryItems.append(URLQueryItem(name: "per_page", value: "\(perPage)")) }
            if let page { queryItems.append(URLQueryItem(name: "page", value: "\(page)")) }
            
            return queryItems
        default:
            return []
        }
    }
}
