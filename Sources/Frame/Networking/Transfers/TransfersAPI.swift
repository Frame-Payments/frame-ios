//
//  TransfersAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 5/11/26.
//

import Foundation

// https://docs.framepayments.com/frameos/transfers

// Protocol for Mock Testing
protocol TransfersProtocol {
    //async/await
    static func createTransfer(request: TransferRequests.CreateTransferRequest) async throws -> (FrameObjects.Transfer?, NetworkingError?)
    static func getTransferWith(transferId: String) async throws -> (FrameObjects.Transfer?, NetworkingError?)
    static func getTransfers(perPage: Int?, page: Int?) async throws -> (TransferResponses.ListTransfersResponse?, NetworkingError?)

    // completionHandlers
    static func createTransfer(request: TransferRequests.CreateTransferRequest, completionHandler: @escaping @Sendable (FrameObjects.Transfer?, NetworkingError?) -> Void)
    static func getTransferWith(transferId: String, completionHandler: @escaping @Sendable (FrameObjects.Transfer?, NetworkingError?) -> Void)
    static func getTransfers(perPage: Int?, page: Int?, completionHandler: @escaping @Sendable (TransferResponses.ListTransfersResponse?, NetworkingError?) -> Void)
}

// Transfers API
public class TransfersAPI: TransfersProtocol, @unchecked Sendable {
    //async/await
    public static func createTransfer(request: TransferRequests.CreateTransferRequest) async throws -> (FrameObjects.Transfer?, NetworkingError?) {
        let endpoint = TransferEndpoints.createTransfer
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody)
        // Don't try to decode an error response as a Transfer — performDataTask
        // already mapped non-2xx to .serverError(statusCode:, errorDescription:);
        // attempting decode would overwrite that with .decodingFailed.
        if let error { return (nil, error) }
        guard let data else { return (nil, nil) }
        // Success path: surface decode failures as .decodingFailed instead of
        // (nil, nil), which would strand the caller with no signal.
        do {
            let decodedResponse = try FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Transfer.self, from: data)
            return (decodedResponse, nil)
        } catch {
            return (nil, .decodingFailed)
        }
    }

    public static func getTransferWith(transferId: String) async throws -> (FrameObjects.Transfer?, NetworkingError?) {
        guard !transferId.isEmpty else { return (nil, nil) }
        let endpoint = TransferEndpoints.getTransferWith(transferId: transferId)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Transfer.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    public static func getTransfers(perPage: Int? = nil, page: Int? = nil) async throws -> (TransferResponses.ListTransfersResponse?, NetworkingError?) {
        let endpoint = TransferEndpoints.getTransfers(perPage: perPage, page: page)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(TransferResponses.ListTransfersResponse.self, from: data) {
            return (decodedResponse, error)
        } else {
            return (nil, error)
        }
    }

    // completionHandlers
    public static func createTransfer(request: TransferRequests.CreateTransferRequest, completionHandler: @escaping @Sendable (FrameObjects.Transfer?, NetworkingError?) -> Void) {
        let endpoint = TransferEndpoints.createTransfer
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Transfer.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    public static func getTransferWith(transferId: String, completionHandler: @escaping @Sendable (FrameObjects.Transfer?, NetworkingError?) -> Void) {
        let endpoint = TransferEndpoints.getTransferWith(transferId: transferId)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Transfer.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }

    public static func getTransfers(perPage: Int? = nil, page: Int? = nil, completionHandler: @escaping @Sendable (TransferResponses.ListTransfersResponse?, NetworkingError?) -> Void) {
        let endpoint = TransferEndpoints.getTransfers(perPage: perPage, page: page)

        FrameNetworking.shared.performDataTask(endpoint: endpoint) { data, response, error in
            if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(TransferResponses.ListTransfersResponse.self, from: data) {
                completionHandler(decodedResponse, error)
            } else {
                completionHandler(nil, error)
            }
        }
    }
}
