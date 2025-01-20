//
//  ChargeResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/11/24.
//

import Foundation

class ChargeIntentResponses {
    struct ListChargeIntentsResponse: Codable {
        let meta: FrameMetadata?
        let data: [FrameObjects.ChargeIntent]?
    }
}
