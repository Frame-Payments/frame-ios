//
//  ChargeResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/11/24.
//

import Foundation

/// Response model namespace for Charge Intents API calls.
public class ChargeIntentResponses {
    /// Paginated response returned when listing charge intents.
    public struct ListChargeIntentsResponse: Codable {
        /// Pagination metadata for the response.
        public let meta: FrameMetadata?
        /// The array of charge intent objects returned by the API.
        public let data: [FrameObjects.ChargeIntent]?
    }
}
