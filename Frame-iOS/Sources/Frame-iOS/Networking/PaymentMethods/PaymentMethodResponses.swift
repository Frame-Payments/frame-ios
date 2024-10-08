//
//  PaymentMethodResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

class PaymentMethodResponses {
    struct ListPaymentMethodsResponse: Decodable {
        let meta: FrameMetadata?
        let data: [FrameObjects.PaymentMethod]?
    }
}
