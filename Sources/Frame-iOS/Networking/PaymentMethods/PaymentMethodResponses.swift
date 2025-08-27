//
//  PaymentMethodResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

public class PaymentMethodResponses {
    public struct ListPaymentMethodsResponse: Codable {
        public let meta: FrameMetadata?
        public let data: [FrameObjects.PaymentMethod]?
    }
}
