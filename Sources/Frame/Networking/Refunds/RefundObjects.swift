//
//  RefundObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

extension FrameObjects {
    /// Represents a refund issued against a captured charge in the Frame SDK.
    public struct Refund: Codable, Sendable, Identifiable, Equatable {
        /// Unique identifier for the refund.
        public let id: String
        /// Total amount captured on the original charge, in the smallest currency unit.
        public let amountCaptured: Int?
        /// Amount refunded, in the smallest currency unit.
        public let amountRefunded: Int?
        /// Identifier of the charge this refund is applied to.
        public let charge: String?
        /// Three-letter ISO currency code for the refund amount.
        public let currency: String?
        /// Human-readable description of the refund.
        public let description: String?
        /// Identifier of the charge intent associated with this refund.
        public let chargeIntent: String?
        /// Current status of the refund (e.g., `"succeeded"`, `"pending"`, `"failed"`).
        public let status: String?
        /// Reason the refund failed, if applicable.
        public let failureReason: String?
        /// Object type identifier returned by the Frame API.
        public let object: String?
        /// Unix timestamp (seconds) when the refund was created.
        public let created: Int
        /// Unix timestamp (seconds) when the refund was last updated.
        public let updated: Int

        /// Creates a new `Refund` value with the given field values.
        /// - Parameters:
        ///   - id: Unique identifier for the refund.
        ///   - amountCaptured: Total amount captured on the original charge, in the smallest currency unit.
        ///   - amountRefunded: Amount refunded, in the smallest currency unit.
        ///   - charge: Identifier of the charge this refund is applied to.
        ///   - currency: Three-letter ISO currency code.
        ///   - description: Human-readable description of the refund.
        ///   - chargeIntent: Identifier of the associated charge intent.
        ///   - status: Current status of the refund.
        ///   - failureReason: Reason the refund failed, if applicable.
        ///   - object: Object type identifier returned by the Frame API.
        ///   - created: Unix timestamp (seconds) when the refund was created.
        ///   - updated: Unix timestamp (seconds) when the refund was last updated.
        public init(id: String, amountCaptured: Int? = nil, amountRefunded: Int? = nil, charge: String? = nil, currency: String? = nil, description: String? = nil, chargeIntent: String? = nil, status: String? = nil, failureReason: String? = nil, object: String? = nil, created: Int, updated: Int) {
            self.id = id
            self.amountCaptured = amountCaptured
            self.amountRefunded = amountRefunded
            self.charge = charge
            self.currency = currency
            self.description = description
            self.chargeIntent = chargeIntent
            self.status = status
            self.failureReason = failureReason
            self.object = object
            self.created = created
            self.updated = updated
        }

        /// Maps Swift property names to their snake_case JSON keys from the Frame API.
        public enum CodingKeys: String, CodingKey {
            case id, charge, currency, description, status, object, created, updated
            /// JSON key: `amount_captured`
            case amountCaptured = "amount_captured"
            /// JSON key: `amount_refunded`
            case amountRefunded = "amount_refunded"
            /// JSON key: `charge_intent`
            case chargeIntent = "charge_intent"
            /// JSON key: `failure_reason`
            case failureReason = "failure_reason"
        }
    }
}
