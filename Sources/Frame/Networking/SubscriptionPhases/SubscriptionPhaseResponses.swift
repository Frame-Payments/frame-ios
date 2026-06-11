//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

/// Response model namespace for Subscription Phases API calls.
public class SubscriptionPhasesResponses {
    /// Decoded response returned when listing the phases of a subscription.
    public struct ListSubscriptionPhasesResponse: Codable {
        /// Metadata associated with the list response, including the parent subscription identifier.
        public let meta: SubscriptionPhaseMeta?
        /// The subscription phases returned by the API.
        public let phases: [FrameObjects.SubscriptionPhase]?
    }

    /// Metadata accompanying a subscription-phases list response.
    public struct SubscriptionPhaseMeta: Codable {
        /// The identifier of the subscription these phases belong to.
        public let subscriptionId: String?

        /// Maps Swift property names to their JSON key equivalents.
        public enum CodingKeys: String, CodingKey {
            /// Maps to the `subscription_id` JSON key.
            case subscriptionId = "subscription_id"
        }
    }
}
