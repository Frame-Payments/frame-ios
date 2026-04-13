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
        let account: String? // Use instead of customer
        let billing: FrameObjects.BillingAddress?
        
        public init(type: FrameObjects.PaymentRequestType = .ach, accountType: FrameObjects.PaymentAccountType, accountNumber: String, routingNumber: String, customer: String?, account: String?, billing: FrameObjects.BillingAddress?) {
            self.type = type
            self.accountType = accountType
            self.accountNumber = accountNumber
            self.routingNumber = routingNumber
            self.customer = customer
            self.account = account
            self.billing = billing
        }
        
        public enum CodingKeys: String, CodingKey {
            case type, customer, billing, account
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
        let account: String? // Use instead of customer
        let billing: FrameObjects.BillingAddress?
        
        public init(type: FrameObjects.PaymentRequestType = .card, cardNumber: String, expMonth: String, expYear: String, cvc: String, customer: String?, account: String?, billing: FrameObjects.BillingAddress?) {
            self.type = type
            self.cardNumber = cardNumber
            self.expMonth = expMonth
            self.expYear = expYear
            self.cvc = cvc
            self.customer = customer
            self.account = account
            self.billing = billing
        }
        
        public enum CodingKeys: String, CodingKey {
            case type, cvc, customer, billing, account
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

    public struct ConnectPlaidBankAccountRequest: Encodable, Sendable {
        let account: String
        let publicToken: String
        let accountId: String
        let institutionName: String?
        let subtype: String?

        public init(account: String, publicToken: String, accountId: String, institutionName: String? = nil, subtype: String? = nil) {
            self.account = account
            self.publicToken = publicToken
            self.accountId = accountId
            self.institutionName = institutionName
            self.subtype = subtype
        }

        public enum CodingKeys: String, CodingKey {
            case account
            case publicToken = "public_token"
            case accountId = "account_id"
            case institutionName = "institution_name"
            case subtype
        }
    }
}
