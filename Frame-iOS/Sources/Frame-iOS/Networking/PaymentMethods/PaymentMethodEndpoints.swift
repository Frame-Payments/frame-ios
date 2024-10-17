//
//  FrameEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import Foundation

enum PaymentMethodEndpoints: FrameNetworkingEndpoints {
    //MARK: Payment Method Endpoints
    case getPaymentMethods(perPage: Int?, page : Int?)
    case getPaymentMethodWith(paymentMethodId: String)
    case getPaymentMethodsWithCustomer(customerId: String)
    case createPaymentMethod
    case updatePaymentMethodWith(paymentMethodId: String)
    case attachPaymentMethodWith(paymentMethodId: String)
    case detachPaymentMethodWith(paymentMethodId: String)
    
    var endpointURL: String {
        switch self {
        case .getPaymentMethods, .createPaymentMethod:
            return NetworkingConstants.endpoint + "/v1/payment_methods"
        case .getPaymentMethodWith(let paymentMethodId), .updatePaymentMethodWith(let paymentMethodId):
            return  NetworkingConstants.endpoint + "/v1/payment_methods/\(paymentMethodId)"
        case .getPaymentMethodsWithCustomer(let customerId):
            return  NetworkingConstants.endpoint + "/v1/customers/\(customerId)/payment_methods"
        case .attachPaymentMethodWith(let paymentMethodId):
            return  NetworkingConstants.endpoint + "/v1/payment_methods/\(paymentMethodId)/attach"
        case .detachPaymentMethodWith(let paymentMethodId):
            return  NetworkingConstants.endpoint + "/v1/payment_methods/\(paymentMethodId)/detach"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .createPaymentMethod, .attachPaymentMethodWith, .detachPaymentMethodWith:
            return "POST"
        case .updatePaymentMethodWith:
            return "PATCH"
        default:
            return "GET"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getPaymentMethods(let perPage, let page):
            var queryItems: [URLQueryItem] = []
            if let perPage { queryItems.append(URLQueryItem(name: "per_page", value: "\(perPage)")) }
            if let page { queryItems.append(URLQueryItem(name: "page", value: "\(page)")) }
            return queryItems
        default:
            return []
        }
    }
}
