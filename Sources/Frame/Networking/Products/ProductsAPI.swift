//
//  ProductsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/1/25.
//

import Foundation

// https://docs.framepayments.com/api/products

// Protocol for Mock Testing
protocol ProductsProtocol {
    // async/await
    static func createProduct(request: ProductRequests.CreateProductRequest) async throws -> (FrameObjects.Product?, NetworkingError?)
    static func updateProduct(productId: String, request: ProductRequests.UpdateProductRequest)  async throws -> (FrameObjects.Product?, NetworkingError?)
    static func getProducts(perPage: Int?, page : Int?) async throws -> (ProductResponses.ListProductsResponse?, NetworkingError?)
    static func getProduct(productId: String) async throws -> (FrameObjects.Product?, NetworkingError?)
    static func searchProduct(name: String?, active: Bool?, shippable: Bool?) async throws -> (ProductResponses.SearchProductResponse?, NetworkingError?)
    static func deleteProduct(productId: String) async throws -> (ProductResponses.DeleteProductResponse?, NetworkingError?)
    
    // completionHandlers
    static func createProduct(request: ProductRequests.CreateProductRequest, completionHandler: @escaping @Sendable (FrameObjects.Product?, NetworkingError?) -> Void)
    static func updateProduct(productId: String, request: ProductRequests.UpdateProductRequest, completionHandler: @escaping @Sendable (FrameObjects.Product?, NetworkingError?) -> Void)
    static func getProducts(perPage: Int?, page : Int?, completionHandler: @escaping @Sendable (ProductResponses.ListProductsResponse?, NetworkingError?) -> Void)
    static func getProduct(productId: String, completionHandler: @escaping @Sendable (FrameObjects.Product?, NetworkingError?) -> Void)
    static func searchProduct(name: String?, active: Bool?, shippable: Bool?, completionHandler: @escaping @Sendable (ProductResponses.SearchProductResponse?, NetworkingError?) -> Void)
    static func deleteProduct(productId: String, completionHandler: @escaping @Sendable (ProductResponses.DeleteProductResponse?, NetworkingError?) -> Void)
}

// Products API
public class ProductsAPI: ProductsProtocol, @unchecked Sendable {
    // async/await
    static func createProduct(request: ProductRequests.CreateProductRequest) async throws -> (FrameObjects.Product?, NetworkingError?) {
        let endpoint = ProductEndpoints.createProduct
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Product.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func updateProduct(productId: String, request: ProductRequests.UpdateProductRequest) async throws -> (FrameObjects.Product?, NetworkingError?) {
        let endpoint = ProductEndpoints.updateProduct(productId: productId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Product.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func getProducts(perPage: Int?, page: Int?) async throws -> (ProductResponses.ListProductsResponse?, NetworkingError?) {
        let endpoint = ProductEndpoints.getProducts(perPage: perPage, page: page)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductResponses.ListProductsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func getProduct(productId: String) async throws -> (FrameObjects.Product?, NetworkingError?) {
        let endpoint = ProductEndpoints.getProduct(productId: productId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Product.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func searchProduct(name: String?, active: Bool?, shippable: Bool?) async throws -> (ProductResponses.SearchProductResponse?, NetworkingError?) {
        let endpoint = ProductEndpoints.searchProduct(name: name, active: active, shippable: shippable)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductResponses.SearchProductResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    static func deleteProduct(productId: String) async throws -> (ProductResponses.DeleteProductResponse?, NetworkingError?) {
        let endpoint = ProductEndpoints.deleteProduct(productId: productId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductResponses.DeleteProductResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    // completionHandlers
    static func createProduct(request: ProductRequests.CreateProductRequest, completionHandler: @escaping @Sendable (FrameObjects.Product?, NetworkingError?) -> Void) {
        let endpoint = ProductEndpoints.createProduct
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Product.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func updateProduct(productId: String, request: ProductRequests.UpdateProductRequest, completionHandler: @escaping @Sendable (FrameObjects.Product?, NetworkingError?) -> Void) {
        let endpoint = ProductEndpoints.updateProduct(productId: productId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Product.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func getProducts(perPage: Int?, page: Int?, completionHandler: @escaping @Sendable (ProductResponses.ListProductsResponse?, NetworkingError?) -> Void) {
        let endpoint = ProductEndpoints.getProducts(perPage: perPage, page: page)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductResponses.ListProductsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func getProduct(productId: String, completionHandler: @escaping @Sendable (FrameObjects.Product?, NetworkingError?) -> Void) {
        let endpoint = ProductEndpoints.getProduct(productId: productId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Product.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func searchProduct(name: String?, active: Bool?, shippable: Bool?, completionHandler: @escaping @Sendable (ProductResponses.SearchProductResponse?, NetworkingError?) -> Void) {
        let endpoint = ProductEndpoints.searchProduct(name: name, active: active, shippable: shippable)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductResponses.SearchProductResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    static func deleteProduct(productId: String, completionHandler: @escaping @Sendable (ProductResponses.DeleteProductResponse?, NetworkingError?) -> Void) {
        let endpoint = ProductEndpoints.deleteProduct(productId: productId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductResponses.DeleteProductResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
