import Foundation

/// Mints and uses a checkout client secret (`chk_sess_`).
///
/// `POST /v1/checkout_sessions` is secret-key only. Production apps mint the token on their
/// backend and pass ``FrameCheckoutClientSecret`` into checkout. Checkout calls the mint again
/// only when that token is expired and a secret key is configured.
public enum CheckoutSessionsAPI {
    /// Mints a checkout client secret for ``accountId``.
    ///
    /// - Parameter accountId: The account the token may read.
    /// - Returns: The session, and any networking error.
    public static func createCheckoutSession(
        accountId: String,
        amount: FrameObjects.TransferV2Money? = nil
    ) async throws -> (CheckoutSession?, NetworkingError?) {
        let endpoint = CheckoutSessionEndpoints.createCheckoutSession
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(
            CreateCheckoutSessionRequest(accountId: accountId, amount: amount)
        )
        // .secret is replaced by an active onboarding session. The mint only accepts sk_.
        let (data, error) = try await FrameNetworking.shared.performDataTask(
            endpoint: endpoint,
            requestBody: requestBody,
            auth: .clientSecret(FrameNetworking.shared.secretKeyCredential)
        )
        guard error == nil, let data,
              let session = try? FrameNetworking.shared.jsonDecoder.decode(CheckoutSession.self, from: data) else {
            return (nil, error)
        }
        return (session, nil)
    }

    static func loadAccount(accountId: String, secret: FrameCheckoutClientSecret) async -> (FrameObjects.AccountProfile?, NetworkingError?) {
        let endpoint = CheckoutSessionEndpoints.getAccount(accountId: accountId)
        let (data, error) = await authorizedData(accountId: accountId, secret: secret, endpoint: endpoint)
        guard error == nil, let data,
              let payload = try? FrameNetworking.shared.jsonDecoder.decode(CheckoutAccountPayload.self, from: data) else {
            return (nil, error)
        }
        let email = payload.profile?.individual?.email ?? payload.profile?.business?.email ?? ""
        SiftManager.collectLoginEvent(customerId: accountId, email: email)
        return (payload.profile, nil)
    }

    static func loadPaymentMethods(accountId: String, secret: FrameCheckoutClientSecret) async -> ([FrameObjects.PaymentMethod], NetworkingError?) {
        let endpoint = CheckoutSessionEndpoints.getPaymentMethods(accountId: accountId)
        let (data, error) = await authorizedData(accountId: accountId, secret: secret, endpoint: endpoint)
        guard error == nil, let data,
              let payload = try? FrameNetworking.shared.jsonDecoder.decode(CheckoutPaymentMethodList.self, from: data) else {
            return ([], error)
        }
        return (payload.data?.map { $0.paymentMethod() } ?? [], nil)
    }

    private static func authorizedData(accountId: String, secret: FrameCheckoutClientSecret, endpoint: CheckoutSessionEndpoints) async -> (Data?, NetworkingError?) {
        guard let token = await tokenForRead(accountId: accountId, secret: secret) else {
            return (nil, .serverError(statusCode: 401, errorDescription: "Checkout client secret expired."))
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

    /// A `chk_sess_…` that is still accepted. Refreshes `secret` in place when it has expired and a secret key is configured.
    static func authorizationToken(accountId: String, secret: FrameCheckoutClientSecret) async -> String? {
        await tokenForRead(accountId: accountId, secret: secret)
    }

    private static func tokenForRead(accountId: String, secret: FrameCheckoutClientSecret) async -> String? {
        if !secret.isExpired, !secret.clientSecret.isEmpty {
            return secret.clientSecret
        }
        return await refresh(accountId: accountId, secret: secret)
    }

    private static func refresh(accountId: String, secret: FrameCheckoutClientSecret) async -> String? {
        guard FrameNetworking.shared.hasSecretKey else { return nil }
        do {
            let lockedAmount = secret.amountCents.map {
                FrameObjects.TransferV2Money(value: $0, currency: secret.amountCurrency)
            }
            let (session, error) = try await createCheckoutSession(accountId: accountId, amount: lockedAmount)
            guard error == nil, let clientSecret = session?.clientSecret, !clientSecret.isEmpty else { return nil }
            secret.clientSecret = clientSecret
            if let expiresAt = session?.expiresAt {
                secret.expiresAt = Date(timeIntervalSince1970: TimeInterval(expiresAt))
            }
            if let amount = session?.amount {
                secret.amountCents = amount.value
                secret.amountCurrency = amount.currency
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
