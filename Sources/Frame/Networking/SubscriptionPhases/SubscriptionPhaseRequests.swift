//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

/// Request body namespace for Subscription Phase API calls.
public class SubscriptionPhaseRequests {
    /// Request body for creating a new subscription phase.
    public struct CreateSubscriptionPhase: Codable {
        /// The ordinal position of this phase within the subscription plan.
        let ordinal: Int
        /// The pricing model applied during this phase.
        let pricingType: FrameObjects.PhasePricingType
        /// Determines whether the phase runs for a fixed period or indefinitely.
        let durationType: FrameObjects.PhaseDurationType
        /// Optional display name for the phase.
        var name: String?
        /// Fixed price for the phase in cents; used when `pricingType` is a flat amount.
        var amountCents: Int?
        /// Percentage discount applied during the phase; used when `pricingType` is a discount.
        var discountPercentage: Float?
        /// Number of billing periods the phase lasts; used when `durationType` is fixed.
        var periodCount: Int?
        /// Billing interval unit (e.g., `"month"`, `"year"`).
        var interval: String?
        /// Number of interval units per billing cycle.
        var intervalCount: Int?

        enum CodingKeys: String, CodingKey {
            case ordinal, name, interval
            case durationType = "duration_type"
            case pricingType = "pricing_type"
            case amountCents = "amount_cents"
            case discountPercentage = "discount_percentage"
            case periodCount = "period_count"
            case intervalCount = "interval_count"
        }
    }

    /// Request body for updating an existing subscription phase.
    public struct UpdateSubscriptionPhase: Codable {
        /// Updated ordinal position of the phase; omit to leave unchanged.
        var ordinal: Int?
        /// Updated pricing model for the phase; omit to leave unchanged.
        var pricingType: FrameObjects.PhasePricingType?
        /// Updated duration type for the phase; omit to leave unchanged.
        var durationType: FrameObjects.PhaseDurationType?
        /// Updated display name for the phase; omit to leave unchanged.
        var name: String?
        /// Updated fixed price in cents; omit to leave unchanged.
        var amountCents: Int?
        /// Updated discount percentage; omit to leave unchanged.
        var discountPercentage: Float?
        /// Updated number of billing periods; omit to leave unchanged.
        var periodCount: Int?
        /// Updated billing interval unit; omit to leave unchanged.
        var interval: String?
        /// Updated number of interval units per billing cycle; omit to leave unchanged.
        var intervalCount: Int?

        enum CodingKeys: String, CodingKey {
            case ordinal, name, interval
            case durationType = "duration_type"
            case pricingType = "pricing_type"
            case amountCents = "amount_cents"
            case discountPercentage = "discount_percentage"
            case periodCount = "period_count"
            case intervalCount = "interval_count"
        }
    }

    /// Request body for replacing all phases of a subscription plan in a single bulk operation.
    public struct BulkUpdateScriptionPhase: Codable {
        /// The complete ordered list of phases that will replace the existing phases.
        let phases: [FrameObjects.SubscriptionPhase]
    }
}
