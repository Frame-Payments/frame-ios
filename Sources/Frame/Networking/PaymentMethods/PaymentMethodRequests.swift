//
//  PaymentMethodRequest.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

/// Request body namespace for Payment Method API calls.
public class PaymentMethodRequest {

    /// Request body for creating an ACH (bank account) payment method.
    public struct CreateACHPaymentMethodRequest: Encodable, Sendable {
        /// The payment method type; always `.ach` for this request.
        let type: FrameObjects.PaymentRequestType
        /// The bank account type (e.g. checking or savings). Required for ACH.
        var accountType: FrameObjects.PaymentAccountType
        /// The bank account number. Required for ACH.
        var accountNumber: String
        /// The bank routing number. Required for ACH.
        var routingNumber: String
        /// The identifier of the customer to associate with this payment method.
        let customer: String?
        /// The account identifier to associate with this payment method; use instead of `customer`.
        let account: String?
        /// Optional billing address to attach to this payment method.
        let billing: FrameObjects.BillingAddress?

        /// Creates a new ACH payment method request.
        ///
        /// - Parameters:
        ///   - type: The payment method type. Defaults to `.ach`.
        ///   - accountType: The bank account type (checking or savings).
        ///   - accountNumber: The bank account number.
        ///   - routingNumber: The bank routing number.
        ///   - customer: The customer identifier to associate with this payment method.
        ///   - account: The account identifier to use instead of `customer`.
        ///   - billing: An optional billing address.
        public init(type: FrameObjects.PaymentRequestType = .ach, accountType: FrameObjects.PaymentAccountType, accountNumber: String, routingNumber: String, customer: String?, account: String?, billing: FrameObjects.BillingAddress?) {
            self.type = type
            self.accountType = accountType
            self.accountNumber = accountNumber
            self.routingNumber = routingNumber
            self.customer = customer
            self.account = account
            self.billing = billing
        }

        /// Coding keys mapping Swift property names to their JSON API equivalents.
        public enum CodingKeys: String, CodingKey {
            case type, customer, billing, account
            case accountType = "account_type"
            case accountNumber = "account_number"
            case routingNumber = "routing_number"
        }
    }

    /// Request body for creating a card payment method.
    public struct CreateCardPaymentMethodRequest: Encodable, Sendable {
        /// The payment method type; always `.card` for this request.
        let type: FrameObjects.PaymentRequestType
        /// The card number. Required for card payment methods.
        var cardNumber: String
        /// The card expiration month (e.g. `"01"`). Required for card payment methods.
        var expMonth: String
        /// The card expiration year (e.g. `"2027"`). Required for card payment methods.
        var expYear: String
        /// The card security code. Required for card payment methods.
        var cvc: String
        /// The identifier of the customer to associate with this payment method.
        let customer: String?
        /// The account identifier to associate with this payment method; use instead of `customer`.
        let account: String?
        /// Optional billing address to attach to this payment method.
        let billing: FrameObjects.BillingAddress?

        /// Creates a new card payment method request.
        ///
        /// - Parameters:
        ///   - type: The payment method type. Defaults to `.card`.
        ///   - cardNumber: The card number.
        ///   - expMonth: The card expiration month.
        ///   - expYear: The card expiration year.
        ///   - cvc: The card security code.
        ///   - customer: The customer identifier to associate with this payment method.
        ///   - account: The account identifier to use instead of `customer`.
        ///   - billing: An optional billing address.
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

        /// Coding keys mapping Swift property names to their JSON API equivalents.
        public enum CodingKeys: String, CodingKey {
            case type, cvc, customer, billing, account
            case cardNumber = "card_number"
            case expMonth = "exp_month"
            case expYear = "exp_year"
        }
    }

    /// Request body for updating an existing payment method.
    public struct UpdatePaymentMethodRequest: Encodable {
        /// Updated card expiration month. Only applicable to `card` payment methods.
        let expMonth: String?
        /// Updated card expiration year. Only applicable to `card` payment methods.
        let expYear: String?
        /// Updated billing address to associate with the payment method.
        let billing: FrameObjects.BillingAddress?

        /// Creates a new update payment method request.
        ///
        /// - Parameters:
        ///   - expMonth: The new expiration month for a card payment method.
        ///   - expYear: The new expiration year for a card payment method.
        ///   - billing: An updated billing address.
        public init(expMonth: String? = nil, expYear: String? = nil, billing: FrameObjects.BillingAddress? = nil) {
            self.expMonth = expMonth
            self.expYear = expYear
            self.billing = billing
        }

        /// Coding keys mapping Swift property names to their JSON API equivalents.
        public enum CodingKeys: String, CodingKey {
            case billing
            case expMonth = "exp_month"
            case expYear = "exp_year"
        }
    }

    /// Request body for attaching an existing payment method to a customer.
    public struct AttachPaymentMethodRequest: Encodable {
        /// The identifier of the customer to attach the payment method to.
        let customer: String

        /// Creates a new attach payment method request.
        ///
        /// - Parameter customer: The customer identifier.
        public init(customer: String) {
            self.customer = customer
        }
    }

    /// Request body for connecting a Plaid-linked bank account as a payment method.
    public struct ConnectPlaidBankAccountRequest: Encodable, Sendable {
        /// The Frame account identifier to associate with the bank account.
        let account: String
        /// The short-lived public token returned by the Plaid Link flow.
        let publicToken: String
        /// The Plaid account ID selected by the user during the Link flow.
        let accountId: String
        /// The human-readable name of the financial institution.
        let institutionName: String?
        /// The Plaid account subtype (e.g. `"checking"` or `"savings"`).
        let subtype: String?

        /// Creates a new Plaid bank account connection request.
        ///
        /// - Parameters:
        ///   - account: The Frame account identifier.
        ///   - publicToken: The public token from the Plaid Link flow.
        ///   - accountId: The Plaid account ID selected by the user.
        ///   - institutionName: The name of the financial institution.
        ///   - subtype: The Plaid account subtype.
        public init(account: String, publicToken: String, accountId: String, institutionName: String? = nil, subtype: String? = nil) {
            self.account = account
            self.publicToken = publicToken
            self.accountId = accountId
            self.institutionName = institutionName
            self.subtype = subtype
        }

        /// Coding keys mapping Swift property names to their JSON API equivalents.
        public enum CodingKeys: String, CodingKey {
            case account
            case publicToken = "public_token"
            case accountId = "account_id"
            case institutionName = "institution_name"
            case subtype
        }
    }
}
