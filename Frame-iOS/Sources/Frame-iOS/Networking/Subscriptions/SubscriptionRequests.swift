//
//  SubscriptionRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/27/24.
//

public class SubscriptionRequest {
    public struct CreateSubscriptionRequest: Codable {
        let customer: String
        let product: String
        let currency: String
        let defaultPaymentMethod: String
        let description: String?
        
        public init(customer: String, product: String, currency: String, defaultPaymentMethod: String, description: String? = nil) {
            self.customer = customer
            self.product = product
            self.currency = currency
            self.defaultPaymentMethod = defaultPaymentMethod
            self.description = description
        }
        
        enum CodingKeys: String, CodingKey {
            case customer
            case product
            case currency
            case defaultPaymentMethod = "default_payment_method"
            case description
        }
    }
    
    public struct UpdateSubscriptionRequest: Codable {
        let description: String?
        let defaultPaymentMethod: String?
        
        public init(description: String? = nil, defaultPaymentMethod: String? = nil) {
            self.description = description
            self.defaultPaymentMethod = defaultPaymentMethod
        }
        
        enum CodingKeys: String, CodingKey {
            case description
            case defaultPaymentMethod = "default_payment_method"
        }
    }
    
    public struct SearchSubscriptionRequest: Codable {
        let status: String?
        let createdBefore: Int?
        let createdAfter: Int?
        
        public init(status: String? = nil, createdBefore: Int? = nil, createdAfter: Int? = nil) {
            self.status = status
            self.createdBefore = createdBefore
            self.createdAfter = createdAfter
        }
        
        enum CodingKeys: String, CodingKey {
            case status
            case createdBefore = "created_before"
            case createdAfter = "created_after"
        }
    }
}
