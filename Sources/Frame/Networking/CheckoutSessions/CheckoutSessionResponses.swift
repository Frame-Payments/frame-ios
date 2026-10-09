import Foundation

/// A short-lived `chk_sess_` token that checkout uses to read a name, email, and saved cards.
///
/// Mint it on the host backend with `POST /v1/checkout_sessions`. Checkout refreshes it with the
/// secret key when ``expiresAt`` has passed or the API rejects it as expired.
public final class FrameCheckoutClientSecret: @unchecked Sendable {
    /// The `chk_sess_…` bearer token.
    public var clientSecret: String
    /// When the token stops being accepted, as a Unix timestamp in seconds.
    public var expiresAt: Date
    /// Locked amount in the smallest currency unit, when the session can create a transfer.
    public var amountCents: Int?
    /// Currency of ``amountCents``.
    public var amountCurrency: String?

    /// `true` when ``expiresAt`` is now or earlier.
    public var isExpired: Bool { expiresAt <= Date() }

    /// Creates a checkout client secret.
    /// - Parameters:
    ///   - clientSecret: The `chk_sess_…` token from `POST /v1/checkout_sessions`.
    ///   - expiresAt: The token's expiry.
    public init(clientSecret: String, expiresAt: Date, amountCents: Int? = nil, amountCurrency: String? = nil) {
        self.clientSecret = clientSecret
        self.expiresAt = expiresAt
        self.amountCents = amountCents
        self.amountCurrency = amountCurrency
    }

    /// Keeps a later refresh transfer-capable when the host passed only the token and expiry.
    func recordLockedAmountIfMissing(cents: Int, currency: String) {
        guard amountCents == nil, cents != 0 else { return }
        amountCents = cents
        if amountCurrency?.isEmpty != false {
            amountCurrency = currency
        }
    }
}

/// The checkout session returned by `POST /v1/checkout_sessions`.
public struct CheckoutSession: Codable, Sendable {
    /// The session identifier.
    @Lenient public private(set) var id: String?
    /// The account the token may read.
    @Lenient public private(set) var accountId: String?
    /// The `chk_sess_…` bearer token.
    @Lenient public private(set) var clientSecret: String?
    /// The object type. Always `"checkout_session"`.
    @Lenient public private(set) var object: String?
    /// Unix timestamp, in seconds, when the token expires.
    @Lenient public private(set) var expiresAt: Int?
    /// `true` for a live-mode session.
    @Lenient public private(set) var livemode: Bool?
    /// Locked amount, present when the session can create and confirm a V2 transfer.
    @Lenient public private(set) var amount: FrameObjects.TransferV2Money?

    enum CodingKeys: String, CodingKey {
        case id, object, livemode, amount
        case accountId = "account_id"
        case clientSecret = "client_secret"
        case expiresAt = "expires_at"
    }
}

struct CheckoutAccountPayload: Decodable {
    let profile: FrameObjects.AccountProfile?
}

struct CheckoutPaymentMethodList: Decodable {
    let data: [CheckoutPaymentMethodPayload]?
}

struct CheckoutPaymentMethodPayload: Decodable {
    let id: String
    let type: FrameObjects.PaymentRequestType
    let object: String
    let status: FrameObjects.PaymentMethodStatus
    let card: CheckoutCardPayload?
    let ach: CheckoutAchPayload?

    func paymentMethod() -> FrameObjects.PaymentMethod {
        let cardDetails = card.map {
            FrameObjects.PaymentCard(
                brand: $0.brand,
                expirationMonth: $0.expirationMonth,
                expirationYear: $0.expirationYear,
                currency: nil,
                lastFourDigits: $0.lastFour
            )
        }
        let achDetails = ach.map {
            FrameObjects.BankAccount(accountType: $0.accountType, lastFour: $0.lastFour)
        }
        return FrameObjects.PaymentMethod(
            id: id,
            type: type,
            object: object,
            created: 0,
            updated: 0,
            livemode: false,
            card: cardDetails,
            ach: achDetails,
            status: status
        )
    }
}

struct CheckoutCardPayload: Decodable {
    let brand: String
    let lastFour: String
    let expirationMonth: String?
    let expirationYear: String?

    enum CodingKeys: String, CodingKey {
        case brand
        case lastFour = "last_four"
        case expirationMonth = "exp_month"
        case expirationYear = "exp_year"
    }
}

struct CheckoutAchPayload: Decodable {
    let accountType: FrameObjects.PaymentAccountType?
    let lastFour: String?

    enum CodingKeys: String, CodingKey {
        case accountType = "account_type"
        case lastFour = "last_four"
    }
}
