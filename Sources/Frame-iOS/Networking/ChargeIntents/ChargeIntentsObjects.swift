//
//  ChargeObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/11/24.
//

import Foundation

extension FrameObjects {
    public enum AuthorizationMode: String, Codable, Sendable {
        case automatic
        case manual
    }
    
    public enum ChargeIntentStatus: String, Codable, Sendable {
        case canceled
        case disputed
        case failed
        case incomplete
        case pending
        case refunded
        case reversed
        case succeeded
    }
    
    public struct ChargeIntent: Codable, Sendable, Identifiable, Equatable {
        public let id: String
        public let currency: String
        public let latestCharge: LatestCharge?
        public let customer: FrameObjects.Customer?
        public let paymentMethod: FrameObjects.PaymentMethod?
        public let shipping: FrameObjects.BillingAddress?
        public let status: FrameObjects.ChargeIntentStatus
        public let description: String?
        public let authorizationMode: FrameObjects.AuthorizationMode
        public let failureDescription: String?
        public let object: String
        public let amount: Int
        public let created: Int
        public let updated: Int
        public let livemode: Bool
        
        public init(id: String, currency: String, latestCharge: FrameObjects.LatestCharge? = nil, customer: FrameObjects.Customer? = nil, paymentMethod: FrameObjects.PaymentMethod? = nil, shipping: FrameObjects.BillingAddress, status: FrameObjects.ChargeIntentStatus, description: String? = nil, authorizationMode: FrameObjects.AuthorizationMode, failureDescription: String? = nil, object: String, amount: Int, created: Int, updated: Int, livemode: Bool) {
            self.id = id
            self.currency = currency
            self.latestCharge = latestCharge
            self.customer = customer
            self.paymentMethod = paymentMethod
            self.shipping = shipping
            self.status = status
            self.description = description
            self.authorizationMode = authorizationMode
            self.failureDescription = failureDescription
            self.object = object
            self.amount = amount
            self.created = created
            self.updated = updated
            self.livemode = livemode
        }
        
        public enum CodingKeys: String, CodingKey {
            case id, currency, customer, shipping, status, description, object, amount, created, livemode, updated
            case latestCharge = "latest_charge"
            case paymentMethod = "payment_method"
            case authorizationMode = "authorization_mode"
            case failureDescription = "failure_description"
        }
    }
    
    public struct LatestCharge: Codable, Sendable, Equatable {
        public let id: String
        public let currency: String
        public let amountCaptured: Int
        public let amountRefunded: Int
        public let created: Int
        public let updated: Int
        public let livemode: Bool
        public let captured: Bool
        public let disputed: Bool
        public let chargeIntent: String
        public let refunded: Bool
        public let failureMessage: String?
        public  let description: String?
        public let status: FrameObjects.ChargeIntentStatus?
        public  let paymentMethodDetails: FrameObjects.PaymentMethod?
        public let customer: String?
        public let paymentMethod: String?
        public let amount: Int
        
        public enum CodingKeys: String, CodingKey {
            case id, currency, created, updated, livemode, captured, disputed, refunded, description, status, customer, amount
            case amountCaptured = "amount_captured"
            case amountRefunded = "amount_refunded"
            case chargeIntent = "charge_intent"
            case failureMessage = "failure_message"
            case paymentMethodDetails = "payment_method_details"
            case paymentMethod = "payment_method"
            
        }
    }
}
