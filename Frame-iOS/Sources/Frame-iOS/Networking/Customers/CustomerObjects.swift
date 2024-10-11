//
//  CustomerObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

extension FrameObjects {
    public class Customer: Codable {
        let id: String
        let created: Int?
        let shippingAddress: BillingAddress?
        let updated: Int?
        let livemode: Bool
        let name: String
        let phone: String?
        let email: String?
        let description: String?
        let object: String?
        let metadata: [String: String]?
        let billingAddress: BillingAddress?
        
        public init(id: String, created: Int?, shippingAddress: BillingAddress?, updated: Int?, livemode: Bool, name: String, phone: String?, email: String?, description: String?, object: String?, metadata: [String : String]?, billingAddress: BillingAddress?) {
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
