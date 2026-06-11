//
//  CapabilityRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

/// Request body namespace for Capabilities API calls.
public class CapabilityRequest {

    /// Request body for requesting one or more merchant capabilities.
    public struct RequestCapabilitiesRequest: Codable {
        /// The list of capabilities being requested for the merchant.
        public let capabilities: [FrameObjects.Capabilities]

        /// Creates a new capability request body.
        /// - Parameter capabilities: The list of capabilities to request.
        public init(capabilities: [FrameObjects.Capabilities]) {
            self.capabilities = capabilities
        }
    }
}
