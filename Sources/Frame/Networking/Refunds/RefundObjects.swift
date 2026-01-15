//
//  RefundObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

extension FrameObjects {
    public struct Refund: Codable, Sendable, Identifiable, Equatable {
        public let id: String
        public let amountCaptured: Int?
        public let amountRefunded: Int?
        public let charge: String?
        public let currency: String?
        public let description: String?
        public let chargeIntent: String?
        public let status: String?
        public let failureReason: String?
        public let object: String?
        public let created: Int
        public let updated: Int
        
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
        
        public enum CodingKeys: String, CodingKey {
            case id, charge, currency, description, status, object, created, updated
            case amountCaptured = "amount_captured"
            case amountRefunded = "amount_refunded"
            case chargeIntent = "charge_intent"
            case failureReason = "failure_reason"
        }
    }
}
