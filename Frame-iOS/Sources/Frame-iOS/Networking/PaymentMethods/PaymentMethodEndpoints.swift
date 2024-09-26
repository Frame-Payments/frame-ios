//
//  FrameEndpoints.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 9/26/24.
//

import Foundation

enum PaymentMethodEndpoints {
    //MARK: Payment Method Endpoints
    case getPaymentMethods
    case getPaymentMethodWith(id: String)
    case getPaymentMethodsWithCustomer(id: String)
    case createPaymentMethod
    case updatePaymentMethodWith(id: String)
    case attachPaymentMethodWith(id: String)
    case detachPaymentMethodWith(id: String)
    
    var endpointURL: String {
        switch self {
        case .getPaymentMethods, .createPaymentMethod:
            return "/v1/payment_methods"
        case .getPaymentMethodWith(let id), .updatePaymentMethodWith(let id):
            return "/v1/payment_methods/\(id)"
        case .getPaymentMethodsWithCustomer(let id):
            return "/v1/customers/\(id)/payment_methods"
        case .attachPaymentMethodWith(let id):
            return "/v1/payment_methods/\(id)/attach"
        case .detachPaymentMethodWith(let id):
            return "/v1/payment_methods/:id/detach"
        }
    }
    
    var requestType: String {
        switch self {
        case .getPaymentMethods, .getPaymentMethodWith, .getPaymentMethodsWithCustomer:
            return "GET"
        case .createPaymentMethod, .attachPaymentMethodWith, .detachPaymentMethodWith:
            return "POST"
        case .updatePaymentMethodWith(let id):
            return "PATCH"
        }
    }
}
