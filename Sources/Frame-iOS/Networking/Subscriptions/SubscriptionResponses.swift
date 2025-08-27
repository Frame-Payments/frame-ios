//
//  SubscriptionResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/27/24.
//

public class SubscriptionResponses {
    public struct ListSubscriptionsResponse: Codable {
        public let meta: FrameMetadata?
        public let data: [FrameObjects.Subscription]?
    }
}
