//
//  PaymentMethodRequest.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

public class PaymentMethodRequest {
    public struct CreatePaymentMethodRequest: Encodable, Sendable {
        let type: String
        var cardNumber: String
        var expMonth: String
        var expYear: String
        var cvc: String
        let customer: String?
        let billing: FrameObjects.BillingAddress?
        
        public init(type: String, cardNumber: String, expMonth: String, expYear: String, cvc: String, customer: String?, billing: FrameObjects.BillingAddress?) {
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
        let expMonth: String?
        let expYear: String?
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
