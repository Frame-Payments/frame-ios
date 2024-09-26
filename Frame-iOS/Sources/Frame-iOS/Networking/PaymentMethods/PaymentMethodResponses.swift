//
//  PaymentMethodResponses.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 9/26/24.
//

class PaymentMethodResponses {
    struct ListPaymentMethodsResponse: Decodable {
        let meta: FrameMetadata?
        let data: [FramePaymentObjects.PaymentMethod]?
    }
}
