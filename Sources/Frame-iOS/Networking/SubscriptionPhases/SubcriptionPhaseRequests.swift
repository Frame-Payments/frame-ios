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
        let name: String?
        let amountCents: Int?
        let discountPercentage: Float?
        let periodCount: Int?
        let interval: String?
        let intervalCount: Int?
    }
    
    public struct UpdateSubscriptionPhase: Codable {
        let ordinal: Int?
        let pricingType: FrameObjects.PhasePricingType?
        let durationType: FrameObjects.PhaseDurationType?
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
}
