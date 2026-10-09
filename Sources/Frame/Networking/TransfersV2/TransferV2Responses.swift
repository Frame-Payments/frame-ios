//
//  TransferV2Responses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/29/26.
//

import Foundation

/// Response model namespace for Transfers V2 API calls.
public enum TransferV2Responses {
    /// Paginated response returned when listing V2 transfers.
    public struct ListTransfersResponse: Codable, Sendable {
        /// Pagination metadata for the response.
        @Lenient public private(set) var meta: FrameMetadata?
        /// The array of V2 transfer objects returned by the API.
        @Lenient public private(set) var data: [FrameObjects.TransferV2]?
    }
}
