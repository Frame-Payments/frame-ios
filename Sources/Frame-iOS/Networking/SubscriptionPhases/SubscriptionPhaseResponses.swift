//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

public class SubscriptionPhasesResponses {
    public struct ListSubscriptionPhasesResponse: Codable {
        public let meta: SubscriptionPhaseMeta?
        public let phases: [FrameObjects.SubscriptionPhase]?
    }
    
    public struct SubscriptionPhaseMeta: Codable {
        public let subscriptionId: String?
        
        public enum CodingKeys: String, CodingKey {
            case subscriptionId = "subscription_id"
        }
    }
}
