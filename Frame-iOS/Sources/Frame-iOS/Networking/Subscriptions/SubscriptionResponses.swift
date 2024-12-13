//
//  SubscriptionResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/27/24.
//

class SubscriptionResponses {
    struct ListSubscriptionsResponse: Codable {
        let meta: FrameMetadata?
        let data: [FrameObjects.Subscription]?
    }
}
