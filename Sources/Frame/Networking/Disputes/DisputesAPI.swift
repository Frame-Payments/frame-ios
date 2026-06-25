//
//  DisputesAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/5/25.
//

import Foundation

// https://docs.framepayments.com/api/disputes

// Protocol for Mock Testing
protocol DisputesProtocol {
    //async/await
    static func updateDispute(disputeId: String, request: DisputeRequests.UpdateDisputeRequest) async throws -> (FrameObjects.Dispute?, NetworkingError?)
    static func getDispute(disputeId: String) async throws -> (FrameObjects.Dispute?, NetworkingError?)
    static func getDisputes(chargeId: String?, chargeIntentId: String?, perPage: Int, page: Int) async throws -> (DisputeResponses.ListDisputesResponse?, NetworkingError?)
    static func closeDispute(disputeId: String) async throws -> (FrameObjects.Dispute?, NetworkingError?)
    static func uploadDocuments(disputeId: String, files: [FileUpload]) async throws -> NetworkingError?

    // completionHandlers
    static func updateDispute(disputeId: String, request: DisputeRequests.UpdateDisputeRequest, completionHandler: @escaping @Sendable (FrameObjects.Dispute?, NetworkingError?) -> Void)
    static func getDispute(disputeId: String, completionHandler: @escaping @Sendable (FrameObjects.Dispute?, NetworkingError?) -> Void)
    static func getDisputes(chargeId: String?, chargeIntentId: String?, perPage: Int, page: Int, completionHandler: @escaping @Sendable (DisputeResponses.ListDisputesResponse?, NetworkingError?) -> Void)
    static func closeDispute(disputeId: String, completionHandler: @escaping @Sendable (FrameObjects.Dispute?, NetworkingError?) -> Void)
    static func uploadDocuments(disputeId: String, files: [FileUpload], completionHandler: @escaping @Sendable (NetworkingError?) -> Void)
}

/// Manages dispute resources in the Frame Payments API, providing methods to retrieve, update, close, and upload documents for disputes.
public class DisputesAPI: DisputesProtocol, @unchecked Sendable {
    //async/await

    /// Updates an existing dispute with the provided request body.
    ///
    /// - Parameters:
    ///   - disputeId: The unique identifier of the dispute to update.
    ///   - request: The update request body containing fields to modify.
    /// - Returns: A tuple of the updated ``FrameObjects/Dispute`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func updateDispute(disputeId: String, request: DisputeRequests.UpdateDisputeRequest) async throws -> (FrameObjects.Dispute?, NetworkingError?) {
        let endpoint = DisputeEndpoints.updateDispute(disputeId: disputeId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Dispute.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a single dispute by its identifier.
    ///
    /// - Parameter disputeId: The unique identifier of the dispute to retrieve.
    /// - Returns: A tuple of the fetched ``FrameObjects/Dispute`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getDispute(disputeId: String) async throws -> (FrameObjects.Dispute?, NetworkingError?) {
        let endpoint = DisputeEndpoints.getDispute(disputeId: disputeId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Dispute.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Retrieves a paginated list of disputes, optionally filtered by charge or charge intent.
    ///
    /// - Parameters:
    ///   - chargeId: An optional charge identifier to filter results.
    ///   - chargeIntentId: An optional charge intent identifier to filter results.
    ///   - perPage: The number of results to return per page. Defaults to `10`.
    ///   - page: The page number to retrieve. Defaults to `1`.
    /// - Returns: A tuple of the ``DisputeResponses/ListDisputesResponse`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getDisputes(chargeId: String? = nil, chargeIntentId: String? = nil, perPage: Int = 10, page: Int = 1) async throws -> (DisputeResponses.ListDisputesResponse?, NetworkingError?) {
        let endpoint = DisputeEndpoints.getDisputes(chargeId: chargeId, chargeIntentId: chargeIntentId, perPage: perPage, page: page)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(DisputeResponses.ListDisputesResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Closes an open dispute, preventing further evidence submission.
    ///
    /// - Parameter disputeId: The unique identifier of the dispute to close.
    /// - Returns: A tuple of the closed ``FrameObjects/Dispute`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func closeDispute(disputeId: String) async throws -> (FrameObjects.Dispute?, NetworkingError?) {
        let endpoint = DisputeEndpoints.closeDispute(disputeId: disputeId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Dispute.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    /// Uploads one or more supporting documents for a dispute as a multipart form upload.
    ///
    /// - Parameters:
    ///   - disputeId: The unique identifier of the dispute to attach documents to.
    ///   - files: An array of ``FileUpload`` values representing the documents to upload.
    /// - Returns: An optional ``NetworkingError`` if the upload failed.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func uploadDocuments(disputeId: String, files: [FileUpload]) async throws -> NetworkingError? {
        guard !disputeId.isEmpty else { return nil }
        let endpoint = DisputeEndpoints.uploadDocuments(disputeId: disputeId)
        let (_, error) = try await FrameNetworking.shared.performMultipartDataTask(endpoint: endpoint, filesToUpload: files)
        return error
    }

    //completionHandler

    /// Completion-handler variant of ``updateDispute(disputeId:request:)``.
    ///
    /// - Parameters:
    ///   - disputeId: The unique identifier of the dispute to update.
    ///   - request: The update request body containing fields to modify.
    ///   - completionHandler: Called with the updated ``FrameObjects/Dispute`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func updateDispute(disputeId: String, request: DisputeRequests.UpdateDisputeRequest, completionHandler: @escaping @Sendable (FrameObjects.Dispute?, NetworkingError?) -> Void) {
        let endpoint = DisputeEndpoints.updateDispute(disputeId: disputeId)
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Dispute.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getDispute(disputeId:)``.
    ///
    /// - Parameters:
    ///   - disputeId: The unique identifier of the dispute to retrieve.
    ///   - completionHandler: Called with the fetched ``FrameObjects/Dispute`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getDispute(disputeId: String, completionHandler: @escaping @Sendable (FrameObjects.Dispute?, NetworkingError?) -> Void) {
        let endpoint = DisputeEndpoints.getDispute(disputeId: disputeId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Dispute.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``getDisputes(chargeId:chargeIntentId:perPage:page:)``.
    ///
    /// - Parameters:
    ///   - chargeId: An optional charge identifier to filter results.
    ///   - chargeIntentId: An optional charge intent identifier to filter results.
    ///   - perPage: The number of results to return per page. Defaults to `10`.
    ///   - page: The page number to retrieve. Defaults to `1`.
    ///   - completionHandler: Called with the ``DisputeResponses/ListDisputesResponse`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getDisputes(chargeId: String? = nil, chargeIntentId: String? = nil, perPage: Int = 10, page: Int = 1, completionHandler: @escaping @Sendable (DisputeResponses.ListDisputesResponse?, NetworkingError?) -> Void) {
        let endpoint = DisputeEndpoints.getDisputes(chargeId: chargeId, chargeIntentId: chargeIntentId, perPage: perPage, page: page)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(DisputeResponses.ListDisputesResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``closeDispute(disputeId:)``.
    ///
    /// - Parameters:
    ///   - disputeId: The unique identifier of the dispute to close.
    ///   - completionHandler: Called with the closed ``FrameObjects/Dispute`` and an optional ``NetworkingError``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func closeDispute(disputeId: String, completionHandler: @escaping @Sendable (FrameObjects.Dispute?, NetworkingError?) -> Void) {
        let endpoint = DisputeEndpoints.closeDispute(disputeId: disputeId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Dispute.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    /// Completion-handler variant of ``uploadDocuments(disputeId:files:)``.
    ///
    /// - Parameters:
    ///   - disputeId: The unique identifier of the dispute to attach documents to.
    ///   - files: An array of ``FileUpload`` values representing the documents to upload.
    ///   - completionHandler: Called with an optional ``NetworkingError`` if the upload failed.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func uploadDocuments(disputeId: String, files: [FileUpload], completionHandler: @escaping @Sendable (NetworkingError?) -> Void) {
        guard !disputeId.isEmpty else { return completionHandler(nil) }
        let endpoint = DisputeEndpoints.uploadDocuments(disputeId: disputeId)

        FrameNetworking.shared.performMultipartDataTask(endpoint: endpoint, filesToUpload: files) { _, _, error in
            completionHandler(error)
        }
    }
}
