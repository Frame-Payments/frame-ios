//
//  TransferV2Requests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/29/26.
//

import Foundation

/// Request body namespace for Transfers V2 API calls (`/v2/transfers`).
public enum TransferV2Requests {
    /// Nested `{ value, currency }` money amount for V2 create/update/confirm/capture/refund.
    public struct MoneyAmount: Codable, Sendable, Equatable {
        /// Amount in the smallest currency unit (e.g. cents for USD).
        public let value: Int
        /// ISO 4217 currency code (e.g. `"usd"`).
        public let currency: String?

        /// Creates a money amount.
        public init(value: Int, currency: String? = "usd") {
            self.value = value
            self.currency = currency
        }
    }

    /// Address fields for nested payment-method billing or shipping.
    public struct Address: Codable, Sendable, Equatable {
        public let line1: String?
        public let line2: String?
        public let city: String?
        public let state: String?
        public let postalCode: String?
        public let country: String?

        public init(line1: String? = nil,
                    line2: String? = nil,
                    city: String? = nil,
                    state: String? = nil,
                    postalCode: String? = nil,
                    country: String? = nil) {
            self.line1 = line1
            self.line2 = line2
            self.city = city
            self.state = state
            self.postalCode = postalCode
            self.country = country
        }

        enum CodingKeys: String, CodingKey {
            case city, state, country
            case line1 = "line_1"
            case line2 = "line_2"
            case postalCode = "postal_code"
        }
    }

    /// Nested payment method create payload under `source` / `destination`.
    public struct NestedPaymentMethod: Codable, Sendable, Equatable {
        public let accountId: String?
        public let type: String?
        public let cardNumber: String?
        public let expMonth: Int?
        public let expYear: Int?
        public let cvc: String?
        public let accountNumber: String?
        public let routingNumber: String?
        public let accountType: String?
        public let cashTag: String?
        public let email: String?
        public let phoneNumber: String?
        public let handle: String?
        public let billing: Address?

        public init(accountId: String? = nil,
                    type: String? = nil,
                    cardNumber: String? = nil,
                    expMonth: Int? = nil,
                    expYear: Int? = nil,
                    cvc: String? = nil,
                    accountNumber: String? = nil,
                    routingNumber: String? = nil,
                    accountType: String? = nil,
                    cashTag: String? = nil,
                    email: String? = nil,
                    phoneNumber: String? = nil,
                    handle: String? = nil,
                    billing: Address? = nil) {
            self.accountId = accountId
            self.type = type
            self.cardNumber = cardNumber
            self.expMonth = expMonth
            self.expYear = expYear
            self.cvc = cvc
            self.accountNumber = accountNumber
            self.routingNumber = routingNumber
            self.accountType = accountType
            self.cashTag = cashTag
            self.email = email
            self.phoneNumber = phoneNumber
            self.handle = handle
            self.billing = billing
        }

        enum CodingKeys: String, CodingKey {
            case type, email, handle, billing
            case accountId = "account_id"
            case cardNumber = "card_number"
            case expMonth = "exp_month"
            case expYear = "exp_year"
            case cvc
            case accountNumber = "account_number"
            case routingNumber = "routing_number"
            case accountType = "account_type"
            case cashTag = "cash_tag"
            case phoneNumber = "phone_number"
        }
    }

    /// A `source` or `destination` slot on create/update/confirm.
    public struct EndpointSlot: Codable, Sendable, Equatable {
        public let accountId: String?
        public let paymentMethodId: String?
        public let walletId: String?
        public let rail: String?
        public let speed: String?
        public let paymentMethod: NestedPaymentMethod?

        public init(accountId: String? = nil,
                    paymentMethodId: String? = nil,
                    walletId: String? = nil,
                    rail: String? = nil,
                    speed: String? = nil,
                    paymentMethod: NestedPaymentMethod? = nil) {
            self.accountId = accountId
            self.paymentMethodId = paymentMethodId
            self.walletId = walletId
            self.rail = rail
            self.speed = speed
            self.paymentMethod = paymentMethod
        }

        enum CodingKeys: String, CodingKey {
            case rail, speed
            case accountId = "account_id"
            case paymentMethodId = "payment_method_id"
            case walletId = "wallet_id"
            case paymentMethod = "payment_method"
        }
    }

    /// Shipping fields on create/update.
    public struct Shipping: Codable, Sendable, Equatable {
        public let line1: String?
        public let line2: String?
        public let city: String?
        public let state: String?
        public let postalCode: String?
        public let country: String?
        public let name: String?
        public let phone: String?
        public let carrier: String?
        public let trackingNumber: String?

        public init(line1: String? = nil,
                    line2: String? = nil,
                    city: String? = nil,
                    state: String? = nil,
                    postalCode: String? = nil,
                    country: String? = nil,
                    name: String? = nil,
                    phone: String? = nil,
                    carrier: String? = nil,
                    trackingNumber: String? = nil) {
            self.line1 = line1
            self.line2 = line2
            self.city = city
            self.state = state
            self.postalCode = postalCode
            self.country = country
            self.name = name
            self.phone = phone
            self.carrier = carrier
            self.trackingNumber = trackingNumber
        }

        enum CodingKeys: String, CodingKey {
            case city, state, country, name, phone, carrier
            case line1 = "line_1"
            case line2 = "line_2"
            case postalCode = "postal_code"
            case trackingNumber = "tracking_number"
        }
    }

    /// External 3DS cryptogram payload under `payment_method_options.card.external_3ds`.
    public struct External3DS: Codable, Sendable, Equatable {
        public let version: String?
        public let transactionId: String?
        public let cryptogram: String?
        public let electronicCommerceIndicator: String?
        public let aresTransStatus: String?

        public init(version: String? = nil,
                    transactionId: String? = nil,
                    cryptogram: String? = nil,
                    electronicCommerceIndicator: String? = nil,
                    aresTransStatus: String? = nil) {
            self.version = version
            self.transactionId = transactionId
            self.cryptogram = cryptogram
            self.electronicCommerceIndicator = electronicCommerceIndicator
            self.aresTransStatus = aresTransStatus
        }

        enum CodingKeys: String, CodingKey {
            case version, cryptogram
            case transactionId = "transaction_id"
            case electronicCommerceIndicator = "electronic_commerce_indicator"
            case aresTransStatus = "ares_trans_status"
        }
    }

    /// Card options nested under `payment_method_options`.
    public struct CardPaymentMethodOptions: Codable, Sendable, Equatable {
        public let external3ds: External3DS?

        public init(external3ds: External3DS? = nil) {
            self.external3ds = external3ds
        }

        enum CodingKeys: String, CodingKey {
            case external3ds = "external_3ds"
        }
    }

    /// Payment method options on create/confirm.
    public struct PaymentMethodOptions: Codable, Sendable, Equatable {
        public let card: CardPaymentMethodOptions?

        public init(card: CardPaymentMethodOptions? = nil) {
            self.card = card
        }
    }

    /// Body for `POST /v2/transfers` and shared fields for update/confirm.
    public struct CreateTransferRequest: Codable, Sendable {
        public let amount: MoneyAmount
        public let source: EndpointSlot?
        public let destination: EndpointSlot?
        public let confirm: Bool?
        public let authorizationMode: String?
        public let receiptEmail: String?
        public let statementDescriptor: String?
        public let productId: String?
        public let paymentLinkId: String?
        public let subscriptionId: String?
        public let invoiceId: String?
        public let description: String?
        public let reference: String?
        public let shipping: Shipping?
        public let paymentMethodOptions: PaymentMethodOptions?
        public let cartData: [String: String]?
        public let metadata: [String: String]?
        /// Populated by ``TransfersV2API`` on payment creates.
        var sonarSessionId: String?

        /// Creates a V2 transfer request.
        ///
        /// - Parameters:
        ///   - amount: Nested money amount (`value` + `currency`).
        ///   - source: Source endpoint slot (payment method / account / wallet).
        ///   - destination: Destination endpoint slot when required.
        ///   - confirm: Pass `false` for deferred confirm (client 3DS). Defaults to API behaviour when `nil`.
        ///   - authorizationMode: `"automatic"` or `"manual"` for card payments.
        public init(amount: MoneyAmount,
                    source: EndpointSlot? = nil,
                    destination: EndpointSlot? = nil,
                    confirm: Bool? = nil,
                    authorizationMode: String? = nil,
                    receiptEmail: String? = nil,
                    statementDescriptor: String? = nil,
                    productId: String? = nil,
                    paymentLinkId: String? = nil,
                    subscriptionId: String? = nil,
                    invoiceId: String? = nil,
                    description: String? = nil,
                    reference: String? = nil,
                    shipping: Shipping? = nil,
                    paymentMethodOptions: PaymentMethodOptions? = nil,
                    cartData: [String: String]? = nil,
                    metadata: [String: String]? = nil) {
            self.amount = amount
            self.source = source
            self.destination = destination
            self.confirm = confirm
            self.authorizationMode = authorizationMode
            self.receiptEmail = receiptEmail
            self.statementDescriptor = statementDescriptor
            self.productId = productId
            self.paymentLinkId = paymentLinkId
            self.subscriptionId = subscriptionId
            self.invoiceId = invoiceId
            self.description = description
            self.reference = reference
            self.shipping = shipping
            self.paymentMethodOptions = paymentMethodOptions
            self.cartData = cartData
            self.metadata = metadata
        }

        enum CodingKeys: String, CodingKey {
            case amount, source, destination, confirm, description, reference, shipping, metadata
            case authorizationMode = "authorization_mode"
            case receiptEmail = "receipt_email"
            case statementDescriptor = "statement_descriptor"
            case productId = "product_id"
            case paymentLinkId = "payment_link_id"
            case subscriptionId = "subscription_id"
            case invoiceId = "invoice_id"
            case paymentMethodOptions = "payment_method_options"
            case cartData = "cart_data"
            case sonarSessionId = "sonar_session_id"
        }
    }

    /// Partial update body for `PATCH /v2/transfers/:id` (pre-confirm payment fields).
    public typealias UpdateTransferRequest = CreateTransferRequest

    /// Optional amount for capture or refund.
    public struct AmountOnlyRequest: Codable, Sendable {
        public let amount: MoneyAmount?

        public init(amount: MoneyAmount? = nil) {
            self.amount = amount
        }
    }

}
