//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

public class SubscriptionPhasesResponses {
    struct ListSubscriptionPhasesResponse: Codable {
        let meta: SubscriptionPhaseMeta?
        let phases: [FrameObjects.SubscriptionPhase]?
    }
    
    struct SubscriptionPhaseMeta: Codable {
        let subscriptionId: String?
        
        enum CodingKeys: String, CodingKey {
            case subscriptionId = "subscription_id"
        }
    }
}
