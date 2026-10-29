import Foundation

/// A short-lived `pyt_sess_` token that payout uses to list banks, elect a destination, and create a transfer.
///
/// Mint it on the host backend with `POST /v1/payout_sessions`. Payout refreshes it with the
/// secret key when ``expiresAt`` has passed or the API rejects it as expired.
public final class FramePayoutClientSecret: @unchecked Sendable {
    /// The `pyt_sess_…` bearer token.
    public var clientSecret: String
    /// When the token stops being accepted, as a Unix timestamp in seconds.
    public var expiresAt: Date
    /// Maximum amount in the smallest currency unit the session may pay out.
    public var amountCents: Int
    /// Currency of ``amountCents``.
    public var amountCurrency: String

    private let refreshGate = PayoutSessionRefreshGate()

    /// `true` when ``expiresAt`` is now or earlier.
    public var isExpired: Bool { expiresAt <= Date() }

    /// Creates a payout client secret.
    /// - Parameters:
    ///   - clientSecret: The `pyt_sess_…` token from `POST /v1/payout_sessions`.
    ///   - expiresAt: The token's expiry.
    ///   - amountCents: Session amount cap in the smallest currency unit.
    ///   - amountCurrency: ISO 4217 currency of ``amountCents``.
    public init(clientSecret: String, expiresAt: Date, amountCents: Int, amountCurrency: String = "usd") {
        self.clientSecret = clientSecret
        self.expiresAt = expiresAt
        self.amountCents = amountCents
        self.amountCurrency = amountCurrency
    }

    /// One in-flight mint at a time; overlapping callers share that result.
    func serializedRefresh(_ body: @escaping @Sendable () async -> String?) async -> String? {
        await refreshGate.run(body)
    }
}

private actor PayoutSessionRefreshGate {
    private var task: Task<String?, Never>?

    func run(_ body: @escaping @Sendable () async -> String?) async -> String? {
        if let task {
            return await task.value
        }
        let created = Task { await body() }
        task = created
        let token = await created.value
        task = nil
        return token
    }
}

/// The payout session returned by `POST /v1/payout_sessions`.
public struct PayoutSession: Codable, Sendable {
    /// The session identifier.
    @Lenient public private(set) var id: String?
    /// The account the token may read and pay out from.
    @Lenient public private(set) var accountId: String?
    /// The `pyt_sess_…` bearer token.
    @Lenient public private(set) var clientSecret: String?
    /// The object type. Always `"payout_session"`.
    @Lenient public private(set) var object: String?
    /// Unix timestamp, in seconds, when the token expires.
    @Lenient public private(set) var expiresAt: Int?
    /// `true` for a live-mode session.
    @Lenient public private(set) var livemode: Bool?
    /// Amount cap. The client amount must be in `(0, cap]` in this currency.
    @Lenient public private(set) var amount: FrameObjects.TransferV2Money?

    enum CodingKeys: String, CodingKey {
        case id, object, livemode, amount
        case accountId = "account_id"
        case clientSecret = "client_secret"
        case expiresAt = "expires_at"
    }
}

struct PayoutAccountPayload: Decodable {
    let id: String
    let object: String
    let payoutPaymentMethodId: String?

    enum CodingKeys: String, CodingKey {
        case id, object
        case payoutPaymentMethodId = "payout_payment_method_id"
    }

    func account() -> FrameObjects.Account {
        FrameObjects.Account(
            id: id,
            object: object,
            accountType: .individual,
            accountStatus: .active,
            payoutPaymentMethodId: payoutPaymentMethodId,
            created: 0,
            updated: 0,
            livemode: false
        )
    }
}

func decodeAccountResource(_ data: Data) -> FrameObjects.Account? {
    if let account = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.Account.self, from: data) {
        return account
    }
    guard let payload = try? FrameNetworking.shared.jsonDecoder.decode(PayoutAccountPayload.self, from: data),
          payload.object == "account" else {
        return nil
    }
    return payload.account()
}
