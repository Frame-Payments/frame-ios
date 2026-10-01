//
//  TransfersV2API.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/29/26.
//

import Foundation

// Protocol for Mock Testing
protocol TransfersV2Protocol {
    static func createTransfer(
        request: TransferV2Requests.CreateTransferRequest,
        idempotencyKey: String?
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?)
    static func getTransferWith(transferId: String) async throws -> (FrameObjects.TransferV2?, NetworkingError?)
    static func getTransfers(perPage: Int?, page: Int?) async throws -> (TransferV2Responses.ListTransfersResponse?, NetworkingError?)
    static func updateTransfer(
        transferId: String,
        request: TransferV2Requests.UpdateTransferRequest
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?)
    static func confirmTransfer(
        transferId: String,
        request: TransferV2Requests.CreateTransferRequest?,
        idempotencyKey: String?
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?)
    static func captureTransfer(
        transferId: String,
        request: TransferV2Requests.AmountOnlyRequest?,
        idempotencyKey: String?
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?)
    static func voidTransfer(
        transferId: String,
        idempotencyKey: String?
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?)
    static func refundTransfer(
        transferId: String,
        request: TransferV2Requests.AmountOnlyRequest?,
        idempotencyKey: String?
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?)
}

/// Manages V2 transfer resources (`/v2/transfers`) in the Frame Payments SDK.
///
/// Additive alongside ``TransfersAPI`` (V1). Money movement authenticates with the secret key.
public class TransfersV2API: TransfersV2Protocol, @unchecked Sendable {

    /// Attaches Sonar when the create has a payment-method source (charge-backed).
    private static func withSonarSession(
        _ request: TransferV2Requests.CreateTransferRequest
    ) async -> TransferV2Requests.CreateTransferRequest {
        let accountId = request.source?.paymentMethod?.accountId
            ?? request.source?.accountId
        let hasPaymentSource = request.source?.paymentMethodId != nil
            || request.source?.paymentMethod != nil
        guard hasPaymentSource, let accountId, !accountId.isEmpty else { return request }

        var updated = request
        updated.sonarSessionId = try? await SessionManager.shared.ensureSession(accountId: accountId)
        return updated
    }

    private static func decodeTransfer(_ data: Data?) -> (FrameObjects.TransferV2?, NetworkingError?) {
        guard let data else { return (nil, nil) }
        do {
            let decoded = try FrameNetworking.shared.jsonDecoder.decode(FrameObjects.TransferV2.self, from: data)
            return (decoded, nil)
        } catch {
            return (nil, .decodingFailed)
        }
    }

    private static func encodeBody<T: Encodable>(_ value: T?) -> Data? {
        guard let value else { return nil }
        return try? FrameNetworking.shared.jsonEncoder.encode(value)
    }

    // MARK: - async/await

    /// Creates a V2 transfer. Requires an `Idempotency-Key` (generated when `idempotencyKey` is `nil`).
    ///
    /// - Important: Money movement is server-only; authenticates with the secret key.
    public static func createTransfer(
        request: TransferV2Requests.CreateTransferRequest,
        idempotencyKey: String? = nil
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        let key = (idempotencyKey?.isEmpty == false) ? idempotencyKey! : UUID().uuidString
        let endpoint = TransferV2Endpoints.createTransfer(idempotencyKey: key)
        let body = encodeBody(await withSonarSession(request))
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: body)
        if let error { return (nil, error) }
        return decodeTransfer(data)
    }

    /// Retrieves a single V2 transfer by id.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getTransferWith(transferId: String) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        guard !transferId.isEmpty else { return (nil, nil) }
        let endpoint = TransferV2Endpoints.getTransferWith(transferId: transferId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let error { return (nil, error) }
        return decodeTransfer(data)
    }

    /// Lists V2 transfers with optional pagination.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getTransfers(
        perPage: Int? = nil,
        page: Int? = nil
    ) async throws -> (TransferV2Responses.ListTransfersResponse?, NetworkingError?) {
        let endpoint = TransferV2Endpoints.getTransfers(perPage: perPage, page: page)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let error { return (nil, error) }
        guard let data else { return (nil, nil) }
        do {
            let decoded = try FrameNetworking.shared.jsonDecoder.decode(
                TransferV2Responses.ListTransfersResponse.self,
                from: data
            )
            return (decoded, nil)
        } catch {
            return (nil, .decodingFailed)
        }
    }

    /// Updates a deferred-confirm payment transfer before confirm.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func updateTransfer(
        transferId: String,
        request: TransferV2Requests.UpdateTransferRequest
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        guard !transferId.isEmpty else { return (nil, nil) }
        let endpoint = TransferV2Endpoints.updateTransfer(transferId: transferId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            requestBody: encodeBody(request)
        )
        if let error { return (nil, error) }
        return decodeTransfer(data)
    }

    /// Confirms a deferred-confirm payment transfer with the secret key (server-side).
    ///
    /// Sends an `Idempotency-Key` (generated when `idempotencyKey` is `nil`).
    public static func confirmTransfer(
        transferId: String,
        request: TransferV2Requests.CreateTransferRequest? = nil,
        idempotencyKey: String? = nil
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        guard !transferId.isEmpty else { return (nil, nil) }
        let key = (idempotencyKey?.isEmpty == false) ? idempotencyKey! : UUID().uuidString
        let endpoint = TransferV2Endpoints.confirmTransfer(transferId: transferId, idempotencyKey: key)
        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            requestBody: encodeBody(request)
        )
        if let error { return (nil, error) }
        return decodeTransfer(data)
    }

    /// Confirms a server-minted V2 transfer in-app using its `client_secret` (publishable auth).
    ///
    /// Mirrors ``ChargeIntentsAPI/confirmChargeIntent(intentId:clientSecret:)``.
    /// Does not send `Idempotency-Key` — publishable confirm is exempt on the API.
    public static func confirmTransfer(
        transferId: String,
        clientSecret: String
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        guard !transferId.isEmpty, !clientSecret.isEmpty else { return (nil, nil) }
        let endpoint = TransferV2Endpoints.confirmTransfer(transferId: transferId, idempotencyKey: nil)
        let body = TransferV2Requests.ConfirmWithClientSecretRequest(clientSecret: clientSecret)
        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            requestBody: encodeBody(body),
            auth: .publishable
        )
        if let error { return (nil, error) }
        return decodeTransfer(data)
    }

    /// Retrieves a server-minted V2 transfer in-app using its `client_secret` (publishable auth).
    public static func getTransferWith(
        transferId: String,
        clientSecret: String
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        guard !transferId.isEmpty, !clientSecret.isEmpty else { return (nil, nil) }
        let endpoint = TransferV2Endpoints.getTransferWith(transferId: transferId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            auth: .publishable
        )
        if let error { return (nil, error) }
        return decodeTransfer(data)
    }

    /// Captures a manually authorized payment transfer (optional partial amount).
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func captureTransfer(
        transferId: String,
        request: TransferV2Requests.AmountOnlyRequest? = nil,
        idempotencyKey: String? = nil
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        guard !transferId.isEmpty else { return (nil, nil) }
        let key = (idempotencyKey?.isEmpty == false) ? idempotencyKey! : UUID().uuidString
        let endpoint = TransferV2Endpoints.captureTransfer(transferId: transferId, idempotencyKey: key)
        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            requestBody: encodeBody(request)
        )
        if let error { return (nil, error) }
        return decodeTransfer(data)
    }

    /// Voids a manually authorized payment transfer.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func voidTransfer(
        transferId: String,
        idempotencyKey: String? = nil
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        guard !transferId.isEmpty else { return (nil, nil) }
        let key = (idempotencyKey?.isEmpty == false) ? idempotencyKey! : UUID().uuidString
        let endpoint = TransferV2Endpoints.voidTransfer(transferId: transferId, idempotencyKey: key)
        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let error { return (nil, error) }
        return decodeTransfer(data)
    }

    /// Refunds a succeeded payment transfer (optional partial amount).
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func refundTransfer(
        transferId: String,
        request: TransferV2Requests.AmountOnlyRequest? = nil,
        idempotencyKey: String? = nil
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        guard !transferId.isEmpty else { return (nil, nil) }
        let key = (idempotencyKey?.isEmpty == false) ? idempotencyKey! : UUID().uuidString
        let endpoint = TransferV2Endpoints.refundTransfer(transferId: transferId, idempotencyKey: key)
        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            requestBody: encodeBody(request)
        )
        if let error { return (nil, error) }
        return decodeTransfer(data)
    }

    // MARK: - Completion handlers

    /// Completion-handler variant of ``createTransfer(request:idempotencyKey:)``.
    public static func createTransfer(
        request: TransferV2Requests.CreateTransferRequest,
        idempotencyKey: String? = nil,
        completionHandler: @escaping @Sendable (FrameObjects.TransferV2?, NetworkingError?) -> Void
    ) {
        Task {
            do {
                let result = try await createTransfer(request: request, idempotencyKey: idempotencyKey)
                completionHandler(result.0, result.1)
            } catch {
                completionHandler(nil, .unknownError)
            }
        }
    }

    /// Completion-handler variant of ``getTransferWith(transferId:)``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getTransferWith(
        transferId: String,
        completionHandler: @escaping @Sendable (FrameObjects.TransferV2?, NetworkingError?) -> Void
    ) {
        Task {
            do {
                let result = try await getTransferWith(transferId: transferId)
                completionHandler(result.0, result.1)
            } catch {
                completionHandler(nil, .unknownError)
            }
        }
    }

    /// Completion-handler variant of ``getTransfers(perPage:page:)``.
    @available(*, deprecated, message: "Server-only — call this from your backend with your secret key (sk_), not from the app.")
    public static func getTransfers(
        perPage: Int? = nil,
        page: Int? = nil,
        completionHandler: @escaping @Sendable (TransferV2Responses.ListTransfersResponse?, NetworkingError?) -> Void
    ) {
        Task {
            do {
                let result = try await getTransfers(perPage: perPage, page: page)
                completionHandler(result.0, result.1)
            } catch {
                completionHandler(nil, .unknownError)
            }
        }
    }

    /// Completion-handler variant of ``confirmTransfer(transferId:request:)``.
    public static func confirmTransfer(
        transferId: String,
        request: TransferV2Requests.CreateTransferRequest? = nil,
        completionHandler: @escaping @Sendable (FrameObjects.TransferV2?, NetworkingError?) -> Void
    ) {
        Task {
            do {
                let result = try await confirmTransfer(transferId: transferId, request: request)
                completionHandler(result.0, result.1)
            } catch {
                completionHandler(nil, .unknownError)
            }
        }
    }
}
