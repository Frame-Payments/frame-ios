//
//  DisputeRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/5/25.
//

import Foundation

public class DisputeRequests {
    public struct UpdateDisputeRequest: Codable, Sendable {
        public let evidence: FrameObjects.DisputeEvidence
        public let submit: Bool
    }
}
