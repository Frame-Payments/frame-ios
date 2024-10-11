//
//  ChargeEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/11/24.
//

import Foundation

enum ChargeEndpoints: FrameNetworkingEndpoints {
    //MARK: Charge Intents Endpoints
    case cancelCharge(intentId: String)
    case captureCharge(intentId: String)
    case confirmCharge(intentId: String)
    case createCharge
    case getCharge(intentId: String)
    case getAllCharges
    case updateCharge(intentId: String)
    
    var endpointURL: String {
        switch self {
        case .cancelCharge(let intentId):
            return "/v1/charge_intents/\(intentId)/cancel"
        case .captureCharge(let intentId):
            return "/v1/charge_intents/\(intentId)/capture"
        case .confirmCharge(let intentId):
            return "/v1/charge_intents/\(intentId)/confirm"
        case .getCharge(let intentId), .updateCharge(let intentId):
            return "/v1/charge_intents/\(intentId)"
        case .getAllCharges, .createCharge:
            return "/v1/charge_intents/"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .createCharge, .cancelCharge, .captureCharge, .confirmCharge:
            return "POST"
        case .updateCharge:
            return "PATCH"
        default:
            return "GET"
        }
    }
}
