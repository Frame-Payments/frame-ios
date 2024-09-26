//
//  PaymentMethodRequest.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 9/26/24.
//

class PaymentMethodRequest {
    struct CreatePaymentMethodRequest: Encodable {
        let type: String
        let cardNumber: String
        let expMonth: String
        let expYear: String
        let cvc: String
        let customer: String?
        let billing: FramePaymentObjects.PaymentBilling?
        
        init(type: String, cardNumber: String, expMonth: String, expYear: String, cvc: String, customer: String?, billing: FramePaymentObjects.PaymentBilling?) {
            self.type = type
            self.cardNumber = cardNumber
            self.expMonth = expMonth
            self.expYear = expYear
            self.cvc = cvc
            self.customer = customer
            self.billing = billing
        }
        
        enum CodingKeys: String, CodingKey {
            case type, cvc, customer, billing
            case cardNumber = "card_number"
            case expMonth = "exp_month"
            case expYear = "exp_year"
        }
    }
    
    struct UpdatePaymentMethodRequest: Encodable {
        let expMonth: String?
        let expYear: String?
        let billing: FramePaymentObjects.PaymentBilling?
        
        enum CodingKeys: String, CodingKey {
            case billing
            case expMonth = "exp_month"
            case expYear = "exp_year"
        }
    }
    
    struct GetPaymentMethodsRequest: Encodable {
        let perPage: Int = 50
        let page: Int?
        
        enum CodingKeys: String, CodingKey {
            case page
            case perPage = "per_page"
        }
    }
    
    struct AttachPaymentMethodRequest: Encodable {
        let customer: String
    }
}
