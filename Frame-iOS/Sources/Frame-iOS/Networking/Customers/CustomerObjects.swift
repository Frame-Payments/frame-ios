//
//  CustomerObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

extension FrameObjects {
    public struct Customer: Codable, Sendable {
        let id: String
        let created: Int?
        var shippingAddress: BillingAddress?
        let updated: Int?
        let livemode: Bool
        let name: String
        var phone: String?
        let email: String?
        var description: String?
        let object: String?
        let metadata: [String: String]?
        var billingAddress: BillingAddress?
        
        public init(id: String, created: Int? = nil, shippingAddress: BillingAddress? = nil, updated: Int? = nil, livemode: Bool, name: String, phone: String? = nil, email: String? = nil, description: String? = nil, object: String? = nil, metadata: [String : String]? = nil, billingAddress: BillingAddress? = nil) {
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
            self.metadata = metadata
            self.billingAddress = billingAddress
        }
        
        public enum CodingKeys: String, CodingKey {
            case id, created, updated, livemode, name, phone, email, description, object, metadata
            case billingAddress = "billing_address"
            case shippingAddress = "shipping_address"
        }
    }
}
