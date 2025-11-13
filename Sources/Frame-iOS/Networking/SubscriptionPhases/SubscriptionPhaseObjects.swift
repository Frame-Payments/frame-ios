//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

extension FrameObjects {
    public enum PhasePricingType: String, Codable, Sendable {
        case staticType = "static"
        case relative
    }
    
    public enum PhaseDurationType: String, Codable, Sendable {
        case finite
        case infinite
    }
    
    public struct SubscriptionPhase: Codable, Sendable, Identifiable, Equatable {
        public var id: String
        public var ordinal: Int?
        public var name: String?
        public var pricingType: PhasePricingType?
        public var durationType: PhaseDurationType?
        public var amount: Int?
        public var currency: String?
        public var discountPercentage: Float?
        public var periodCount: Int?
        public var interval: String?
        public var intervalCount: Int?
        public var livemode: Bool?
        public var created: Int?
        public var updated: Int?
        public var object: String?
        
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
        
        public enum CodingKeys: String, CodingKey {
            case id
            case ordinal
            case name
            case pricingType = "pricing_type"
            case durationType = "duration_type"
            case amount
            case currency
            case discountPercentage = "discount_percentage"
            case periodCount = "period_count"
            case interval
            case intervalCount = "interval_count"
            case livemode
            case created
            case updated
            case object
        }
    }
}
