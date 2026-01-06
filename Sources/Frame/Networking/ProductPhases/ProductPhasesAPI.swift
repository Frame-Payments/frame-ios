//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/3/25.
//

import Foundation

// https://docs.framepayments.com/api/product_phases

protocol ProductPhasesProtocol {
    //async/await
    static func listAllProductPhases(productId: String) async throws -> (ProductPhasesResponses.ListProductPhasesResponse?, NetworkingError?)
    static func getProductPhase(productId: String, phaseId: String) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)
    static func createProductPhase(productId: String, request: ProductPhaseRequests.CreateProductPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)
    static func updateProductPhase(productId: String, phaseId: String, request: ProductPhaseRequests.UpdateProductPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)
    static func deleteProductPhase(productId: String, phaseId: String) async throws -> (NetworkingError?)
    static func bulkUpdateProductPhases(productId: String, request: ProductPhaseRequests.BulkUpdateProductPhase) async throws -> (ProductPhasesResponses.ListProductPhasesResponse?, NetworkingError?)
    
    // completionHandlers
    static func listAllProductPhases(productId: String, completionHandler: @escaping @Sendable (ProductPhasesResponses.ListProductPhasesResponse?, NetworkingError?) -> Void)
    static func getProductPhase(productId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)
    static func createProductPhase(productId: String, request: ProductPhaseRequests.CreateProductPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)
    static func updateProductPhase(productId: String, phaseId: String, request: ProductPhaseRequests.UpdateProductPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)
    static func deleteProductPhase(productId: String, phaseId: String, completionHandler: @escaping @Sendable (NetworkingError?) -> Void)
    static func bulkUpdateProductPhases(productId: String, request: ProductPhaseRequests.BulkUpdateProductPhase, completionHandler: @escaping @Sendable (ProductResponses.ListProductsResponse?, NetworkingError?) -> Void)
}

// Product Phases API
public class ProductPhasesAPI: ProductPhasesProtocol, @unchecked Sendable {
    // async/await
    public static func listAllProductPhases(productId: String) async throws -> (ProductPhasesResponses.ListProductPhasesResponse?, NetworkingError?) {
        guard productId != "" else { return (nil, nil) }
        let endpoint = ProductPhaseEndpoints.getAllProductPhases(productId: productId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductPhasesResponses.ListProductPhasesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getProductPhase(productId: String, phaseId: String) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard productId != "" && phaseId != "" else { return (nil, nil) }
        let endpoint = ProductPhaseEndpoints.getProductPhaseWith(productId: productId, phaseId: phaseId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func createProductPhase(productId: String, request: ProductPhaseRequests.CreateProductPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard productId != "" else { return (nil, nil) }
        let endpoint = ProductPhaseEndpoints.createProductPhase(productId: productId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func updateProductPhase(productId: String, phaseId: String, request: ProductPhaseRequests.UpdateProductPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard productId != "" && phaseId != "" else { return (nil, nil) }
        let endpoint = ProductPhaseEndpoints.updateProductPhaseWith(productId: productId, phaseId: phaseId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func deleteProductPhase(productId: String, phaseId: String) async throws -> (NetworkingError?) {
        guard productId != "" && phaseId != "" else { return (nil) }
        let endpoint = ProductPhaseEndpoints.deleteProductPhase(productId: productId, phaseId: phaseId)
        
        let (_, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        return error
    }
    
    public static func bulkUpdateProductPhases(productId: String, request: ProductPhaseRequests.BulkUpdateProductPhase) async throws -> (ProductPhasesResponses.ListProductPhasesResponse?, NetworkingError?) {
        guard productId != "" else { return (nil, nil) }
        let endpoint = ProductPhaseEndpoints.bulkUpdateProductPhases(productId: productId)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductPhasesResponses.ListProductPhasesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    // completionHandlers
    public static func listAllProductPhases(productId: String, completionHandler: @escaping @Sendable (ProductPhasesResponses.ListProductPhasesResponse?, NetworkingError?) -> Void) {
        guard productId != "" else { return completionHandler(nil, nil) }
        let endpoint = ProductPhaseEndpoints.getAllProductPhases(productId: productId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductPhasesResponses.ListProductPhasesResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getProductPhase(productId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard productId != "", phaseId != "" else { return completionHandler(nil, nil) }
        let endpoint = ProductPhaseEndpoints.getProductPhaseWith(productId: productId, phaseId: phaseId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func createProductPhase(productId: String, request: ProductPhaseRequests.CreateProductPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard productId != "" else { return completionHandler(nil, nil) }
        let endpoint = ProductPhaseEndpoints.createProductPhase(productId: productId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func updateProductPhase(productId: String, phaseId: String, request: ProductPhaseRequests.UpdateProductPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard productId != "", phaseId != "" else { return completionHandler(nil, nil) }
        let endpoint = ProductPhaseEndpoints.updateProductPhaseWith(productId: productId, phaseId: phaseId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func deleteProductPhase(productId: String, phaseId: String, completionHandler: @escaping @Sendable (NetworkingError?) -> Void) {
        guard productId != "", phaseId != "" else { return completionHandler(nil) }
        let endpoint = ProductPhaseEndpoints.deleteProductPhase(productId: productId, phaseId: phaseId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            completionHandler(error)
        }
    }
    
    public static func bulkUpdateProductPhases(productId: String, request: ProductPhaseRequests.BulkUpdateProductPhase, completionHandler: @escaping @Sendable (ProductResponses.ListProductsResponse?, NetworkingError?) -> Void) {
        guard productId != "" else { return completionHandler(nil, nil) }
        let endpoint = ProductPhaseEndpoints.bulkUpdateProductPhases(productId: productId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductResponses.ListProductsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
