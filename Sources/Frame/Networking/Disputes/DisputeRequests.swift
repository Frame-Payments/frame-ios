//
//  DisputeRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/5/25.
//

import Foundation

/// Request body namespace for Disputes API calls.
public class DisputeRequests {
    /// Request body for updating an existing dispute.
    public struct UpdateDisputeRequest: Codable, Sendable {
        /// The evidence to attach to the dispute.
        public let evidence: FrameObjects.DisputeEvidence
        /// Whether to submit the dispute for review immediately after updating.
        public let submit: Bool
    }
}
