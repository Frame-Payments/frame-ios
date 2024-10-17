//
//  ChargeEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/11/24.
//

import Foundation

enum ChargeIntentEndpoints: FrameNetworkingEndpoints {
    //MARK: Charge Intents Endpoints
    case cancelChargeIntent(intentId: String)
    case captureChargeIntent(intentId: String)
    case confirmChargeIntent(intentId: String)
    case createChargeIntent
    case getChargeIntent(intentId: String)
    case getAllChargeIntents(perPage: Int?, page : Int?)
    case updateChargeIntent(intentId: String)
    
    var endpointURL: String {
        switch self {
        case .cancelChargeIntent(let intentId):
            return "/v1/charge_intents/\(intentId)/cancel"
        case .captureChargeIntent(let intentId):
            return "/v1/charge_intents/\(intentId)/capture"
        case .confirmChargeIntent(let intentId):
            return "/v1/charge_intents/\(intentId)/confirm"
        case .getChargeIntent(let intentId), .updateChargeIntent(let intentId):
            return "/v1/charge_intents/\(intentId)"
        case .getAllChargeIntents, .createChargeIntent:
            return "/v1/charge_intents/"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .createChargeIntent, .cancelChargeIntent, .captureChargeIntent, .confirmChargeIntent:
            return "POST"
        case .updateChargeIntent:
            return "PATCH"
        default:
            return "GET"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getAllChargeIntents(let perPage, let page):
            var queryItems: [URLQueryItem] = []
            if let perPage { queryItems.append(URLQueryItem(name: "per_page", value: "\(perPage)")) }
            if let page { queryItems.append(URLQueryItem(name: "page", value: "\(page)")) }
            return queryItems
        default:
            return []
        }
    }
}
