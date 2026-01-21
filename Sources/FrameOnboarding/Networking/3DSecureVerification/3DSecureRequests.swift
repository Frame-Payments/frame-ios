//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/2/26.
//

import Foundation

class ThreeDSecureRequests {
    struct CreateThreeDSecureVerification: Encodable, Sendable {
        let paymentMethodId: String
        
        init(paymentMethodId: String) {
            self.paymentMethodId = paymentMethodId
        }
        
        enum CodingKeys: String, CodingKey {
            case paymentMethodId = "payment_method_id"
        }
    }
}
