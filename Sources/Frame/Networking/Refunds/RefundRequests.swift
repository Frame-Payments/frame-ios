//
//  RefundRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

/// Request body namespace for Refunds API calls.
public class RefundRequests {
    /// Request body for creating a new refund.
    public struct CreateRefundRequest: Codable {
        /// The amount to refund, in the smallest currency unit (e.g. cents).
        let amount: Int
        /// The identifier of the charge to refund.
        let charge: String
        /// The identifier of the charge intent associated with the refund.
        let chargeIntent: String
        /// The reason for issuing the refund.
        let reason: String

        enum CodingKeys: String, CodingKey {
            case amount, charge, reason
            case chargeIntent = "charge_intent"
        }
    }
}
