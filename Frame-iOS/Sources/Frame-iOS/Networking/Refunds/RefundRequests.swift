//
//  RefundRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

public class RefundRequests {
    public struct CreateRefundRequest: Codable {
        let amount: Int
        let charge: String
        let chargeIntent: String
        let reason: String
        
        enum CodingKeys: String, CodingKey {
            case amount, charge, reason
            case chargeIntent = "charge_intent"
        }
    }
}
