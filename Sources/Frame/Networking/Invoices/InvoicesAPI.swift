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

/// Manages invoice resources in the Frame SDK, providing static methods to create, retrieve, update, delete, and issue invoices.
public class InvoicesAPI: InvoicesProtocol, @unchecked Sendable {

    //MARK: Methods using async/await

    /// Creates a new invoice using the provided request body.
    ///
    /// - Parameter request: The request body containing the invoice fields to set.
    /// - Returns: A tuple of the created ``FrameObjects/Invoice`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
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

    /// Updates an existing invoice identified by its ID.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice to update.
    ///   - request: The request body containing the fields to update.
    /// - Returns: A tuple of the updated ``FrameObjects/Invoice`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
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

    /// Retrieves a paginated list of invoices, optionally filtered by customer or status.
    ///
    /// - Parameters:
    ///   - perPage: The number of invoices to return per page.
    ///   - page: The page number to retrieve.
    ///   - customer: An optional customer ID to filter invoices by.
    ///   - status: An optional ``FrameObjects/InvoiceStatus`` to filter invoices by.
    /// - Returns: A tuple of an ``InvoiceResponses/ListInvoicesResponse`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getInvoices(perPage: Int? = nil, page: Int? = nil, customer: String? = nil, status: FrameObjects.InvoiceStatus? = nil)  async throws -> (InvoiceResponses.ListInvoicesResponse?, NetworkingError?) {
        let endpoint = InvoiceEndpoints.getInvoices(perPage: perPage, page: page, customer: customer, status: status)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceResponses.ListInvoicesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a single invoice by its ID.
    ///
    /// - Parameter invoiceId: The unique identifier of the invoice to fetch.
    /// - Returns: A tuple of the matching ``FrameObjects/Invoice`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getInvoice(invoiceId: String) async throws -> (FrameObjects.Invoice?, NetworkingError?) {
        let endpoint = InvoiceEndpoints.getInvoice(invoiceId: invoiceId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Invoice.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Deletes an invoice identified by its ID.
    ///
    /// - Parameter invoiceId: The unique identifier of the invoice to delete.
    /// - Returns: A tuple of an ``InvoiceResponses/DeleteInvoiceResponse`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func deleteInvoice(invoiceId: String) async throws -> (InvoiceResponses.DeleteInvoiceResponse?, NetworkingError?) {
        let endpoint = InvoiceEndpoints.deleteInvoice(invoiceId: invoiceId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(InvoiceResponses.DeleteInvoiceResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Issues (finalises and sends) an invoice identified by its ID.
    ///
    /// - Parameter invoiceId: The unique identifier of the invoice to issue.
    /// - Returns: A tuple of the issued ``FrameObjects/Invoice`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
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

    /// Completion-handler variant of ``createInvoice(request:)``.
    ///
    /// - Parameters:
    ///   - request: The request body containing the invoice fields to set.
    ///   - completionHandler: Called with the created ``FrameObjects/Invoice`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
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

    /// Completion-handler variant of ``updateInvoice(invoiceId:request:)``.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice to update.
    ///   - request: The request body containing the fields to update.
    ///   - completionHandler: Called with the updated ``FrameObjects/Invoice`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
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

    /// Completion-handler variant of ``getInvoices(perPage:page:customer:status:)``.
    ///
    /// - Parameters:
    ///   - perPage: The number of invoices to return per page.
    ///   - page: The page number to retrieve.
    ///   - customer: An optional customer ID to filter invoices by.
    ///   - status: An optional ``FrameObjects/InvoiceStatus`` to filter invoices by.
    ///   - completionHandler: Called with an ``InvoiceResponses/ListInvoicesResponse`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
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

    /// Completion-handler variant of ``getInvoice(invoiceId:)``.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice to fetch.
    ///   - completionHandler: Called with the matching ``FrameObjects/Invoice`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
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

    /// Completion-handler variant of ``deleteInvoice(invoiceId:)``.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice to delete.
    ///   - completionHandler: Called with an ``InvoiceResponses/DeleteInvoiceResponse`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
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

    /// Completion-handler variant of ``issueInvoice(invoiceId:)``.
    ///
    /// - Parameters:
    ///   - invoiceId: The unique identifier of the invoice to issue.
    ///   - completionHandler: Called with the issued ``FrameObjects/Invoice`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
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
