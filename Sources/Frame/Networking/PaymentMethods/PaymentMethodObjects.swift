//
//  PaymentObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import Foundation

/// Namespace for shared payment-method model types used throughout the Frame SDK.
public class FrameObjects {

    /// The lifecycle status of a payment method stored in Frame.
    public enum PaymentMethodStatus: String, Codable, Sendable {
        /// The payment method is active and can be used for transactions.
        case active
        /// The payment method has been blocked and cannot be used for transactions.
        case blocked
    }

    /// The funding instrument type associated with a payment request.
    public enum PaymentRequestType: String, Codable, Sendable {
        /// A credit or debit card payment method.
        case card
        /// An ACH bank-transfer payment method.
        case ach
    }

    /// The type of bank account used for ACH payments.
    public enum PaymentAccountType: String, Codable, Sendable, CaseIterable {
        /// A checking (demand deposit) bank account.
        case checking
        /// A savings bank account.
        case savings
    }

    /// A payment method resource representing a card or bank account saved in Frame.
    public struct PaymentMethod: Codable, Sendable, Identifiable, Equatable {
        /// Unique identifier for the payment method.
        public let id: String
        /// The identifier of the customer this payment method belongs to, if any.
        public var customerId: String?
        /// Billing address associated with the payment method.
        public var billing: BillingAddress?
        /// The funding instrument type (card or ACH) of this payment method.
        public let type: PaymentRequestType
        /// The object type string returned by the Frame API (e.g. `"payment_method"`).
        public let object: String
        /// Unix timestamp (seconds) when the payment method was created.
        public let created: Int
        /// Unix timestamp (seconds) when the payment method was last updated.
        public let updated: Int
        /// Whether the payment method was created in live mode (`true`) or test mode (`false`).
        public let livemode: Bool
        /// Card details, present when `type` is `.card`.
        public var card: PaymentCard?
        /// Bank account details, present when `type` is `.ach`.
        public var ach: BankAccount?
        /// Current lifecycle status of the payment method.
        public let status: PaymentMethodStatus

        /// Creates a ``PaymentMethod`` with all fields.
        ///
        /// - Parameters:
        ///   - id: Unique identifier for the payment method.
        ///   - customerId: The owning customer's identifier, if any.
        ///   - billing: Billing address associated with the payment method.
        ///   - type: The funding instrument type (`.card` or `.ach`).
        ///   - object: The API object type string.
        ///   - created: Unix timestamp of creation.
        ///   - updated: Unix timestamp of last update.
        ///   - livemode: `true` if created in live mode.
        ///   - card: Card details (required when `type` is `.card`).
        ///   - ach: Bank account details (required when `type` is `.ach`).
        ///   - status: Current lifecycle status.
        public init(id: String, customerId: String? = nil, billing: BillingAddress? = nil, type: PaymentRequestType, object: String, created: Int, updated: Int, livemode: Bool, card: PaymentCard? = nil, ach: BankAccount? = nil, status: PaymentMethodStatus) {
            self.id = id
            self.customerId = customerId
            self.billing = billing
            self.type = type
            self.object = object
            self.created = created
            self.updated = updated
            self.livemode = livemode
            self.card = card
            self.ach = ach
            self.status = status
        }

        enum CodingKeys: String, CodingKey {
            case id, billing, type, object, created, updated, livemode, card , ach, status
            case customerId = "customer_id"
        }
    }

    /// A postal billing address associated with a payment method.
    public struct BillingAddress: Codable, Sendable, Equatable {
        /// City portion of the billing address.
        public var city: String?
        /// ISO 3166-1 alpha-2 country code (e.g. `"US"`).
        public var country: String?
        /// State or province of the billing address.
        public var state: String?
        /// Postal or ZIP code of the billing address.
        public var postalCode: String
        /// Primary street address line.
        public var addressLine1: String?
        /// Secondary street address line (suite, apartment, etc.).
        public var addressLine2: String?

        /// Creates a ``BillingAddress``.
        ///
        /// - Parameters:
        ///   - city: City portion of the address.
        ///   - country: ISO 3166-1 alpha-2 country code.
        ///   - state: State or province.
        ///   - postalCode: Postal or ZIP code.
        ///   - addressLine1: Primary street address line.
        ///   - addressLine2: Secondary street address line.
        public init(city: String? = nil, country: String? = nil, state: String? = nil, postalCode: String, addressLine1: String? = nil, addressLine2: String? = nil) {
            self.city = city
            self.country = country
            self.state = state
            self.postalCode = postalCode
            self.addressLine1 = addressLine1
            self.addressLine2 = addressLine2
        }

        public enum CodingKeys: String, CodingKey {
            case city, country, state
            case postalCode = "postal_code"
            case addressLine1 = "line_1"
            case addressLine2 = "line_2"
        }
    }

    /// Details about a credit or debit card attached to a payment method.
    public struct PaymentCard: Codable, Sendable, Equatable {
        /// Card network brand (e.g. `"visa"`, `"mastercard"`).
        public let brand: String
        /// Two-digit expiration month string (e.g. `"01"`).
        public let expirationMonth: String?
        /// Four-digit expiration year string (e.g. `"2027"`).
        public let expirationYear: String?
        /// Name of the card-issuing bank or institution.
        public let issuer: String?
        /// ISO 4217 currency code associated with the card.
        public let currency: String?
        /// Market segment classification for the card (e.g. `"consumer"`, `"commercial"`).
        public let segment: String?
        /// Funding type of the card (e.g. `"credit"`, `"debit"`, `"prepaid"`).
        public let type: String?
        /// The last four digits of the card number.
        public let lastFourDigits: String
        /// Digital wallet information, if the card is tokenised in a wallet.
        public let wallet: Wallet?

        /// Creates a ``PaymentCard``.
        ///
        /// - Parameters:
        ///   - brand: Card network brand string.
        ///   - expirationMonth: Two-digit expiration month.
        ///   - expirationYear: Four-digit expiration year.
        ///   - issuer: Card-issuing institution name.
        ///   - currency: ISO 4217 currency code.
        ///   - segment: Market segment classification.
        ///   - type: Funding type of the card.
        ///   - lastFourDigits: Last four digits of the card number.
        ///   - wallet: Digital wallet information, if applicable.
        public init(brand: String, expirationMonth: String? = nil, expirationYear: String? = nil, issuer: String? = nil, currency: String?, segment: String? = nil,
                    type: String? = nil, lastFourDigits: String, wallet: Wallet? = nil) {
            self.brand = brand
            self.expirationMonth = expirationMonth
            self.expirationYear = expirationYear
            self.issuer = issuer
            self.currency = currency
            self.segment = segment
            self.type = type
            self.lastFourDigits = lastFourDigits
            self.wallet = wallet
        }

        public enum CodingKeys: String, CodingKey {
            case brand, issuer, currency, segment, type, wallet
            case expirationMonth = "exp_month"
            case expirationYear = "exp_year"
            case lastFourDigits = "last_four"
        }
    }

    /// Digital wallet information associated with a tokenised card.
    public struct Wallet: Codable, Sendable, Equatable {
        /// The type of digital wallet (e.g. Apple Pay or Google Pay).
        public let type: WalletType
        /// A dynamic last-four-digit string provided by the wallet network, if available.
        public let dynamicLast4: String?

        /// Creates a ``Wallet``.
        ///
        /// - Parameters:
        ///   - type: The wallet type.
        ///   - dynamicLast4: Dynamic last four digits provided by the wallet network.
        public init(type: WalletType, dynamicLast4: String? = nil) {
            self.type = type
            self.dynamicLast4 = dynamicLast4
        }

        public enum CodingKeys: String, CodingKey {
            case type
            case dynamicLast4 = "dynamic_last4"
        }
    }

    /// Identifies the digital wallet network that tokenised a card.
    public enum WalletType: String, Codable, Sendable, Equatable {
        /// Apple Pay wallet.
        case applePay = "apple_pay"
        /// Google Pay wallet.
        case googlePay = "google_pay"
    }

    /// Details about a bank account used for ACH payments.
    public struct BankAccount: Codable, Sendable, Equatable {
        /// Whether the account is a checking or savings account.
        public var accountType: FrameObjects.PaymentAccountType?
        /// Full bank account number (present only when explicitly returned by the API).
        public var accountNumber: String?
        /// ABA routing number for the bank.
        public var routingNumber: String?
        /// Name of the bank or financial institution.
        public var bankName: String?
        /// Last four digits of the bank account number.
        public var lastFour: String?

        /// Creates a ``BankAccount``.
        ///
        /// - Parameters:
        ///   - accountType: Checking or savings account type.
        ///   - accountNumber: Full account number, if available.
        ///   - routingNumber: ABA routing number.
        ///   - bankName: Name of the bank or financial institution.
        ///   - lastFour: Last four digits of the account number.
        public init(accountType: FrameObjects.PaymentAccountType? = nil, accountNumber: String? = nil, routingNumber: String? = nil, bankName: String? = nil, lastFour: String? = nil) {
            self.accountType = accountType
            self.accountNumber = accountNumber
            self.routingNumber = routingNumber
            self.bankName = bankName
            self.lastFour = lastFour
        }

        public enum CodingKeys: String, CodingKey {
            case accountType = "account_type"
            case accountNumber = "account_number"
            case routingNumber = "routing_number"
            case bankName = "bank_name"
            case lastFour = "last_four"
        }
    }
}
