//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

public class SubscriptionPhaseRequests {
    public struct CreateSubscriptionPhase: Codable {
        let ordinal: Int
        let pricingType: PhasePricingType
        let durationType: PhaseDurationType
        let name: String?
        let amountCents: Int?
        let discountPercentage: Float?
        let periodCount: Int?
        let interval: String?
        let intervalCount: Int?
    }
    
    public struct UpdateSubscriptionPhase: Codable {
        let ordinal: Int?
        let pricingType: PhasePricingType?
        let durationType: PhaseDurationType?
        let name: String?
        let amountCents: Int?
        let discountPercentage: Float?
        let periodCount: Int?
        let interval: String?
        let intervalCount: Int?
    }
    
    public struct BulkUpdateScriptionPhase: Codable {
        let phases: [FrameObjects.SubscriptionPhase]
    }
    
    public enum PhasePricingType: String, Codable {
        case staticType = "static"
        case relative
    }
    
    public enum PhaseDurationType: String, Codable {
        case finite
        case infinite
    }
}
