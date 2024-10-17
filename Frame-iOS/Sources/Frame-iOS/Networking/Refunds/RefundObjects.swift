//
//  RefundObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

extension FrameObjects {
    public struct Refund: Codable {
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
        
        enum CodingKeys: String, CodingKey {
            case id, amount, charge, currency, description, status, object, created, updated
            case chargeIntent = "charge_intent"
            case failureReason = "failure_reason"
        }
    }
}
