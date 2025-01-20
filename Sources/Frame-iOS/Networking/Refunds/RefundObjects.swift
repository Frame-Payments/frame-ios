//
//  RefundObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

extension FrameObjects {
    public struct Refund: Codable, Sendable {
        let id: String
        let amount: Int
        let charge: String?
        let currency: String?
        let description: String?
        let chargeIntent: String?
        let status: String?
        let failureReason: String?
        let object: String
        let created: Int
        let updated: Int
        
        init(id: String, amount: Int, charge: String? = nil, currency: String? = nil, description: String? = nil, chargeIntent: String? = nil,
             status: String? = nil, failureReason: String? = nil, object: String, created: Int, updated: Int) {
            self.id = id
            self.amount = amount
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
        
        enum CodingKeys: String, CodingKey {
            case id, amount, charge, currency, description, status, object, created, updated
            case chargeIntent = "charge_intent"
            case failureReason = "failure_reason"
        }
    }
}
