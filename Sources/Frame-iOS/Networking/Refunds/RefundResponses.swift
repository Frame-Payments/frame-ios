//
//  RefundResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/17/24.
//

import Foundation

public class RefundResponses {
    struct ListRefundsResponse: Codable {
        let meta: FrameMetadata?
        let data: [FrameObjects.Refund]?
    }
}
