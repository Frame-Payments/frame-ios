//
//  PaymentMethodResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import Foundation
import EvervaultEnclaves

public class PaymentMethodResponses {
    struct ListPaymentMethodsResponse: Decodable {
        let meta: FrameMetadata?
        let data: [FrameObjects.PaymentMethod]?
    }
    
    public struct EvervaultProviderResponse: Decodable {
        public let data: [PCRs]
        public init(data: [PCRs]) {
            self.data = data
        }
    }
}
