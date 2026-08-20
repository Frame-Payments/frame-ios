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
        @Lenient public private(set) var meta: FrameMetadata?
        /// The array of transfer objects returned by the API.
        @Lenient public private(set) var data: [FrameObjects.Transfer]?
    }
}
