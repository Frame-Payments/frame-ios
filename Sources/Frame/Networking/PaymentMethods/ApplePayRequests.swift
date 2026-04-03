//
//  ApplePayRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/2/25.
//

import Foundation

public class ApplePayRequests {

    // MARK: - Top-level request

    public struct CreateApplePayPaymentMethodRequest: Encodable {
        let type: String = "card"
        let wallet: ApplePayWallet
        let customer: String?  // use instead of account
        let account: String?   // use instead of customer

        public init(wallet: ApplePayWallet, customer: String? = nil, account: String? = nil) {
            self.wallet = wallet
            self.customer = customer
            self.account = account
        }

        enum CodingKeys: String, CodingKey {
            case type, customer, account
            case wallet = "_wallet"
        }
    }

    // MARK: - Wallet envelope

    public struct ApplePayWallet: Encodable {
        let type: String = "apple_pay"
        let applePay: ApplePayDetails

        public init(applePay: ApplePayDetails) {
            self.applePay = applePay
        }

        enum CodingKeys: String, CodingKey {
            case type
            case applePay = "apple_pay"
        }
    }

    // MARK: - Apple Pay details

    public struct ApplePayDetails: Encodable {
        let requestId: String
        let methodName: String = "https://apple.com/apple-pay"
        let payerName: String?
        let payerEmail: String?
        let details: ApplePayTokenDetails

        public init(requestId: String, payerName: String? = nil, payerEmail: String? = nil, details: ApplePayTokenDetails) {
            self.requestId = requestId
            self.payerName = payerName
            self.payerEmail = payerEmail
            self.details = details
        }

        enum CodingKeys: String, CodingKey {
            case requestId = "requestId"
            case methodName = "methodName"
            case payerName = "payerName"
            case payerEmail = "payerEmail"
            case details
        }
    }

    public struct ApplePayTokenDetails: Encodable {
        let token: ApplePayToken
        let billingContact: ApplePayBillingContact?

        public init(token: ApplePayToken, billingContact: ApplePayBillingContact? = nil) {
            self.token = token
            self.billingContact = billingContact
        }

        enum CodingKeys: String, CodingKey {
            case token
            case billingContact = "billingContact"
        }
    }

    // MARK: - Token

    public struct ApplePayToken: Encodable {
        let paymentData: ApplePayPaymentData
        let paymentMethod: ApplePayPaymentMethod
        let transactionIdentifier: String

        public init(paymentData: ApplePayPaymentData, paymentMethod: ApplePayPaymentMethod, transactionIdentifier: String) {
            self.paymentData = paymentData
            self.paymentMethod = paymentMethod
            self.transactionIdentifier = transactionIdentifier
        }

        enum CodingKeys: String, CodingKey {
            case paymentData, paymentMethod, transactionIdentifier
        }
    }

    public struct ApplePayPaymentData: Encodable {
        let version: String
        let data: String
        let signature: String
        let header: ApplePayPaymentDataHeader

        public init(version: String, data: String, signature: String, header: ApplePayPaymentDataHeader) {
            self.version = version
            self.data = data
            self.signature = signature
            self.header = header
        }
    }

    public struct ApplePayPaymentDataHeader: Encodable {
        let ephemeralPublicKey: String
        let publicKeyHash: String
        let transactionId: String

        public init(ephemeralPublicKey: String, publicKeyHash: String, transactionId: String) {
            self.ephemeralPublicKey = ephemeralPublicKey
            self.publicKeyHash = publicKeyHash
            self.transactionId = transactionId
        }
    }

    public struct ApplePayPaymentMethod: Encodable {
        let displayName: String
        let network: String
        let type: String

        public init(displayName: String, network: String, type: String) {
            self.displayName = displayName
            self.network = network
            self.type = type
        }
    }

    // MARK: - Billing contact

    public struct ApplePayBillingContact: Encodable {
        let addressLines: [String]?
        let locality: String?
        let administrativeArea: String?
        let postalCode: String?
        let countryCode: String?

        public init(addressLines: [String]? = nil, locality: String? = nil,
                    administrativeArea: String? = nil, postalCode: String? = nil,
                    countryCode: String? = nil) {
            self.addressLines = addressLines
            self.locality = locality
            self.administrativeArea = administrativeArea
            self.postalCode = postalCode
            self.countryCode = countryCode
        }
    }
}
