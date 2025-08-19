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
    case getCustomerIdentityWith(customerIdentityId: String)
    
    var endpointURL: String {
        switch self {
        case .createCustomerIdentity:
            return "/v1/customer_identity_verifications"
        case .getCustomerIdentityWith(let customerIdentityId):
            return "/v1/customer_identity_verifications/\(customerIdentityId)"
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
