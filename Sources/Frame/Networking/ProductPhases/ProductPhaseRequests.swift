//
//  ProductPhaseRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/3/25.
//

import Foundation

/// Request body namespace for Product Phase API calls.
public class ProductPhaseRequests {
    /// Request body for creating a new product phase.
    public struct CreateProductPhase: Codable {
        /// The ordinal position of the phase within the product's phase sequence.
        let ordinal: Int
        /// The pricing strategy applied during this phase.
        let pricingType: FrameObjects.PhasePricingType
        /// An optional human-readable label for the phase.
        var name: String?
        /// The phase price in the smallest currency unit (e.g. cents for USD).
        var amountCents: Int?
        /// An optional discount applied to the phase price, expressed as a percentage.
        var discountPercentage: Float?
        /// The number of billing periods this phase spans.
        var periodCount: Int?

        enum CodingKeys: String, CodingKey {
            case ordinal, name
            case pricingType = "pricing_type"
            case amountCents = "amount_cents"
            case discountPercentage = "discount_percentage"
            case periodCount = "period_count"
        }
    }

    /// Request body for updating an existing product phase.
    public struct UpdateProductPhase: Codable {
        /// The updated ordinal position of the phase; omit to leave unchanged.
        var ordinal: Int?
        /// The updated pricing strategy; omit to leave unchanged.
        var pricingType: FrameObjects.PhasePricingType?
        /// The updated display name; omit to leave unchanged.
        var name: String?
        /// The updated price in the smallest currency unit; omit to leave unchanged.
        var amountCents: Int?
        /// The updated discount percentage; omit to leave unchanged.
        var discountPercentage: Float?
        /// The updated number of billing periods; omit to leave unchanged.
        var periodCount: Int?

        enum CodingKeys: String, CodingKey {
            case ordinal, name
            case pricingType = "pricing_type"
            case amountCents = "amount_cents"
            case discountPercentage = "discount_percentage"
            case periodCount = "period_count"
        }
    }

    /// Request body for replacing all phases on a product in a single bulk operation.
    public struct BulkUpdateProductPhase: Codable {
        /// The complete ordered list of subscription phases to apply to the product.
        let phases: [FrameObjects.SubscriptionPhase]
    }
}
