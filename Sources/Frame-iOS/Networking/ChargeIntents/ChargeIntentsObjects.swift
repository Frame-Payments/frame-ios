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
    
    public struct ChargeIntent: Codable, Sendable {
        let id: String
        let currency: String
        let latestCharge: LatestCharge?
        let customer: FrameObjects.Customer?
        let paymentMethod: FrameObjects.PaymentMethod?
        let shipping: FrameObjects.BillingAddress?
        let status: FrameObjects.ChargeIntentStatus
        let description: String?
        let authorizationMode: FrameObjects.AuthorizationMode
        let failureDescription: String?
        let object: String
        let amount: Int
        let created: Int
        let updated: Int?
        let livemode: Bool
        
        public init(id: String, currency: String, latestCharge: FrameObjects.LatestCharge? = nil, customer: FrameObjects.Customer? = nil, paymentMethod: FrameObjects.PaymentMethod? = nil, shipping: FrameObjects.BillingAddress, status: FrameObjects.ChargeIntentStatus, description: String? = nil, authorizationMode: FrameObjects.AuthorizationMode, failureDescription: String? = nil, object: String, amount: Int, created: Int,updated: Int? = nil, livemode: Bool) {
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
    
    public struct LatestCharge: Codable, Sendable {
        let id: String
        let currency: String
        let amountCaptured: Int
        let amountRefunded: Int
        let created: Int
        let updated: Int
        let livemode: Bool
        let captured: Bool
        let disputed: Bool
        let chargeIntent: String
        let refunded: Bool
        let failureMessage: String?
        let description: String?
        let status: FrameObjects.ChargeIntentStatus?
        let paymentMethodDetails: FrameObjects.PaymentMethod?
        let customer: String?
        let paymentMethod: String?
        let amount: Int
        
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
