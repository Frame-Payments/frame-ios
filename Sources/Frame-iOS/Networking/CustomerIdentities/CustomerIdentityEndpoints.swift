//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

enum CustomerIdentityEndpoints: FrameNetworkingEndpoints {
    //MARK: Customer Identity Endpoints
    case createCustomerIdentity
    case getCustomerIdentityWith(customerId: String)
    
    var endpointURL: String {
        switch self {
        case .createCustomerIdentity:
            return "/v1/customer_identity_verifications"
        case .getCustomerIdentityWith(let customerId):
            return "/v1/customer_identity_verifications\(customerId)"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .createCustomerIdentity:
            return "POST"
        default:
            return "GET"
        }
    }
    
    var queryItems: [URLQueryItem]? { return nil }
}
