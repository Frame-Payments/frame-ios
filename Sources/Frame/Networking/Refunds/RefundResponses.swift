//
//  RefundResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

public class RefundResponses {
    public struct ListRefundsResponse: Codable {
        public let meta: FrameMetadata?
        public let data: [FrameObjects.Refund]?
    }
}
