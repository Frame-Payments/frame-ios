//
//  CapabilityResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

public class CapabilityResponses {
    public struct ListCapabilitiesResponse: Codable {
        public let data: [FrameObjects.Capability]?
    }
}
