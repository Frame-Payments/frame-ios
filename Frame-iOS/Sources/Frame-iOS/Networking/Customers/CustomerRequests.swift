//
//  CustomerRequest.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

public class CustomerRequest {
    public struct CreateCustomerRequest: Codable {
        var billingAddress: FrameObjects.BillingAddress?
        var shippingAddress: FrameObjects.BillingAddress?
        let name: String
        var phone: String?
        let email: String
        var description: String?
        var metadata: [String: String]?
        
        public init(billingAddress: FrameObjects.BillingAddress? = nil, shippingAddress: FrameObjects.BillingAddress? = nil, name: String, phone: String? = nil, email: String, description: String? = nil, metadata: [String : String]? = nil) {
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
    
    public struct UpdateCustomerRequest: Codable {
        var billingAddress: FrameObjects.BillingAddress?
        var shippingAddress: FrameObjects.BillingAddress?
        var name: String?
        var phone: String?
        var email: String?
        var description: String?
        var metadata: [String: String]?
        
        public init(billingAddress: FrameObjects.BillingAddress? = nil, shippingAddress: FrameObjects.BillingAddress? = nil, name: String? = nil, phone: String? = nil, email: String? = nil, description: String? = nil, metadata: [String : String]? = nil) {
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
    
    public struct SearchCustomersRequest: Codable {
        var name: String?
        var phone: String?
        var email: String?
        var createdBefore: Int?
        var createdAfter: Int?
        
        public init(name: String? = nil, phone: String? = nil, email: String? = nil, createdBefore: Int? = nil, createdAfter: Int? = nil) {
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
