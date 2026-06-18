//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/3/25.
//

import Foundation

// https://docs.framepayments.com/api/product_phases

/// Internal protocol describing the full set of product-phase operations supported by the SDK.
protocol ProductPhasesProtocol {
    //async/await
    /// Lists all subscription phases belonging to a product.
    static func listAllProductPhases(productId: String) async throws -> (ProductPhasesResponses.ListProductPhasesResponse?, NetworkingError?)
    /// Retrieves a single subscription phase by product and phase identifiers.
    static func getProductPhase(productId: String, phaseId: String) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)
    /// Creates a new subscription phase for a product.
    static func createProductPhase(productId: String, request: ProductPhaseRequests.CreateProductPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)
    /// Updates an existing subscription phase for a product.
    static func updateProductPhase(productId: String, phaseId: String, request: ProductPhaseRequests.UpdateProductPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?)
    /// Deletes a subscription phase from a product.
    static func deleteProductPhase(productId: String, phaseId: String) async throws -> (NetworkingError?)
    /// Replaces all subscription phases for a product in a single atomic operation.
    static func bulkUpdateProductPhases(productId: String, request: ProductPhaseRequests.BulkUpdateProductPhase) async throws -> (ProductPhasesResponses.ListProductPhasesResponse?, NetworkingError?)

    // completionHandlers
    /// Completion-handler variant of `listAllProductPhases(productId:)`.
    static func listAllProductPhases(productId: String, completionHandler: @escaping @Sendable (ProductPhasesResponses.ListProductPhasesResponse?, NetworkingError?) -> Void)
    /// Completion-handler variant of `getProductPhase(productId:phaseId:)`.
    static func getProductPhase(productId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)
    /// Completion-handler variant of `createProductPhase(productId:request:)`.
    static func createProductPhase(productId: String, request: ProductPhaseRequests.CreateProductPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)
    /// Completion-handler variant of `updateProductPhase(productId:phaseId:request:)`.
    static func updateProductPhase(productId: String, phaseId: String, request: ProductPhaseRequests.UpdateProductPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void)
    /// Completion-handler variant of `deleteProductPhase(productId:phaseId:)`.
    static func deleteProductPhase(productId: String, phaseId: String, completionHandler: @escaping @Sendable (NetworkingError?) -> Void)
    /// Completion-handler variant of `bulkUpdateProductPhases(productId:request:)`.
    static func bulkUpdateProductPhases(productId: String, request: ProductPhaseRequests.BulkUpdateProductPhase, completionHandler: @escaping @Sendable (ProductResponses.ListProductsResponse?, NetworkingError?) -> Void)
}

// Product Phases API
/// Manages the Product Phases resource, providing methods to list, retrieve, create, update, delete,
/// and bulk-update the subscription phases associated with a product.
public class ProductPhasesAPI: ProductPhasesProtocol, @unchecked Sendable {
    // async/await

    /// Lists all subscription phases for the specified product.
    ///
    /// - Parameter productId: The unique identifier of the product whose phases should be listed.
    /// - Returns: A tuple containing the list response and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func listAllProductPhases(productId: String) async throws -> (ProductPhasesResponses.ListProductPhasesResponse?, NetworkingError?) {
        guard productId != "" else { return (nil, nil) }
        let endpoint = ProductPhaseEndpoints.getAllProductPhases(productId: productId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductPhasesResponses.ListProductPhasesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a single subscription phase by its identifier.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the owning product.
    ///   - phaseId: The unique identifier of the subscription phase.
    /// - Returns: A tuple containing the decoded phase and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getProductPhase(productId: String, phaseId: String) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard productId != "" && phaseId != "" else { return (nil, nil) }
        let endpoint = ProductPhaseEndpoints.getProductPhaseWith(productId: productId, phaseId: phaseId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Creates a new subscription phase for the specified product.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the product to which the phase will be added.
    ///   - request: The request body describing the phase to create.
    /// - Returns: A tuple containing the newly created phase and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func createProductPhase(productId: String, request: ProductPhaseRequests.CreateProductPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard productId != "" else { return (nil, nil) }
        let endpoint = ProductPhaseEndpoints.createProductPhase(productId: productId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Updates an existing subscription phase for the specified product.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the owning product.
    ///   - phaseId: The unique identifier of the phase to update.
    ///   - request: The request body containing the fields to update.
    /// - Returns: A tuple containing the updated phase and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func updateProductPhase(productId: String, phaseId: String, request: ProductPhaseRequests.UpdateProductPhase) async throws -> (FrameObjects.SubscriptionPhase?, NetworkingError?) {
        guard productId != "" && phaseId != "" else { return (nil, nil) }
        let endpoint = ProductPhaseEndpoints.updateProductPhaseWith(productId: productId, phaseId: phaseId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Deletes the specified subscription phase from a product.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the owning product.
    ///   - phaseId: The unique identifier of the phase to delete.
    /// - Returns: Any networking error that occurred, or `nil` on success.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func deleteProductPhase(productId: String, phaseId: String) async throws -> (NetworkingError?) {
        guard productId != "" && phaseId != "" else { return (nil) }
        let endpoint = ProductPhaseEndpoints.deleteProductPhase(productId: productId, phaseId: phaseId)

        let (_, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        return error
    }

    /// Replaces all subscription phases for a product in a single atomic operation.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the product whose phases should be replaced.
    ///   - request: The request body containing the complete, ordered set of phases.
    /// - Returns: A tuple containing the updated list of phases and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func bulkUpdateProductPhases(productId: String, request: ProductPhaseRequests.BulkUpdateProductPhase) async throws -> (ProductPhasesResponses.ListProductPhasesResponse?, NetworkingError?) {
        guard productId != "" else { return (nil, nil) }
        let endpoint = ProductPhaseEndpoints.bulkUpdateProductPhases(productId: productId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductPhasesResponses.ListProductPhasesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    // completionHandlers

    /// Completion-handler variant of `listAllProductPhases(productId:)`.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the product whose phases should be listed.
    ///   - completionHandler: Called with the list response and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func listAllProductPhases(productId: String, completionHandler: @escaping @Sendable (ProductPhasesResponses.ListProductPhasesResponse?, NetworkingError?) -> Void) {
        guard productId != "" else { return completionHandler(nil, nil) }
        let endpoint = ProductPhaseEndpoints.getAllProductPhases(productId: productId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductPhasesResponses.ListProductPhasesResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of `getProductPhase(productId:phaseId:)`.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the owning product.
    ///   - phaseId: The unique identifier of the subscription phase.
    ///   - completionHandler: Called with the decoded phase and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getProductPhase(productId: String, phaseId: String, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard productId != "", phaseId != "" else { return completionHandler(nil, nil) }
        let endpoint = ProductPhaseEndpoints.getProductPhaseWith(productId: productId, phaseId: phaseId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of `createProductPhase(productId:request:)`.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the product to which the phase will be added.
    ///   - request: The request body describing the phase to create.
    ///   - completionHandler: Called with the newly created phase and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func createProductPhase(productId: String, request: ProductPhaseRequests.CreateProductPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard productId != "" else { return completionHandler(nil, nil) }
        let endpoint = ProductPhaseEndpoints.createProductPhase(productId: productId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of `updateProductPhase(productId:phaseId:request:)`.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the owning product.
    ///   - phaseId: The unique identifier of the phase to update.
    ///   - request: The request body containing the fields to update.
    ///   - completionHandler: Called with the updated phase and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func updateProductPhase(productId: String, phaseId: String, request: ProductPhaseRequests.UpdateProductPhase, completionHandler: @escaping @Sendable (FrameObjects.SubscriptionPhase?, NetworkingError?) -> Void) {
        guard productId != "", phaseId != "" else { return completionHandler(nil, nil) }
        let endpoint = ProductPhaseEndpoints.updateProductPhaseWith(productId: productId, phaseId: phaseId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.SubscriptionPhase.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of `deleteProductPhase(productId:phaseId:)`.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the owning product.
    ///   - phaseId: The unique identifier of the phase to delete.
    ///   - completionHandler: Called with any networking error that occurred, or `nil` on success.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func deleteProductPhase(productId: String, phaseId: String, completionHandler: @escaping @Sendable (NetworkingError?) -> Void) {
        guard productId != "", phaseId != "" else { return completionHandler(nil) }
        let endpoint = ProductPhaseEndpoints.deleteProductPhase(productId: productId, phaseId: phaseId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            completionHandler(error)
        }
    }

    /// Completion-handler variant of `bulkUpdateProductPhases(productId:request:)`.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the product whose phases should be replaced.
    ///   - request: The request body containing the complete, ordered set of phases.
    ///   - completionHandler: Called with the updated product list response and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func bulkUpdateProductPhases(productId: String, request: ProductPhaseRequests.BulkUpdateProductPhase, completionHandler: @escaping @Sendable (ProductResponses.ListProductsResponse?, NetworkingError?) -> Void) {
        guard productId != "" else { return completionHandler(nil, nil) }
        let endpoint = ProductPhaseEndpoints.bulkUpdateProductPhases(productId: productId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductResponses.ListProductsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
