//
//  CapabilityRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

public class CapabilityRequest {
    
    public struct RequestCapabilitiesRequest: Codable {
        public let capabilities: [FrameObjects.Capabilities]
        
        public init(capabilities: [FrameObjects.Capabilities]) {
            self.capabilities = capabilities
        }
    }
}
