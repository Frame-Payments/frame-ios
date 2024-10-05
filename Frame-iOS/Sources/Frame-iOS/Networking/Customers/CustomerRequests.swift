//
//  CustomerRequest.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

public class CustomerRequest {
    public struct CreateCustomerRequest: Encodable {
        let billingAddress: FrameObjects.BillingAddress?
        let shippingAddress: FrameObjects.BillingAddress?
        let name: String
        let phone: String?
        let email: String
        let description: String?
        let metadata: [String: String]?
        
        public init(billingAddress: FrameObjects.BillingAddress?, shippingAddress: FrameObjects.BillingAddress?, name: String, phone: String?, email: String, description: String?, metadata: [String : String]?) {
            self.billingAddress = billingAddress
            self.shippingAddress = shippingAddress
            self.name = name
            self.phone = phone
            self.email = email
            self.description = description
            self.metadata = metadata
        }
        
        enum CodingKeys: String, CodingKey {
            case name, phone, email, description, metadata
            case billingAddress = "billing_address"
            case shippingAddress = "shipping_address"
        }
    }
    
    public struct UpdateCustomerRequest: Encodable {
        let billingAddress: FrameObjects.BillingAddress?
        let shippingAddress: FrameObjects.BillingAddress?
        let name: String?
        let phone: String?
        let email: String?
        let description: String?
        let metadata: [String: String]?
        
        public init(billingAddress: FrameObjects.BillingAddress?, shippingAddress: FrameObjects.BillingAddress?, name: String?, phone: String?, email: String?, description: String?, metadata: [String : String]?) {
            self.billingAddress = billingAddress
            self.shippingAddress = shippingAddress
            self.name = name
            self.phone = phone
            self.email = email
            self.description = description
            self.metadata = metadata
        }
        
        enum CodingKeys: String, CodingKey {
            case name, phone, email, description, metadata
            case billingAddress = "billing_address"
            case shippingAddress = "shipping_address"
        }
    }
    
    public struct SearchCustomersRequest: Encodable {
        let name: String?
        let phone: String?
        let email: String?
        let createdBefore: Int?
        let createdAfter: Int?
        
        public init(name: String?, phone: String?, email: String?, createdBefore: Int?, createdAfter: Int?) {
            self.name = name
            self.phone = phone
            self.email = email
            self.createdBefore = createdBefore
            self.createdAfter = createdAfter
        }
        
        enum CodingKeys: String, CodingKey {
            case name, phone, email
            case createdBefore = "created_before"
            case createdAfter = "created_after"
        }
    }
}
