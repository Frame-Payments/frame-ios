//
//  InvoiceLineItemObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

extension FrameObjects {
    /// A single line item on an invoice, representing a product or service charge.
    public struct InvoiceLineItem: Codable, Sendable, Identifiable, Equatable  {
        /// Unique identifier for the invoice line item.
        public let id: String
        /// Object type identifier returned by the Frame API.
        public let object: String
        /// Human-readable description of the line item.
        public let description: String
        /// Number of units included in this line item.
        public let quantity: Int
        /// Per-unit price in the smallest currency unit (e.g., cents for USD).
        public let unitAmountCents: Int
        /// ISO 4217 currency code for ``unitAmountCents`` (e.g., `"usd"`).
        public let unitAmountCurrency: String
        /// Unix timestamp (seconds) when the line item was created.
        public let created: Int
        /// Unix timestamp (seconds) when the line item was last updated.
        public let updated: Int

        /// Creates a new ``InvoiceLineItem`` with all required fields.
        /// - Parameters:
        ///   - id: Unique identifier for the line item.
        ///   - object: Object type identifier returned by the Frame API.
        ///   - description: Human-readable description of the line item.
        ///   - quantity: Number of units included in this line item.
        ///   - unitAmountCents: Per-unit price in the smallest currency unit.
        ///   - unitAmountCurrency: ISO 4217 currency code for the unit amount.
        ///   - created: Unix timestamp (seconds) when the line item was created.
        ///   - updated: Unix timestamp (seconds) when the line item was last updated.
        public init(id: String, object: String, description: String, quantity: Int, unitAmountCents: Int, unitAmountCurrency: String, created: Int, updated: Int) {
            self.id = id
            self.object = object
            self.description = description
            self.quantity = quantity
            self.unitAmountCents = unitAmountCents
            self.unitAmountCurrency = unitAmountCurrency
            self.created = created
            self.updated = updated
        }

        enum CodingKeys: String, CodingKey {
            case id, object, description, quantity, created, updated
            case unitAmountCents = "unit_amount_cents"
            case unitAmountCurrency = "unit_amount_currency"
        }
    }
}


