//
//  InvoiceLineItemsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

/// Internal protocol defining the async/await and completion-handler surface for invoice line item operations.
protocol InvoiceLineItemProtocol {
    // async/await

    /// Retrieves all line items belonging to the specified invoice.
    static func getLineItems(invoiceId: String) async throws -> (InvoiceLineItemResponses.ListLineItemsResponse?, NetworkingError?)

    /// Creates a new line item on the specified invoice.
    static func createLineItem(invoiceId: String, request: InvoiceLineItemRequests.CreateLineItemRequest) async throws -> (FrameObjects.InvoiceLineItem?, NetworkingError?)

    /// Updates an existing line item on the specified invoice.
    static func updateLineItem(invoiceId: String, itemId: String, request: InvoiceLineItemRequests.UpdateLineItemRequest) async throws -> (FrameObjects.InvoiceLineItem?, NetworkingError?)

    /// Retrieves a single line item by its identifier from the specified invoice.
    static func getLineItem(invoiceId: String, itemId: String) async throws -> (FrameObjects.InvoiceLineItem?, NetworkingError?)

    /// Deletes a line item from the specified invoice.
    static func deleteLineItem(invoiceId: String, itemId: String) async throws -> (InvoiceLineItemResponses.DeleteLineItemResponse?, NetworkingError?)

    // completionHandlers

    /// Retrieves all line items belonging to the specified invoice.
    static func getLineItems(invoiceId: String, completionHandler: @escaping @Sendable (InvoiceLineItemResponses.ListLineItemsResponse?, NetworkingError?) -> Void)

    /// Creates a new line item on the specified invoice.
    static func createLineItem(invoiceId: String, request: InvoiceLineItemRequests.CreateLineItemRequest, completionHandler: @escaping @Sendable (FrameObjects.InvoiceLineItem?, NetworkingError?) -> Void)

    /// Updates an existing line item on the specified invoice.
    static func updateLineItem(invoiceId: String, itemId: String, request: InvoiceLineItemRequests.UpdateLineItemRequest, completionHandler: @escaping @Sendable (FrameObjects.InvoiceLineItem?, NetworkingError?) -> Void)

    /// Retrieves a single line item by its identifier from the specified invoice.
    static func getLineItem(invoiceId: String, itemId: String, completionHandler: @escaping @Sendable (FrameObjects.InvoiceLineItem?, NetworkingError?) -> Void)

    /// Deletes a line item from the specified invoice.
    static func deleteLineItem(invoiceId: String, itemId: String, completionHandler: @escaping @Sendable (InvoiceLineItemResponses.DeleteLineItemResponse?, NetworkingError?) -> Void)
}

/// Manages invoice line item resources, providing methods to list, create, retrieve, update, and delete
/// individual line items associated with a given invoice in the Frame SDK.
public class InvoiceLineItemsAPI: InvoiceLineItemProtocol {
    //async/await

    /// Retrieves all line items for the specified invoice.
    ///
    /// - Parameter invoiceId: The unique identifier of the invoice whose line items should be fetched.
    /// - Returns: A tuple containing the paginated list response and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getLineItems(invoiceId: String) async throws -> (InvoiceLineItemResponses.ListLineItemsResponse?, NetworkingError?) {
        let endpoint = InvoiceLineItemEndpoints.getLineItems(invoiceId: invoiceId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceLineItemResponses.ListLineItemsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Creates a new line item on the specified invoice.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice to which the line item will be added.
    ///   - request: The request body containing the details of the line item to create.
    /// - Returns: A tuple containing the created ``FrameObjects/InvoiceLineItem`` and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func createLineItem(invoiceId: String, request: InvoiceLineItemRequests.CreateLineItemRequest) async throws -> (FrameObjects.InvoiceLineItem?, NetworkingError?) {
        let endpoint = InvoiceLineItemEndpoints.createLineItem(invoiceId: invoiceId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.InvoiceLineItem.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Updates an existing line item on the specified invoice.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice that owns the line item.
    ///   - itemId: The unique identifier of the line item to update.
    ///   - request: The request body containing the fields to update on the line item.
    /// - Returns: A tuple containing the updated ``FrameObjects/InvoiceLineItem`` and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func updateLineItem(invoiceId: String, itemId: String, request: InvoiceLineItemRequests.UpdateLineItemRequest) async throws -> (FrameObjects.InvoiceLineItem?, NetworkingError?) {
        let endpoint = InvoiceLineItemEndpoints.updateLineItem(invoiceId: invoiceId, itemId: itemId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.InvoiceLineItem.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a single line item from the specified invoice.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice that owns the line item.
    ///   - itemId: The unique identifier of the line item to retrieve.
    /// - Returns: A tuple containing the ``FrameObjects/InvoiceLineItem`` and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getLineItem(invoiceId: String, itemId: String) async throws -> (FrameObjects.InvoiceLineItem?, NetworkingError?) {
        let endpoint = InvoiceLineItemEndpoints.getLineItem(invoiceId: invoiceId, itemId: itemId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.InvoiceLineItem.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Deletes a line item from the specified invoice.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice that owns the line item.
    ///   - itemId: The unique identifier of the line item to delete.
    /// - Returns: A tuple containing the deletion confirmation response and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func deleteLineItem(invoiceId: String, itemId: String) async throws -> (InvoiceLineItemResponses.DeleteLineItemResponse?, NetworkingError?) {
        let endpoint = InvoiceLineItemEndpoints.deleteLineItem(invoiceId: invoiceId, itemId: itemId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceLineItemResponses.DeleteLineItemResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    //completionHandlers

    /// Completion-handler variant of ``getLineItems(invoiceId:)``.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice whose line items should be fetched.
    ///   - completionHandler: Called with the paginated list response and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getLineItems(invoiceId: String, completionHandler: @escaping @Sendable (InvoiceLineItemResponses.ListLineItemsResponse?, NetworkingError?) -> Void) {
        let endpoint = InvoiceLineItemEndpoints.getLineItems(invoiceId: invoiceId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceLineItemResponses.ListLineItemsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``createLineItem(invoiceId:request:)``.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice to which the line item will be added.
    ///   - request: The request body containing the details of the line item to create.
    ///   - completionHandler: Called with the created ``FrameObjects/InvoiceLineItem`` and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func createLineItem(invoiceId: String, request: InvoiceLineItemRequests.CreateLineItemRequest, completionHandler: @escaping @Sendable (FrameObjects.InvoiceLineItem?, NetworkingError?) -> Void) {
        let endpoint = InvoiceLineItemEndpoints.createLineItem(invoiceId: invoiceId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.InvoiceLineItem.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``updateLineItem(invoiceId:itemId:request:)``.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice that owns the line item.
    ///   - itemId: The unique identifier of the line item to update.
    ///   - request: The request body containing the fields to update on the line item.
    ///   - completionHandler: Called with the updated ``FrameObjects/InvoiceLineItem`` and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func updateLineItem(invoiceId: String, itemId: String, request: InvoiceLineItemRequests.UpdateLineItemRequest, completionHandler: @escaping @Sendable (FrameObjects.InvoiceLineItem?, NetworkingError?) -> Void) {
        let endpoint = InvoiceLineItemEndpoints.updateLineItem(invoiceId: invoiceId, itemId: itemId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.InvoiceLineItem.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getLineItem(invoiceId:itemId:)``.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice that owns the line item.
    ///   - itemId: The unique identifier of the line item to retrieve.
    ///   - completionHandler: Called with the ``FrameObjects/InvoiceLineItem`` and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getLineItem(invoiceId: String, itemId: String, completionHandler: @escaping @Sendable (FrameObjects.InvoiceLineItem?, NetworkingError?) -> Void) {
        let endpoint = InvoiceLineItemEndpoints.getLineItem(invoiceId: invoiceId, itemId: itemId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.InvoiceLineItem.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``deleteLineItem(invoiceId:itemId:)``.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice that owns the line item.
    ///   - itemId: The unique identifier of the line item to delete.
    ///   - completionHandler: Called with the deletion confirmation response and any networking error that occurred.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func deleteLineItem(invoiceId: String, itemId: String, completionHandler: @escaping @Sendable (InvoiceLineItemResponses.DeleteLineItemResponse?, NetworkingError?) -> Void) {
        let endpoint = InvoiceLineItemEndpoints.deleteLineItem(invoiceId: invoiceId, itemId: itemId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .secret) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceLineItemResponses.DeleteLineItemResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
