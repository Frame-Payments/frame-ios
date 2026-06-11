//
//  SubscriptionResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/27/24.
//

/// Response model namespace for Subscriptions API calls.
public class SubscriptionResponses {
    /// Decoded response returned when listing subscriptions.
    public struct ListSubscriptionsResponse: Codable {
        /// Pagination and request metadata associated with the response.
        public let meta: FrameMetadata?
        /// The array of subscription objects returned by the API.
        public let data: [FrameObjects.Subscription]?
    }
}
