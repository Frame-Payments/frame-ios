import Foundation

/// Request body for `POST /v1/checkout_sessions`.
///
/// The host backend mints this with a secret key. The SDK calls it only to replace a
/// `chk_sess_` token that has expired, and only when a secret key is configured.
public struct CreateCheckoutSessionRequest: Codable, Sendable {
    /// The account the checkout token may read.
    public let accountId: String

    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
    }

    /// Creates a checkout-session request for one account.
    /// - Parameter accountId: The account the token may read.
    public init(accountId: String) {
        self.accountId = accountId
    }
}
