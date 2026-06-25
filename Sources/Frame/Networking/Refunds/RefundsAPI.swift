//
//  RefundsAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

// https://docs.framepayments.com/api/refunds

// Protocol for Mock Testing
protocol RefundsProtocol {
    //async/await
    static func createRefund(request: RefundRequests.CreateRefundRequest) async throws -> (FrameObjects.Refund?, NetworkingError?)
    static func getRefunds(chargeId: String?, chargeIntentId: String?, perPage: Int?, page : Int?) async throws -> (RefundResponses.ListRefundsResponse?, NetworkingError?)
    static func getRefundWith(refundId: String) async throws -> (FrameObjects.Refund?, NetworkingError?)
    static func cancelRefund(refundId: String) async throws -> (FrameObjects.Refund?, NetworkingError?)

    // completionHandlers
    static func createRefund(request: RefundRequests.CreateRefundRequest, completionHandler: @escaping @Sendable (FrameObjects.Refund?, NetworkingError?) -> Void)
    static func getRefunds(chargeId: String?, chargeIntentId: String?, perPage: Int?, page : Int?, completionHandler: @escaping @Sendable (RefundResponses.ListRefundsResponse?, NetworkingError?) -> Void)
    static func getRefundWith(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?, NetworkingError?) -> Void)
    static func cancelRefund(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?, NetworkingError?) -> Void)
}

/// Manages the Refunds resource, providing static methods to create, list, retrieve, and cancel refunds via the Frame Payments API.
public class RefundsAPI: RefundsProtocol, @unchecked Sendable {
    //async/await

    /// Creates a new refund for a previously completed charge.
    ///
    /// - Parameter request: The request body containing the refund details.
    /// - Returns: A tuple of the created ``FrameObjects/Refund`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func createRefund(request: RefundRequests.CreateRefundRequest) async throws -> (FrameObjects.Refund?, NetworkingError?) {
        let endpoint = RefundEndpoints.createRefund
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a paginated list of refunds, optionally filtered by charge or charge intent.
    ///
    /// - Parameters:
    ///   - chargeId: An optional charge ID to filter refunds by.
    ///   - chargeIntentId: An optional charge intent ID to filter refunds by.
    ///   - perPage: The number of results to return per page.
    ///   - page: The page number to retrieve.
    /// - Returns: A tuple of a ``RefundResponses/ListRefundsResponse`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getRefunds(chargeId: String? = nil, chargeIntentId: String? = nil, perPage: Int? = nil, page: Int? = nil) async throws -> (RefundResponses.ListRefundsResponse?, NetworkingError?) {
        let endpoint = RefundEndpoints.getRefunds(chargeId: chargeId, chargeIntentId: chargeIntentId, perPage: perPage, page: page)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(RefundResponses.ListRefundsResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a single refund by its unique identifier.
    ///
    /// - Parameter refundId: The unique identifier of the refund to retrieve.
    /// - Returns: A tuple of the matching ``FrameObjects/Refund`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getRefundWith(refundId: String) async throws -> (FrameObjects.Refund?, NetworkingError?) {
        guard !refundId.isEmpty else { return (nil, nil) }
        let endpoint = RefundEndpoints.getRefundWith(refundId: refundId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Cancels a pending refund by its unique identifier.
    ///
    /// - Parameter refundId: The unique identifier of the refund to cancel.
    /// - Returns: A tuple of the updated ``FrameObjects/Refund`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func cancelRefund(refundId: String) async throws -> (FrameObjects.Refund?, NetworkingError?) {
        guard !refundId.isEmpty else { return (nil, nil) }
        let endpoint = RefundEndpoints.cancelRefund(refundId: refundId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    // completionHandlers

    /// Completion-handler variant of ``createRefund(request:)``.
    ///
    /// - Parameters:
    ///   - request: The request body containing the refund details.
    ///   - completionHandler: Called with the created ``FrameObjects/Refund`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func createRefund(request: RefundRequests.CreateRefundRequest, completionHandler: @escaping @Sendable (FrameObjects.Refund?, NetworkingError?) -> Void) {
        let endpoint = RefundEndpoints.createRefund
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getRefunds(chargeId:chargeIntentId:perPage:page:)``.
    ///
    /// - Parameters:
    ///   - chargeId: An optional charge ID to filter refunds by.
    ///   - chargeIntentId: An optional charge intent ID to filter refunds by.
    ///   - perPage: The number of results to return per page.
    ///   - page: The page number to retrieve.
    ///   - completionHandler: Called with a ``RefundResponses/ListRefundsResponse`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getRefunds(chargeId: String? = nil, chargeIntentId: String? = nil, perPage: Int? = nil, page: Int? = nil, completionHandler: @escaping @Sendable (RefundResponses.ListRefundsResponse?, NetworkingError?) -> Void) {
        let endpoint = RefundEndpoints.getRefunds(chargeId: chargeId, chargeIntentId: chargeIntentId, perPage: perPage, page: page)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(RefundResponses.ListRefundsResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getRefundWith(refundId:)``.
    ///
    /// - Parameters:
    ///   - refundId: The unique identifier of the refund to retrieve.
    ///   - completionHandler: Called with the matching ``FrameObjects/Refund`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getRefundWith(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?, NetworkingError?) -> Void) {
        let endpoint = RefundEndpoints.getRefundWith(refundId: refundId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``cancelRefund(refundId:)``.
    ///
    /// - Parameters:
    ///   - refundId: The unique identifier of the refund to cancel.
    ///   - completionHandler: Called with the updated ``FrameObjects/Refund`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func cancelRefund(refundId: String, completionHandler: @escaping @Sendable (FrameObjects.Refund?, NetworkingError?) -> Void) {
        let endpoint = RefundEndpoints.cancelRefund(refundId: refundId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Refund.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
