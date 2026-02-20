//
//  CapabilityEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

enum CapabilityEndpoints: FrameNetworkingEndpoints {
    //MARK: Capability Endpoints
    case getCapabilities(accountId: String)
    case requestCapabilities(accountId: String)
    case getCapabilityWith(accountId: String, name: String)
    case disableCapabilityWith(accountId: String, name: String)
    
    var endpointURL: String {
        switch self {
        case .getCapabilities(let accountId), .requestCapabilities(let accountId):
            return "/v1/accounts/\(accountId)/capabilities"
        case .getCapabilityWith(let accountId, let name), .disableCapabilityWith(let accountId, let name):
            return "/v1/accounts/\(accountId)/capabilities/\(name)"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .requestCapabilities:
            return .POST
        case .disableCapabilityWith:
            return .DELETE
        default:
            return .GET
        }
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
}
