//
//  TransferRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 5/11/26.
//

import Foundation

public class TransferRequests {
    public struct CreateTransferRequest: Codable {
        public let amount: Int
        public let accountId: String
        public let currency: String?
        public let sourcePaymentMethodId: String?
        public let destinationPaymentMethodId: String?
        public let description: String?
        public let metadata: [String: String]?

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
