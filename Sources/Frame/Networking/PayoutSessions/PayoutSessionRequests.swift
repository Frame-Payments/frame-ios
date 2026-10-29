import Foundation

/// Request body for `POST /v1/payout_sessions`.
///
/// The host backend mints this with a secret key. The SDK calls it only to replace a
/// `pyt_sess_` token that has expired, and only when a secret key is configured.
public struct CreatePayoutSessionRequest: Codable, Sendable {
    /// The account the payout token may read and pay out from.
    public let accountId: String
    /// Maximum `{ value, currency }` the session may pay out. Required.
    public let amount: FrameObjects.TransferV2Money

    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case amount
    }

    /// Creates a payout-session request for one account.
    /// - Parameters:
    ///   - accountId: The account the token may read and pay out from.
    ///   - amount: Cap `{ value, currency }`. The client amount must be in `(0, cap]`.
    public init(accountId: String, amount: FrameObjects.TransferV2Money) {
        self.accountId = accountId
        self.amount = amount
    }
}
