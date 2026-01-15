//
//  InvoiceLineItemObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/4/25.
//

extension FrameObjects {
    public struct InvoiceLineItem: Codable, Sendable, Identifiable, Equatable  {
        public let id: String
        public let object: String
        public let description: String
        public let quantity: Int
        public let unitAmountCents: Int
        public let unitAmountCurrency: String
        public let created: Int
        public let updated: Int
        
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


