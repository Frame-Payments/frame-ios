
//
//  ProductEndpoints.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/1/25.
//

import Foundation

enum ProductEndpoints: FrameNetworkingEndpoints {
    //MARK: Product Endpoints
    case createProduct
    case updateProduct(productId: String)
    case getProducts(perPage: Int?, page : Int?)
    case getProduct(productId: String)
    case searchProduct(name: String?, active: Bool?, shippable: Bool?)
    case deleteProduct(productId: String)
    
    var endpointURL: String {
        switch self {
        case .createProduct, .getProducts:
            return "/v1/products"
        case .updateProduct(let id), .getProduct(let id), .deleteProduct(let id):
            return "/v1/products/\(id)"
        case .searchProduct:
            return "/v1/products/search"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .createProduct:
            return "POST"
        case .updateProduct:
            return "PATCH"
        case .deleteProduct:
            return "DELETE"
        default:
            return "GET"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getProducts(let perPage, let page):
            var queryItems: [URLQueryItem] = []
            
            if let perPage { queryItems.append(URLQueryItem(name: "per_page", value: "\(perPage)")) }
            if let page { queryItems.append(URLQueryItem(name: "page", value: "\(page)")) }
            
            return queryItems
        case .searchProduct(let name, let active, let shippable):
            var queryItems: [URLQueryItem] = []
            
            if let name { queryItems.append(URLQueryItem(name: "name", value: name)) }
            if let active { queryItems.append(URLQueryItem(name: "active", value: active.description)) }
            if let shippable { queryItems.append(URLQueryItem(name: "shippable", value: shippable.description)) }
            
            return queryItems
        default:
            return nil
        }
    }
}
