//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

extension FrameObjects {
    public enum PhasePricingType: String, Codable {
        case staticPricing = "static"
        case relative
    }
    
    public enum PhaseDurationType: String, Codable {
        case finite
        case infinite
    }
    
    public struct SubscriptionPhase: Codable {
        let id: String
        let ordinal: Int?
        let name: String?
        let pricingType: PhasePricingType?
        let durationType: PhaseDurationType?
        let amount: Int?
        let currency: String?
        let discountPercentage: Float?
        let periodCount: Int?
        let interval: String?
        let intervalCount: Int?
        let livemode: Bool?
        let created: Int?
        let updated: Int?
        let object: String?
        
        public init(id: String, ordinal: Int?, name: String?, pricingType: PhasePricingType?, durationType: PhaseDurationType?, amount: Int?, currency: String?, discountPercentage: Float?, periodCount: Int?, interval: String?, intervalCount: Int?, livemode: Bool?, created: Int?, updated: Int?, object: String?) {
            self.id = id
            self.ordinal = ordinal
            self.name = name
            self.pricingType = pricingType
            self.durationType = durationType
            self.amount = amount
            self.currency = currency
            self.discountPercentage = discountPercentage
            self.periodCount = periodCount
            self.interval = interval
            self.intervalCount = intervalCount
            self.livemode = livemode
            self.created = created
            self.updated = updated
            self.object = object
        }
    }
}
