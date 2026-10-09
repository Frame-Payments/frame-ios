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
        idempotencyKey: String?,
        accountId: String?
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

/// Manages transfer resources (`/v2/transfers`) in the Frame Payments SDK.
///
/// Capture, void, refund, update, and list authenticate with the secret key. Checkout create,
/// show, and confirm authenticate with a `chk_sess_` token minted with a locked amount.
public class TransfersV2API: TransfersV2Protocol, @unchecked Sendable {

    /// Attaches Sonar on a payment-method create. The account is the global one, or `accountId` when that is unset.
    private static func withSonarSession(
        _ request: TransferV2Requests.CreateTransferRequest,
        accountId: String?
    ) async -> TransferV2Requests.CreateTransferRequest {
        let resolved = FrameNetworking.shared.accountId ?? accountId
        let hasPaymentSource = request.source?.paymentMethodId != nil
            || request.source?.paymentMethod != nil
        guard hasPaymentSource, let resolved, !resolved.isEmpty else { return request }

        var updated = request
        updated.sonarSessionId = try? await SessionManager.shared.ensureSession(accountId: resolved)
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

    /// Creates a V2 transfer with the secret key. Requires an `Idempotency-Key` (generated when `idempotencyKey` is `nil`).
    ///
    /// Checkout should call ``createTransfer(request:idempotencyKey:checkoutClientSecret:)`` instead.
    public static func createTransfer(
        request: TransferV2Requests.CreateTransferRequest,
        idempotencyKey: String? = nil,
        accountId: String? = nil
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        try await createTransfer(request: request, idempotencyKey: idempotencyKey, accountId: accountId, auth: .secret)
    }

    /// Creates a V2 transfer as a checkout session (`Authorization: Bearer chk_sess_…`).
    ///
    /// The session must have been minted with a locked amount. The request amount has to match
    /// that lock; source must be a payment method on the session account. Requires an
    /// `Idempotency-Key` (generated when `idempotencyKey` is `nil`).
    public static func createTransfer(
        request: TransferV2Requests.CreateTransferRequest,
        idempotencyKey: String? = nil,
        checkoutClientSecret: String,
        accountId: String? = nil
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        guard !checkoutClientSecret.isEmpty else { return (nil, nil) }
        return try await createTransfer(
            request: request,
            idempotencyKey: idempotencyKey,
            accountId: accountId,
            auth: .clientSecret(checkoutClientSecret)
        )
    }

    private static func createTransfer(
        request: TransferV2Requests.CreateTransferRequest,
        idempotencyKey: String?,
        accountId: String?,
        auth: FrameAuthMode
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        let key = (idempotencyKey?.isEmpty == false) ? idempotencyKey! : UUID().uuidString
        let endpoint = TransferV2Endpoints.createTransfer(idempotencyKey: key)
        let body = encodeBody(await withSonarSession(request, accountId: accountId))
        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            requestBody: body,
            auth: auth
        )
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

    /// Confirms a deferred-confirm payment transfer as a checkout session (`Bearer chk_sess_…`).
    ///
    /// Does not send `Idempotency-Key`. Capture, void, and refund stay secret-key only.
    public static func confirmTransfer(
        transferId: String,
        request: TransferV2Requests.CreateTransferRequest? = nil,
        checkoutClientSecret: String
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        guard !transferId.isEmpty, !checkoutClientSecret.isEmpty else { return (nil, nil) }
        let endpoint = TransferV2Endpoints.confirmTransfer(transferId: transferId, idempotencyKey: nil)
        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            requestBody: encodeBody(request),
            auth: .clientSecret(checkoutClientSecret)
        )
        if let error { return (nil, error) }
        return decodeTransfer(data)
    }

    /// Retrieves a V2 transfer created by this checkout session (`Bearer chk_sess_…`).
    public static func getTransferWith(
        transferId: String,
        checkoutClientSecret: String
    ) async throws -> (FrameObjects.TransferV2?, NetworkingError?) {
        guard !transferId.isEmpty, !checkoutClientSecret.isEmpty else { return (nil, nil) }
        let endpoint = TransferV2Endpoints.getTransferWith(transferId: transferId)
        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            auth: .clientSecret(checkoutClientSecret)
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
        accountId: String? = nil,
        completionHandler: @escaping @Sendable (FrameObjects.TransferV2?, NetworkingError?) -> Void
    ) {
        Task {
            do {
                let result = try await createTransfer(request: request, idempotencyKey: idempotencyKey, accountId: accountId)
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
