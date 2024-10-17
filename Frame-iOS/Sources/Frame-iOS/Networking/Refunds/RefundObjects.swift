//
//  RefundObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

extension FrameObjects {
    public enum RefundReason: String, Codable {
        case duplicate
        case expired = "expired_uncaptured_charge"
        case fraudulent
        case requested = "requested_by_customer"
    }
    
    public struct Refund: Codable {
        let id: String
        let amount: Int
        let charge: String?
        let currency: String?
        let description: String?
        let chargeIntent: String?
        let reason: RefundReason?
        let status: String?
        let failureReason: String?
        let object: String
        let created: Int
        let updated: Int
        
        enum CodingKeys: String, CodingKey {
            case id, amount, charge, currency, description, reason, status, object, created, updated
            case chargeIntent = "charge_intent"
            case failureReason = "failure_reason"
        }
    }
}
