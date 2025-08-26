//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

extension FrameObjects {
    public enum PhasePricingType: String, Codable {
        case staticType = "static"
        case relative
    }
    
    public enum PhaseDurationType: String, Codable {
        case finite
        case infinite
    }
    
    public struct SubscriptionPhase: Codable {
        var id: String
        var ordinal: Int?
        var name: String?
        var pricingType: PhasePricingType?
        var durationType: PhaseDurationType?
        var amount: Int?
        var currency: String?
        var discountPercentage: Float?
        var periodCount: Int?
        var interval: String?
        var intervalCount: Int?
        var livemode: Bool?
        var created: Int?
        var updated: Int?
        var object: String?
        
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
