//
//  PaymentMethodRequest.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

public class PaymentMethodRequest {
    
    public struct CreateACHPaymentMethodRequest: Encodable, Sendable {
        let type: FrameObjects.PaymentRequestType
        var accountType: FrameObjects.PaymentAccountType // Required for ACH
        var accountNumber: String // Required for ACH
        var routingNumber: String // Required for ACH
        let customer: String?
        let billing: FrameObjects.BillingAddress?
        
        public init(type: FrameObjects.PaymentRequestType = .ach, accountType: FrameObjects.PaymentAccountType, accountNumber: String, routingNumber: String, customer: String?, billing: FrameObjects.BillingAddress?) {
            self.type = type
            self.accountType = accountType
            self.accountNumber = accountNumber
            self.routingNumber = routingNumber
            self.customer = customer
            self.billing = billing
        }
        
        public enum CodingKeys: String, CodingKey {
            case type, customer, billing
            case accountType = "account_type"
            case accountNumber = "account_number"
            case routingNumber = "routing_number"
        }
    }
    
    public struct CreateCardPaymentMethodRequest: Encodable, Sendable {
        let type: FrameObjects.PaymentRequestType
        var cardNumber: String // Required for Card
        var expMonth: String // Required for Card
        var expYear: String // Required for Card
        var cvc: String // Required for Card
        let customer: String?
        let billing: FrameObjects.BillingAddress?
        
        public init(type: FrameObjects.PaymentRequestType = .card, cardNumber: String, expMonth: String, expYear: String, cvc: String, customer: String?, billing: FrameObjects.BillingAddress?) {
            self.type = type
            self.cardNumber = cardNumber
            self.expMonth = expMonth
            self.expYear = expYear
            self.cvc = cvc
            self.customer = customer
            self.billing = billing
        }
        
        public enum CodingKeys: String, CodingKey {
            case type, cvc, customer, billing
            case cardNumber = "card_number"
            case expMonth = "exp_month"
            case expYear = "exp_year"
        }
    }
    
    public struct UpdatePaymentMethodRequest: Encodable {
        let expMonth: String? // Only used for type: `card` payment methods
        let expYear: String? // Only used for type: `card` payment methods
        let billing: FrameObjects.BillingAddress?
        
        public init(expMonth: String? = nil, expYear: String? = nil, billing: FrameObjects.BillingAddress? = nil) {
            self.expMonth = expMonth
            self.expYear = expYear
            self.billing = billing
        }
        
        public enum CodingKeys: String, CodingKey {
            case billing
            case expMonth = "exp_month"
            case expYear = "exp_year"
        }
    }
    
    public struct AttachPaymentMethodRequest: Encodable {
        let customer: String
        
        public init(customer: String) {
            self.customer = customer
        }
    }
}
