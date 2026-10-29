import Foundation

/// Mints and uses a payout client secret (`pyt_sess_`).
///
/// `POST /v1/payout_sessions` is secret-key only. Production apps mint the token on their
/// backend and pass ``FramePayoutClientSecret`` into payout. Payout calls the mint again
/// only when that token is expired and a secret key is configured.
public enum PayoutSessionsAPI {
    /// Mints a payout client secret for ``accountId``.
    ///
    /// - Parameters:
    ///   - accountId: The account the token may read and pay out from.
    ///   - amount: Required cap. The client amount must be in `(0, cap]` in this currency.
    /// - Returns: The session, and any networking error.
    public static func createPayoutSession(
        accountId: String,
        amount: FrameObjects.TransferV2Money
    ) async throws -> (PayoutSession?, NetworkingError?) {
        let endpoint = PayoutSessionEndpoints.createPayoutSession
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(
            CreatePayoutSessionRequest(accountId: accountId, amount: amount)
        )
        // .secret is replaced by an active onboarding session. The mint only accepts sk_.
        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            requestBody: requestBody,
            auth: .clientSecret(FrameNetworking.shared.secretKeyCredential)
        )
        guard error == nil, let data,
              let session = try? FrameNetworking.shared.jsonDecoder.decode(PayoutSession.self, from: data) else {
            return (nil, error)
        }
        return (session, nil)
    }

    /// Reads `payout_payment_method_id` for ``accountId`` with the payout session.
    ///
    /// - Parameters:
    ///   - accountId: The account the token may read.
    ///   - secret: The payout session used as the Bearer token.
    /// - Returns: The elected payout method id, if any, and any networking error.
    public static func loadAccount(accountId: String, secret: FramePayoutClientSecret) async -> (String?, NetworkingError?) {
        let endpoint = PayoutSessionEndpoints.getAccount(accountId: accountId)
        let (data, error) = await authorizedData(accountId: accountId, secret: secret, endpoint: endpoint)
        guard error == nil, let data, let account = decodeAccountResource(data) else {
            return (nil, error)
        }
        return (account.payoutPaymentMethodId, nil)
    }

    /// Lists payment methods on ``accountId`` with the payout session.
    ///
    /// - Parameters:
    ///   - accountId: The account the token may read.
    ///   - secret: The payout session used as the Bearer token.
    /// - Returns: Saved methods, and any networking error.
    public static func loadPaymentMethods(accountId: String, secret: FramePayoutClientSecret) async -> ([FrameObjects.PaymentMethod], NetworkingError?) {
        let endpoint = PayoutSessionEndpoints.getPaymentMethods(accountId: accountId)
        let (data, error) = await authorizedData(accountId: accountId, secret: secret, endpoint: endpoint)
        guard error == nil, let data, let methods = decodeSessionPaymentMethods(data) else {
            return ([], error ?? .decodingFailed)
        }
        return (methods, nil)
    }

    private static func authorizedData(accountId: String, secret: FramePayoutClientSecret, endpoint: PayoutSessionEndpoints) async -> (Data?, NetworkingError?) {
        guard let token = await tokenForRead(accountId: accountId, secret: secret) else {
            return (nil, .serverError(statusCode: 401, errorDescription: "Payout client secret expired."))
        }
        do {
            let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .clientSecret(token))
            guard isUnauthorized(error) else { return (data, error) }
            guard let refreshed = await refresh(accountId: accountId, secret: secret) else {
                return (nil, error)
            }
            return try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .clientSecret(refreshed))
        } catch {
            return (nil, error as? NetworkingError)
        }
    }

    /// A `pyt_sess_…` that is still accepted. Refreshes `secret` in place when it has expired and a secret key is configured.
    ///
    /// - Parameters:
    ///   - accountId: The account the token was minted for.
    ///   - secret: The payout session to read or refresh.
    /// - Returns: A bearer token, or `nil` when the session is expired and cannot be refreshed.
    public static func authorizationToken(accountId: String, secret: FramePayoutClientSecret) async -> String? {
        await tokenForRead(accountId: accountId, secret: secret)
    }

    private static func tokenForRead(accountId: String, secret: FramePayoutClientSecret) async -> String? {
        if !secret.isExpired, !secret.clientSecret.isEmpty {
            return secret.clientSecret
        }
        return await refresh(accountId: accountId, secret: secret)
    }

    private static func refresh(accountId: String, secret: FramePayoutClientSecret) async -> String? {
        guard FrameNetworking.shared.hasSecretKey else { return nil }
        do {
            let amount = FrameObjects.TransferV2Money(value: secret.amountCents, currency: secret.amountCurrency)
            let (session, error) = try await createPayoutSession(accountId: accountId, amount: amount)
            guard error == nil, let clientSecret = session?.clientSecret, !clientSecret.isEmpty else { return nil }
            secret.clientSecret = clientSecret
            if let expiresAt = session?.expiresAt {
                secret.expiresAt = Date(timeIntervalSince1970: TimeInterval(expiresAt))
            }
            if let amount = session?.amount {
                secret.amountCents = amount.value
                secret.amountCurrency = amount.currency ?? secret.amountCurrency
            }
            return clientSecret
        } catch {
            return nil
        }
    }

    private static func isUnauthorized(_ error: NetworkingError?) -> Bool {
        guard case .serverError(let statusCode, _) = error else { return false }
        return statusCode == 401
    }
}
