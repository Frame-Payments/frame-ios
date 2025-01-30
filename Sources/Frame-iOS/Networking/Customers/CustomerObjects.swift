//
//  CustomerObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

extension FrameObjects {
    public struct Customer: Codable, Sendable, Identifiable, Equatable {
        public let id: String
        public let created: Int?
        public var shippingAddress: BillingAddress?
        public let updated: Int?
        public let livemode: Bool
        public let name: String
        public var phone: String?
        public let email: String?
        public var description: String?
        public let object: String?
        public var billingAddress: BillingAddress?
        public var paymentMethods: [PaymentMethod]?
        
        public init(id: String, created: Int? = nil, shippingAddress: BillingAddress? = nil, updated: Int? = nil, livemode: Bool, name: String, phone: String? = nil, email: String? = nil, description: String? = nil, object: String? = nil, metadata: [String : String]? = nil, billingAddress: BillingAddress? = nil, paymentMethods: [PaymentMethod]? = nil) {
            self.id = id
            self.created = created
            self.shippingAddress = shippingAddress
            self.updated = updated
            self.livemode = livemode
            self.name = name
            self.phone = phone
            self.email = email
            self.description = description
            self.object = object
            self.billingAddress = billingAddress
            self.paymentMethods = paymentMethods
        }
//        
        public enum CodingKeys: String, CodingKey {
            case id, created, updated, livemode, name, phone, email, description, object
            case billingAddress = "billing_address"
            case shippingAddress = "shipping_address"
            case paymentMethods = "payment_methods"
        }
    }
}
