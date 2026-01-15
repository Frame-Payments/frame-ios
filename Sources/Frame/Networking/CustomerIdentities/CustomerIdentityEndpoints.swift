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
    case createCustomerIdenityWith(customerId: String)
    case getCustomerIdentityWith(customerIdentityId: String)
    case submitForVerification(customerIdentityId: String)
    case uploadIdentityDocuments(customerIdentityId: String)
    
    var endpointURL: String {
        switch self {
        case .createCustomerIdentity:
            return "/v1/customer_identity_verifications"
        case .createCustomerIdenityWith(let customerId):
            return "/v1/customers/\(customerId)/identity_verifications"
        case .getCustomerIdentityWith(let customerIdentityId):
            return "/v1/customer_identity_verifications/\(customerIdentityId)"
        case .submitForVerification(let customerIdentityId):
            return "/v1/customer_identity_verifications/\(customerIdentityId)/submit"
        case .uploadIdentityDocuments(let customerIdentityId):
            return "/v1/customer_identity_verifications/\(customerIdentityId)/upload_documents"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .getCustomerIdentityWith:
            return .GET
        default:
            return .POST
        }
    }
    
    var queryItems: [URLQueryItem]? { return nil }
}
