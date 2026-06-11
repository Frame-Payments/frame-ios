//
//  ChargeRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/11/24.
//

import Foundation

/// Request body namespace for Charge Intents API calls.
///
/// All encodable request structs and supporting types used when creating, updating,
/// or capturing charge intents are nested inside this class.
public class ChargeIntentsRequests {

    /// Request body for creating a new charge intent.
    public struct CreateChargeIntentRequest: Encodable {
        /// The charge amount in the smallest currency unit (e.g. cents).
        let amount: Int
        /// The three-letter ISO 4217 currency code (e.g. `"usd"`).
        let currency: String
        /// The ID of an existing Frame customer to associate with the charge. Mutually exclusive with `account`.
        let customer: String?
        /// The ID of a connected account to charge on behalf of. Use instead of `customer`, not together.
        let account: String? // use instead of customer, not with it.
        /// An optional human-readable description attached to the charge intent.
        let description: String?
        /// The ID of a previously created payment method to use for this charge.
        let paymentMethod: String?
        /// Whether to immediately confirm and capture the charge intent upon creation.
        let confirm: Bool
        /// Email address to which a receipt is sent after a successful charge.
        let receiptEmail: String?
        /// Controls whether the charge is authorized in full or in incremental-authorization mode.
        let authorizationMode: FrameObjects.AuthorizationMode?
        /// Inline customer data to create or look up a customer record during the request.
        let customerData: CustomerData?
        /// Raw payment-method card data supplied directly on the request instead of a saved method ID.
        let paymentMethodData: PaymentMethodData?
        /// Always `true`; signals to the Frame backend that the request originated from the iOS SDK.
        let useFrameSDK: Bool = true
        /// Device and session signals used for fraud detection.
        var fraudSignals: FraudSignals?
        /// Sonar session identifier for additional fraud-scoring context.
        var sonarSessionId: String?

        /// Creates a new charge-intent request.
        ///
        /// - Parameters:
        ///   - amount: Charge amount in the smallest currency unit.
        ///   - currency: Three-letter ISO 4217 currency code.
        ///   - customer: ID of an existing Frame customer. Mutually exclusive with `account`.
        ///   - account: ID of a connected account. Mutually exclusive with `customer`.
        ///   - description: Human-readable description for the charge.
        ///   - paymentMethod: ID of a saved payment method to charge.
        ///   - confirm: Whether to confirm the charge intent immediately.
        ///   - receiptEmail: Email address to receive the payment receipt.
        ///   - authorizationMode: Authorization capture mode for the charge.
        ///   - customerData: Inline customer details to attach to the charge.
        ///   - paymentMethodData: Raw card data to use instead of a saved payment method.
        public init(amount: Int, currency: String, customer: String? = nil, account: String? = nil, description: String? = nil, paymentMethod: String? = nil, confirm: Bool, receiptEmail: String? = nil, authorizationMode: FrameObjects.AuthorizationMode? = nil, customerData: CustomerData? = nil, paymentMethodData: PaymentMethodData? = nil) {
            self.amount = amount
            self.currency = currency
            self.customer = customer
            self.account = account
            self.description = description
            self.paymentMethod = paymentMethod
            self.confirm = confirm
            self.receiptEmail = receiptEmail
            self.authorizationMode = authorizationMode
            self.customerData = customerData
            self.paymentMethodData = paymentMethodData
        }

        /// JSON coding keys mapping Swift property names to the API's snake_case field names.
        public enum CodingKeys: String, CodingKey {
            case amount, currency, customer, description, confirm, account
            case paymentMethod = "payment_method"
            case receiptEmail = "receipt_email"
            case authorizationMode = "authorization_mode"
            case customerData = "customer_data"
            case paymentMethodData = "payment_method_data"
            case useFrameSDK = "use_frame_sdk"
            case fraudSignals = "fraud_signals"
            case sonarSessionId = "sonar_session_id"
        }
    }

    /// Request body for updating a mutable field on an existing charge intent.
    public struct UpdateChargeIntentRequest: Encodable {
        /// Updated charge amount in the smallest currency unit, if changing.
        let amount: Int?
        /// Updated ISO 4217 currency code, if changing.
        let currency: String?
        /// Updated customer ID to associate with the charge, if changing.
        let customer: String?
        /// Updated connected-account ID, if changing.
        let account: String?
        /// Updated human-readable description, if changing.
        let description: String?
        /// Updated payment method ID to use for the charge, if changing.
        let paymentMethod: String?
        /// Whether to confirm the charge intent as part of this update.
        let confirm: Bool?
        /// Updated receipt email address, if changing.
        let receiptEmail: String?

        /// Creates an update request with only the fields that should change.
        ///
        /// All parameters are optional; omitted fields are left unchanged on the server.
        ///
        /// - Parameters:
        ///   - amount: New amount in the smallest currency unit.
        ///   - currency: New three-letter ISO 4217 currency code.
        ///   - customer: New customer ID.
        ///   - account: New connected-account ID.
        ///   - description: New human-readable description.
        ///   - paymentMethod: New saved payment method ID.
        ///   - confirm: Whether to confirm the charge intent.
        ///   - receiptEmail: New receipt email address.
        public init(amount: Int? = nil, currency: String? = nil, customer: String? = nil, account: String? = nil, description: String? = nil, paymentMethod: String? = nil, confirm: Bool? = nil, receiptEmail: String? = nil) {
            self.amount = amount
            self.currency = currency
            self.customer = customer
            self.account = account
            self.description = description
            self.paymentMethod = paymentMethod
            self.confirm = confirm
            self.receiptEmail = receiptEmail
        }

        /// JSON coding keys mapping Swift property names to the API's snake_case field names.
        public enum CodingKeys: String, CodingKey {
            case amount, currency, customer, description, confirm, account
            case paymentMethod = "payment_method"
            case receiptEmail = "receipt_email"
        }
    }

    /// Request body for capturing a previously authorized charge intent.
    public struct CaptureChargeIntentRequest: Encodable {
        /// The amount to capture, in cents. Must be less than or equal to the originally authorized amount.
        let amountCapturedCents: Int

        /// Creates a capture request.
        ///
        /// - Parameter amountCapturedCents: Amount to capture in cents.
        public init(amountCapturedCents: Int) {
            self.amountCapturedCents = amountCapturedCents
        }

        /// JSON coding keys mapping Swift property names to the API's snake_case field names.
        enum CodingKeys: String, CodingKey {
            case amountCapturedCents = "amount_captured_cents"
        }
    }

    /// Inline customer details that can be attached to a charge intent at creation time.
    public struct CustomerData: Encodable {
        /// The customer's full name.
        let name: String
        /// The customer's email address.
        let email: String

        /// Creates a `CustomerData` value.
        ///
        /// - Parameters:
        ///   - name: The customer's full name.
        ///   - email: The customer's email address.
        public init(name: String, email: String) {
            self.name = name
            self.email = email
        }
    }

    /// The type of payment method supplied inline on a charge-intent request.
    public enum PaymentMethodType: String, Encodable {
        /// A standard credit or debit card.
        case card
    }

    /// Raw payment-method card data included directly on a charge-intent request.
    public struct PaymentMethodData: Encodable {
        /// Whether to save (attach) this payment method to the customer after a successful charge.
        let attach: Bool?
        /// The type of payment method (e.g. `.card`).
        let type: PaymentMethodType
        /// The full card number.
        let cardNumber: String
        /// The card's two-digit expiration month (e.g. `"01"`).
        let expMonth: String
        /// The card's two- or four-digit expiration year (e.g. `"26"` or `"2026"`).
        let expYear: String
        /// The card's security code (CVC/CVV).
        let cvc: String
        /// Optional billing address associated with the card.
        let billing: FrameObjects.BillingAddress?

        /// Creates a `PaymentMethodData` value with raw card details.
        ///
        /// - Parameters:
        ///   - attach: Whether to save the card to the customer after charge.
        ///   - type: The payment method type.
        ///   - cardNumber: The full card number.
        ///   - expMonth: Two-digit expiration month.
        ///   - expYear: Two- or four-digit expiration year.
        ///   - cvc: Card security code.
        ///   - billing: Optional billing address for the card.
        public init(attach: Bool?, type: PaymentMethodType, cardNumber: String, expMonth: String, expYear: String, cvc: String, billing: FrameObjects.BillingAddress?) {
            self.attach = attach
            self.type = type
            self.cardNumber = cardNumber
            self.expMonth = expMonth
            self.expYear = expYear
            self.cvc = cvc
            self.billing = billing
        }

        /// JSON coding keys mapping Swift property names to the API's snake_case field names.
        public enum CodingKeys: String, CodingKey {
            case attach, type, cvc, billing
            case cardNumber = "card_number"
            case expMonth = "exp_month"
            case expYear = "exp_year"
        }
    }

    /// Device and session signals forwarded to Frame's fraud-detection pipeline.
    public struct FraudSignals: Encodable {
        /// The client IP address of the end user initiating the payment.
        let clientIp: String?

        /// Creates a `FraudSignals` value.
        ///
        /// - Parameter clientIp: The client's IP address, if available.
        public init(clientIp: String?) {
            self.clientIp = clientIp
        }

        /// JSON coding keys mapping Swift property names to the API's snake_case field names.
        public enum CodingKeys: String, CodingKey {
            case clientIp = "client_ip"
        }
    }
}
