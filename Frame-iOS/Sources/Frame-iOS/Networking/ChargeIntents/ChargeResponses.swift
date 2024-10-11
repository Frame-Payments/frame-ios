//
//  ChargeResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/11/24.
//

import Foundation

class ChargeResponses {
    struct ListChargeIntentsResponse: Decodable {
        let meta: FrameMetadata?
        let data: [FrameObjects.ChargeIntent]?
    }
}
