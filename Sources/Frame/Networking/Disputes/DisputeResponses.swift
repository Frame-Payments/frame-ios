//
//  DisputeResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/5/25.
//

import Foundation

/// Response model namespace for Disputes API calls.
public class DisputeResponses {
    /// The response returned when listing disputes.
    public struct ListDisputesResponse: Codable {
        /// The array of disputes returned by the API.
        public let data: [FrameObjects.Dispute]?
    }
}

