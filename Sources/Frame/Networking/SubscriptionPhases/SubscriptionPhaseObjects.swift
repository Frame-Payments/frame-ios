//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

extension FrameObjects {
    /// Describes how the price of a subscription phase is determined.
    public enum PhasePricingType: String, Codable, Sendable {
        /// The phase has a fixed, predetermined price.
        case staticType = "static"
        /// The phase price is calculated relative to another value.
        case relative
    }

    /// Describes how long a subscription phase lasts.
    public enum PhaseDurationType: String, Codable, Sendable {
        /// The phase runs for a bounded number of billing periods.
        case finite
        /// The phase continues indefinitely until cancelled.
        case infinite
    }

    /// Represents a single phase within a subscription or product, defining its pricing, duration, and billing interval.
    public struct SubscriptionPhase: Codable, Sendable, Identifiable, Equatable {
        /// Unique identifier for the phase.
        public var id: String
        /// The zero-based position of this phase in the overall phase sequence.
        public var ordinal: Int?
        /// Human-readable name for the phase.
        public var name: String?
        /// How the phase price is determined (static or relative).
        public var pricingType: PhasePricingType?
        /// Whether the phase is finite or runs indefinitely.
        public var durationType: PhaseDurationType?
        /// Billing amount for the phase in the smallest currency unit (e.g., cents).
        public var amount: Int?
        /// ISO 4217 currency code for the phase amount.
        public var currency: String?
        /// Optional discount applied to the phase price, expressed as a percentage.
        public var discountPercentage: Float?
        /// Number of billing periods this phase lasts (relevant when `durationType` is `.finite`).
        public var periodCount: Int?
        /// Billing interval unit (e.g., `"month"`, `"year"`).
        public var interval: String?
        /// Number of interval units between each billing cycle.
        public var intervalCount: Int?
        /// Whether the phase is active in live mode; `false` indicates test mode.
        public var livemode: Bool?
        /// Unix timestamp (seconds) when the phase was created.
        public var created: Int?
        /// Unix timestamp (seconds) when the phase was last updated.
        public var updated: Int?
        /// API object type identifier returned by the server.
        public var object: String?

        /// Creates a new `SubscriptionPhase` with all available fields.
        /// - Parameters:
        ///   - id: Unique identifier for the phase.
        ///   - ordinal: Zero-based position of this phase in the sequence.
        ///   - name: Human-readable name for the phase.
        ///   - pricingType: How the phase price is determined.
        ///   - durationType: Whether the phase is finite or indefinite.
        ///   - amount: Billing amount in the smallest currency unit.
        ///   - currency: ISO 4217 currency code.
        ///   - discountPercentage: Discount applied to the phase price as a percentage.
        ///   - periodCount: Number of billing periods the phase lasts.
        ///   - interval: Billing interval unit string.
        ///   - intervalCount: Number of interval units per billing cycle.
        ///   - livemode: Whether the phase belongs to a live-mode resource.
        ///   - created: Unix timestamp of when the phase was created.
        ///   - updated: Unix timestamp of when the phase was last updated.
        ///   - object: API object type identifier.
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

        /// Maps Swift property names to their snake_case JSON keys.
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
