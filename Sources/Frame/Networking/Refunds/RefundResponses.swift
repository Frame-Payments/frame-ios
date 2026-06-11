//
//  RefundResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

/// Response model namespace for Refunds API calls.
public class RefundResponses {
    /// Paginated response returned when listing refunds.
    public struct ListRefundsResponse: Codable {
        /// Pagination and request metadata for the response.
        public let meta: FrameMetadata?
        /// The array of refund objects returned by the API.
        public let data: [FrameObjects.Refund]?
    }
}
