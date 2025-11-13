//
//  InvoiceLineItemsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

protocol InvoiceLineItemProtocol {
    // async/await
    static func getLineItems(invoiceId: String) async throws -> (InvoiceLineItemResponses.ListLineItemsResponse?, NetworkingError?)
    static func createLineItem(invoiceId: String, request: InvoiceLineItemRequests.CreateLineItemRequest) async throws -> (FrameObjects.InvoiceLineItem?, NetworkingError?)
    static func updateLineItem(invoiceId: String, itemId: String, request: InvoiceLineItemRequests.UpdateLineItemRequest) async throws -> (FrameObjects.InvoiceLineItem?, NetworkingError?)
    static func getLineItem(invoiceId: String, itemId: String) async throws -> (FrameObjects.InvoiceLineItem?, NetworkingError?)
    static func deleteLineItem(invoiceId: String, itemId: String) async throws -> (InvoiceLineItemResponses.DeleteLineItemResponse?, NetworkingError?)
    
    // completionHandlers
    static func getLineItems(invoiceId: String, completionHandler: @escaping @Sendable (InvoiceLineItemResponses.ListLineItemsResponse?, NetworkingError?) -> Void)
    static func createLineItem(invoiceId: String, request: InvoiceLineItemRequests.CreateLineItemRequest, completionHandler: @escaping @Sendable (FrameObjects.InvoiceLineItem?, NetworkingError?) -> Void)
    static func updateLineItem(invoiceId: String, itemId: String, request: InvoiceLineItemRequests.UpdateLineItemRequest, completionHandler: @escaping @Sendable (FrameObjects.InvoiceLineItem?, NetworkingError?) -> Void)
    static func getLineItem(invoiceId: String, itemId: String, completionHandler: @escaping @Sendable (FrameObjects.InvoiceLineItem?, NetworkingError?) -> Void)
    static func deleteLineItem(invoiceId: String, itemId: String, completionHandler: @escaping @Sendable (InvoiceLineItemResponses.DeleteLineItemResponse?, NetworkingError?) -> Void)
}

public class InvoiceLineItemsAPI: InvoiceLineItemProtocol {
    //async/await
    public static func getLineItems(invoiceId: String) async throws -> (InvoiceLineItemResponses.ListLineItemsResponse?, NetworkingError?) {
        let endpoint = InvoiceLineItemEndpoints.getLineItems(invoiceId: invoiceId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceLineItemResponses.ListLineItemsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func createLineItem(invoiceId: String, request: InvoiceLineItemRequests.CreateLineItemRequest) async throws -> (FrameObjects.InvoiceLineItem?, NetworkingError?) {
        let endpoint = InvoiceLineItemEndpoints.createLineItem(invoiceId: invoiceId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.InvoiceLineItem.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func updateLineItem(invoiceId: String, itemId: String, request: InvoiceLineItemRequests.UpdateLineItemRequest) async throws -> (FrameObjects.InvoiceLineItem?, NetworkingError?) {
        let endpoint = InvoiceLineItemEndpoints.updateLineItem(invoiceId: invoiceId, itemId: itemId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)
        
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.InvoiceLineItem.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getLineItem(invoiceId: String, itemId: String) async throws -> (FrameObjects.InvoiceLineItem?, NetworkingError?) {
        let endpoint = InvoiceLineItemEndpoints.getLineItem(invoiceId: invoiceId, itemId: itemId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.InvoiceLineItem.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func deleteLineItem(invoiceId: String, itemId: String) async throws -> (InvoiceLineItemResponses.DeleteLineItemResponse?, NetworkingError?) {
        let endpoint = InvoiceLineItemEndpoints.deleteLineItem(invoiceId: invoiceId, itemId: itemId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceLineItemResponses.DeleteLineItemResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    //completionHandlers
    public static func getLineItems(invoiceId: String, completionHandler: @escaping @Sendable (InvoiceLineItemResponses.ListLineItemsResponse?, NetworkingError?) -> Void) {
        let endpoint = InvoiceLineItemEndpoints.getLineItems(invoiceId: invoiceId)
        
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceLineItemResponses.ListLineItemsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func createLineItem(invoiceId: String, request: InvoiceLineItemRequests.CreateLineItemRequest, completionHandler: @escaping @Sendable (FrameObjects.InvoiceLineItem?, NetworkingError?) -> Void) {
        let endpoint = InvoiceLineItemEndpoints.createLineItem(invoiceId: invoiceId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.InvoiceLineItem.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func updateLineItem(invoiceId: String, itemId: String, request: InvoiceLineItemRequests.UpdateLineItemRequest, completionHandler: @escaping @Sendable (FrameObjects.InvoiceLineItem?, NetworkingError?) -> Void) {
        let endpoint = InvoiceLineItemEndpoints.updateLineItem(invoiceId: invoiceId, itemId: itemId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.InvoiceLineItem.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getLineItem(invoiceId: String, itemId: String, completionHandler: @escaping @Sendable (FrameObjects.InvoiceLineItem?, NetworkingError?) -> Void) {
        let endpoint = InvoiceLineItemEndpoints.getLineItem(invoiceId: invoiceId, itemId: itemId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.InvoiceLineItem.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func deleteLineItem(invoiceId: String, itemId: String, completionHandler: @escaping @Sendable (InvoiceLineItemResponses.DeleteLineItemResponse?, NetworkingError?) -> Void) {
        let endpoint = InvoiceLineItemEndpoints.deleteLineItem(invoiceId: invoiceId, itemId: itemId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceLineItemResponses.DeleteLineItemResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
