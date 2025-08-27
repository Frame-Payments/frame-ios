//
//  ChargeResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/11/24.
//

import Foundation

public class ChargeIntentResponses {
    public struct ListChargeIntentsResponse: Codable {
        public let meta: FrameMetadata?
        public let data: [FrameObjects.ChargeIntent]?
    }
}
