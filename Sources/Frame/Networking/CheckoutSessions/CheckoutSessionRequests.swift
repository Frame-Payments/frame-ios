import Foundation

/// Request body for `POST /v1/checkout_sessions`.
///
/// The host backend mints this with a secret key. The SDK calls it only to replace a
/// `chk_sess_` token that has expired, and only when a secret key is configured.
public struct CreateCheckoutSessionRequest: Codable, Sendable {
    /// The account the checkout token may read.
    public let accountId: String
    /// Locked charge amount. Present when the session may create and confirm a V2 transfer.
    public let amount: FrameObjects.TransferV2Money?

    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case amount
    }

    /// Creates a checkout-session request for one account.
    /// - Parameters:
    ///   - accountId: The account the token may read.
    ///   - amount: Locked `{ value, currency }` when the session should move money.
    public init(accountId: String, amount: FrameObjects.TransferV2Money? = nil) {
        self.accountId = accountId
        self.amount = amount
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountId, forKey: .accountId)
        try container.encodeIfPresent(amount, forKey: .amount)
    }
}
