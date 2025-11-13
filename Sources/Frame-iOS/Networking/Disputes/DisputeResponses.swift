//
//  DisputeResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/5/25.
//

import Foundation

public class DisputeResponses {
    public struct ListDisputesResponse: Codable {
        public let data: [FrameObjects.Dispute]?
    }
}

