//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

public class SubscriptionPhaseRequests {
    public struct CreateSubscriptionPhase: Codable {
        let ordinal: Int
        let pricingType: FrameObjects.PhasePricingType
        let durationType: FrameObjects.PhaseDurationType
        var name: String?
        var amountCents: Int?
        var discountPercentage: Float?
        var periodCount: Int?
        var interval: String?
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
    
    public struct UpdateSubscriptionPhase: Codable {
        var ordinal: Int?
        var pricingType: FrameObjects.PhasePricingType?
        var durationType: FrameObjects.PhaseDurationType?
        var name: String?
        var amountCents: Int?
        var discountPercentage: Float?
        var periodCount: Int?
        var interval: String?
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
    
    public struct BulkUpdateScriptionPhase: Codable {
        let phases: [FrameObjects.SubscriptionPhase]
    }
}
