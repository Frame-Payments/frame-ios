//
//  TransferResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 5/11/26.
//

import Foundation

/// Response model namespace for Transfers API calls.
public class TransferResponses {
    /// Paginated response returned when listing transfers.
    public struct ListTransfersResponse: Codable {
        /// Pagination metadata for the response.
        public let meta: FrameMetadata?
        /// The array of transfer objects returned by the API.
        public let data: [FrameObjects.Transfer]?
    }
}
