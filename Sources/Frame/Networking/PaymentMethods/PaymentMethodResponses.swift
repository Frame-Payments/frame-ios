//
//  PaymentMethodResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

/// Response model namespace for Payment Methods API calls.
public class PaymentMethodResponses {
    /// Decoded response returned by the list payment methods endpoint.
    public struct ListPaymentMethodsResponse: Codable {
        /// Pagination and request metadata accompanying the response.
        public let meta: FrameMetadata?
        /// The array of payment methods returned by the API.
        public let data: [FrameObjects.PaymentMethod]?
    }
}
