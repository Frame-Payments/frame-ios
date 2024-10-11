//
//  CustomerEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

enum CustomerEndpoints: FrameNetworkingEndpoints {
    //MARK: Customer Endpoints
    case createCustomer
    case updateCustomer(customerId: String)
    case getCustomers
    case getCustomerWith(customerId: String)
    case searchCustomers
    case deleteCustomer(customerId: String)
    
    var endpointURL: String {
        switch self {
        case .createCustomer, .getCustomers:
            return "/v1/customers"
        case .updateCustomer(let customerId), .deleteCustomer(let customerId), .getCustomerWith(let customerId):
            return "/v1/customers/\(customerId)"
        case .searchCustomers:
            return "/v1/customers/search"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .createCustomer:
            return "POST"
        case .updateCustomer:
            return "PATCH"
        case .deleteCustomer:
            return "DELETE"
        default:
            return "GET"
        }
    }
}
