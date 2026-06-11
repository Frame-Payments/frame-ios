//
//  CapabilityResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

/// Response model namespace for Capabilities API calls.
public class CapabilityResponses {
    /// Response returned when listing the capabilities available to the merchant.
    public struct ListCapabilitiesResponse: Codable {
        /// The array of capability objects returned by the API, or `nil` if none are present.
        public let data: [FrameObjects.Capability]?
    }
}
