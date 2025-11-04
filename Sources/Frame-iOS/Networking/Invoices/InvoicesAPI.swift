//
//  InvoiceAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

// Protocol for Mock Testing
protocol InvoicesProtocol {
    //async/await
    static func createInvoice(request: InvoiceRequests.CreateInvoiceRequest) async throws -> (FrameObjects.Invoice?, NetworkingError?)
    static func updateInvoice(invoiceId: String, request: InvoiceRequests.UpdateInvoiceRequest) async throws -> (FrameObjects.Invoice?, NetworkingError?)
    static func getInvoices(perPage: Int?, page: Int?, customer: String?, status: FrameObjects.InvoiceStatus?)  async throws -> (InvoiceResponses.ListInvoicesResponse?, NetworkingError?)
    static func getInvoice(invoiceId: String) async throws -> (FrameObjects.Invoice?, NetworkingError?)
    static func deleteInvoice(invoiceId: String) async throws -> (InvoiceResponses.DeleteInvoiceResponse?, NetworkingError?)
    static func issueInvoice(invoiceId: String) async throws -> (FrameObjects.Invoice?, NetworkingError?)
    
    // completionHandlers
    static func createInvoice(request: InvoiceRequests.CreateInvoiceRequest, completionHandler: @escaping @Sendable (FrameObjects.Invoice?, NetworkingError?) -> Void)
    static func updateInvoice(invoiceId: String, request: InvoiceRequests.UpdateInvoiceRequest, completionHandler: @escaping @Sendable (FrameObjects.Invoice?, NetworkingError?) -> Void)
    static func getInvoices(perPage: Int?, page: Int?, customer: String?, status: FrameObjects.InvoiceStatus?, completionHandler: @escaping @Sendable (InvoiceResponses.ListInvoicesResponse?, NetworkingError?) -> Void)
    static func getInvoice(invoiceId: String, completionHandler: @escaping @Sendable (FrameObjects.Invoice?, NetworkingError?) -> Void)
    static func deleteInvoice(invoiceId: String, completionHandler: @escaping @Sendable (InvoiceResponses.DeleteInvoiceResponse?, NetworkingError?) -> Void)
    static func issueInvoice(invoiceId: String, completionHandler: @escaping @Sendable (FrameObjects.Invoice?, NetworkingError?) -> Void)
}

// Customers API
public class InvoicesAPI: InvoicesProtocol, @unchecked Sendable {
    
    //MARK: Methods using async/await
    public static func createInvoice(request: InvoiceRequests.CreateInvoiceRequest) async throws -> (FrameObjects.Invoice?, NetworkingError?) {
        let endpoint = InvoiceEndpoints.createInvoice
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Invoice.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func updateInvoice(invoiceId: String, request: InvoiceRequests.UpdateInvoiceRequest) async throws -> (FrameObjects.Invoice?, NetworkingError?) {
        let endpoint = InvoiceEndpoints.updateInvoice(invoiceId: invoiceId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Invoice.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getInvoices(perPage: Int? = nil, page: Int? = nil, customer: String? = nil, status: FrameObjects.InvoiceStatus? = nil)  async throws -> (InvoiceResponses.ListInvoicesResponse?, NetworkingError?) {
        let endpoint = InvoiceEndpoints.getInvoices(perPage: perPage, page: page, customer: customer, status: status)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceResponses.ListInvoicesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func getInvoice(invoiceId: String) async throws -> (FrameObjects.Invoice?, NetworkingError?) {
        let endpoint = InvoiceEndpoints.getInvoice(invoiceId: invoiceId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Invoice.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func deleteInvoice(invoiceId: String) async throws -> (InvoiceResponses.DeleteInvoiceResponse?, NetworkingError?) {
        let endpoint = InvoiceEndpoints.deleteInvoice(invoiceId: invoiceId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceResponses.DeleteInvoiceResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    public static func issueInvoice(invoiceId: String) async throws -> (FrameObjects.Invoice?, NetworkingError?) {
        let endpoint = InvoiceEndpoints.issueInvoice(invoiceId: invoiceId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Invoice.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }
    
    //MARK: Methods using completion handler
    public static func createInvoice(request: InvoiceRequests.CreateInvoiceRequest, completionHandler: @escaping @Sendable (FrameObjects.Invoice?, NetworkingError?) -> Void) {
        let endpoint = InvoiceEndpoints.createInvoice
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Invoice.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func updateInvoice(invoiceId: String, request: InvoiceRequests.UpdateInvoiceRequest, completionHandler: @escaping @Sendable (FrameObjects.Invoice?, NetworkingError?) -> Void) {
        let endpoint = InvoiceEndpoints.updateInvoice(invoiceId: invoiceId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Invoice.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getInvoices(perPage: Int?, page: Int?, customer: String?, status: FrameObjects.InvoiceStatus?, completionHandler: @escaping @Sendable (InvoiceResponses.ListInvoicesResponse?, NetworkingError?) -> Void) {
        let endpoint = InvoiceEndpoints.getInvoices(perPage: perPage, page: page, customer: customer, status: status)
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceResponses.ListInvoicesResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func getInvoice(invoiceId: String, completionHandler: @escaping @Sendable (FrameObjects.Invoice?, NetworkingError?) -> Void) {
        let endpoint = InvoiceEndpoints.getInvoice(invoiceId: invoiceId)
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Invoice.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func deleteInvoice(invoiceId: String, completionHandler: @escaping @Sendable (InvoiceResponses.DeleteInvoiceResponse?, NetworkingError?) -> Void) {
        let endpoint = InvoiceEndpoints.deleteInvoice(invoiceId: invoiceId)
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceResponses.DeleteInvoiceResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    public static func issueInvoice(invoiceId: String, completionHandler: @escaping @Sendable (FrameObjects.Invoice?, NetworkingError?) -> Void) {
        let endpoint = InvoiceEndpoints.issueInvoice(invoiceId: invoiceId)
        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Invoice.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
