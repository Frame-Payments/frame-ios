//
//  TransferRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 5/11/26.
//

import Foundation

/// Request body namespace for Transfer API calls.
public class TransferRequests {
    /// Request body used to create a new transfer between accounts.
    public struct CreateTransferRequest: Codable {
        /// The transfer amount in the smallest currency unit (e.g., cents for USD).
        public let amount: Int

        /// The identifier of the account associated with this transfer.
        public let accountId: String

        /// The ISO 4217 currency code for the transfer (e.g., `"usd"`). Defaults to the account currency when `nil`.
        public let currency: String?

        /// The identifier of the payment method to debit funds from.
        public let sourcePaymentMethodId: String?

        /// The identifier of the payment method to credit funds to.
        public let destinationPaymentMethodId: String?

        /// An optional human-readable description of the transfer.
        public let description: String?

        /// Arbitrary key-value metadata to attach to the transfer.
        public let metadata: [String: String]?

        /// Creates a new ``CreateTransferRequest``.
        ///
        /// - Parameters:
        ///   - amount: The transfer amount in the smallest currency unit.
        ///   - accountId: The identifier of the account associated with this transfer.
        ///   - currency: The ISO 4217 currency code. Pass `nil` to use the account default.
        ///   - sourcePaymentMethodId: The payment method to debit. Pass `nil` if not applicable.
        ///   - destinationPaymentMethodId: The payment method to credit. Pass `nil` if not applicable.
        ///   - description: An optional human-readable description of the transfer.
        ///   - metadata: Arbitrary key-value metadata to attach to the transfer.
        public init(amount: Int,
                    accountId: String,
                    currency: String? = nil,
                    sourcePaymentMethodId: String? = nil,
                    destinationPaymentMethodId: String? = nil,
                    description: String? = nil,
                    metadata: [String: String]? = nil) {
            self.amount = amount
            self.accountId = accountId
            self.currency = currency
            self.sourcePaymentMethodId = sourcePaymentMethodId
            self.destinationPaymentMethodId = destinationPaymentMethodId
            self.description = description
            self.metadata = metadata
        }

        enum CodingKeys: String, CodingKey {
            case amount, currency, description, metadata
            case accountId = "account_id"
            case sourcePaymentMethodId = "source_payment_method_id"
            case destinationPaymentMethodId = "destination_payment_method_id"
        }
    }
}
