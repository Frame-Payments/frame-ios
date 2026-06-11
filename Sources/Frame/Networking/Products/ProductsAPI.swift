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

/// Manages product resources in the Frame Payments API, providing methods to create, retrieve, update, search, and delete products.
public class ProductsAPI: ProductsProtocol, @unchecked Sendable {
    // async/await

    /// Creates a new product.
    ///
    /// - Parameter request: The request body containing the product details to create.
    /// - Returns: A tuple containing the newly created ``FrameObjects/Product`` on success, or a ``NetworkingError`` on failure.
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

    /// Updates an existing product by ID.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the product to update.
    ///   - request: The request body containing the fields to update.
    /// - Returns: A tuple containing the updated ``FrameObjects/Product`` on success, or a ``NetworkingError`` on failure.
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

    /// Retrieves a paginated list of all products.
    ///
    /// - Parameters:
    ///   - perPage: The maximum number of products to return per page.
    ///   - page: The page number to retrieve.
    /// - Returns: A tuple containing a ``ProductResponses/ListProductsResponse`` on success, or a ``NetworkingError`` on failure.
    static func getProducts(perPage: Int?, page: Int?) async throws -> (ProductResponses.ListProductsResponse?, NetworkingError?) {
        let endpoint = ProductEndpoints.getProducts(perPage: perPage, page: page)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductResponses.ListProductsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a single product by ID.
    ///
    /// - Parameter productId: The unique identifier of the product to fetch.
    /// - Returns: A tuple containing the matching ``FrameObjects/Product`` on success, or a ``NetworkingError`` on failure.
    static func getProduct(productId: String) async throws -> (FrameObjects.Product?, NetworkingError?) {
        let endpoint = ProductEndpoints.getProduct(productId: productId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Product.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Searches for products matching the given criteria.
    ///
    /// - Parameters:
    ///   - name: An optional name to filter products by.
    ///   - active: An optional flag to filter by active or inactive products.
    ///   - shippable: An optional flag to filter by whether products are shippable.
    /// - Returns: A tuple containing a ``ProductResponses/SearchProductResponse`` on success, or a ``NetworkingError`` on failure.
    static func searchProduct(name: String?, active: Bool?, shippable: Bool?) async throws -> (ProductResponses.SearchProductResponse?, NetworkingError?) {
        let endpoint = ProductEndpoints.searchProduct(name: name, active: active, shippable: shippable)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ProductResponses.SearchProductResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Deletes a product by ID.
    ///
    /// - Parameter productId: The unique identifier of the product to delete.
    /// - Returns: A tuple containing a ``ProductResponses/DeleteProductResponse`` on success, or a ``NetworkingError`` on failure.
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

    /// Completion-handler variant of `createProductAsync(_:)`.
    ///
    /// - Parameters:
    ///   - request: The request body containing the product details to create.
    ///   - completionHandler: Called with the newly created ``FrameObjects/Product`` or a ``NetworkingError``.
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

    /// Completion-handler variant of `updateProductAsync(_:)`.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the product to update.
    ///   - request: The request body containing the fields to update.
    ///   - completionHandler: Called with the updated ``FrameObjects/Product`` or a ``NetworkingError``.
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

    /// Completion-handler variant of `getProductsAsync(_:)`.
    ///
    /// - Parameters:
    ///   - perPage: The maximum number of products to return per page.
    ///   - page: The page number to retrieve.
    ///   - completionHandler: Called with a ``ProductResponses/ListProductsResponse`` or a ``NetworkingError``.
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

    /// Completion-handler variant of `getProductAsync(_:)`.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the product to fetch.
    ///   - completionHandler: Called with the matching ``FrameObjects/Product`` or a ``NetworkingError``.
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

    /// Completion-handler variant of `searchProductAsync(_:)`.
    ///
    /// - Parameters:
    ///   - name: An optional name to filter products by.
    ///   - active: An optional flag to filter by active or inactive products.
    ///   - shippable: An optional flag to filter by whether products are shippable.
    ///   - completionHandler: Called with a ``ProductResponses/SearchProductResponse`` or a ``NetworkingError``.
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

    /// Completion-handler variant of `deleteProductAsync(_:)`.
    ///
    /// - Parameters:
    ///   - productId: The unique identifier of the product to delete.
    ///   - completionHandler: Called with a ``ProductResponses/DeleteProductResponse`` or a ``NetworkingError``.
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
