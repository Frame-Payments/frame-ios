//
//  ProductPhaseRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/3/25.
//

import Foundation

public class ProductPhaseRequests {
    public struct CreateProductPhase: Codable {
        let ordinal: Int
        let pricingType: FrameObjects.PhasePricingType
        var name: String?
        var amountCents: Int?
        var discountPercentage: Float?
        var periodCount: Int?
        
        enum CodingKeys: String, CodingKey {
            case ordinal, name
            case pricingType = "pricing_type"
            case amountCents = "amount_cents"
            case discountPercentage = "discount_percentage"
            case periodCount = "period_count"
        }
    }
    
    public struct UpdateProductPhase: Codable {
        var ordinal: Int?
        var pricingType: FrameObjects.PhasePricingType?
        var name: String?
        var amountCents: Int?
        var discountPercentage: Float?
        var periodCount: Int?
        
        enum CodingKeys: String, CodingKey {
            case ordinal, name
            case pricingType = "pricing_type"
            case amountCents = "amount_cents"
            case discountPercentage = "discount_percentage"
            case periodCount = "period_count"
        }
    }
    
    public struct BulkUpdateProductPhase: Codable {
        let phases: [FrameObjects.SubscriptionPhase]
    }
}
