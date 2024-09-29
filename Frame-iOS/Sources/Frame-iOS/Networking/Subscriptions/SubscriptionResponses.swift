//
//  SubscriptionResponses.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 9/27/24.
//

class SubscriptionResponses {
    struct ListSubscriptionsResponse: Decodable {
        let meta: FrameMetadata?
        let data: [FrameObjects.Subscription]?
    }
}
