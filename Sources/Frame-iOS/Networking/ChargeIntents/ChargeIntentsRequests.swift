//
//  ChargeRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/11/24.
//

import Foundation

public class ChargeIntentsRequests {
    public struct CreateChargeIntentRequest: Encodable {
        let amount: Int
        let currency: String
        let customer: String?
        let description: String?
        let paymentMethod: String?
        let confirm: Bool
        let receiptEmail: String?
        let authorizationMode: FrameObjects.AuthorizationMode?
        let customerData: CustomerData?
        let paymentMethodData: PaymentMethodData?
        let useFrameSDK: Bool = true
        var fraudSignals: FraudSignals?
        
        public init(amount: Int, currency: String, customer: String? = nil, description: String? = nil, paymentMethod: String? = nil, confirm: Bool, receiptEmail: String? = nil, authorizationMode: FrameObjects.AuthorizationMode? = nil, customerData: CustomerData? = nil, paymentMethodData: PaymentMethodData? = nil, fraudSignals: FraudSignals? = nil) {
            self.amount = amount
            self.currency = currency
            self.customer = customer
            self.description = description
            self.paymentMethod = paymentMethod
            self.confirm = confirm
            self.receiptEmail = receiptEmail
            self.authorizationMode = authorizationMode
            self.customerData = customerData
            self.paymentMethodData = paymentMethodData
            self.fraudSignals = fraudSignals
        }
        
        public enum CodingKeys: String, CodingKey {
            case amount, currency, customer, description, confirm
            case paymentMethod = "payment_method"
            case receiptEmail = "receipt_email"
            case authorizationMode = "authorization_mode"
            case customerData = "customer_data"
            case paymentMethodData = "payment_method_data"
            case useFrameSDK = "use_frame_sdk"
            case fraudSignals = "fraud_signals"
        }
    }
    
    public struct UpdateChargeIntentRequest: Encodable {
        let amount: Int?
        let currency: String?
        let customer: String?
        let description: String?
        let paymentMethod: String?
        let confirm: Bool?
        let receiptEmail: String?
        
        public init(amount: Int? = nil, currency: String? = nil, customer: String? = nil, description: String? = nil, paymentMethod: String? = nil, confirm: Bool? = nil, receiptEmail: String? = nil) {
            self.amount = amount
            self.currency = currency
            self.customer = customer
            self.description = description
            self.paymentMethod = paymentMethod
            self.confirm = confirm
            self.receiptEmail = receiptEmail
        }
        
        public enum CodingKeys: String, CodingKey {
            case amount, currency, customer, description, confirm
            case paymentMethod = "payment_method"
            case receiptEmail = "receipt_email"
        }
    }
    
    public struct CaptureChargeIntentRequest: Encodable {
        let amountCapturedCents: Int
        
        public init(amountCapturedCents: Int) {
            self.amountCapturedCents = amountCapturedCents
        }
        
        enum CodingKeys: String, CodingKey {
            case amountCapturedCents = "amount_captured_cents"
        }
    }
    
    public struct CustomerData: Encodable {
        let name: String
        let email: String
        
        public init(name: String, email: String) {
            self.name = name
            self.email = email
        }
    }
    
    public enum PaymentMethodType: String, Encodable {
        case card
    }
    
    public struct PaymentMethodData: Encodable {
        let attach: Bool?
        let type: PaymentMethodType
        let cardNumber: String
        let expMonth: String
        let expYear: String
        let cvc: String
        let billing: FrameObjects.BillingAddress?
        
        public init(attach: Bool?, type: PaymentMethodType, cardNumber: String, expMonth: String, expYear: String, cvc: String, billing: FrameObjects.BillingAddress?) {
            self.attach = attach
            self.type = type
            self.cardNumber = cardNumber
            self.expMonth = expMonth
            self.expYear = expYear
            self.cvc = cvc
            self.billing = billing
        }
        
        public enum CodingKeys: String, CodingKey {
            case attach, type, cvc, billing
            case cardNumber = "card_number"
            case expMonth = "exp_month"
            case expYear = "exp_year"
        }
    }
    
    public struct FraudSignals: Encodable {
        let clientIp: String?
        
        public init(clientIp: String?) {
            self.clientIp = clientIp
        }
        
        public enum CodingKeys: String, CodingKey {
            case clientIp = "client_ip"
        }
    }
}
