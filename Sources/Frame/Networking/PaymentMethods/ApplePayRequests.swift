//
//  ApplePayRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/2/25.
//

import Foundation

/// Request body namespace for Apple Pay payment-method API calls.
///
/// All encodable structs needed to tokenise an Apple Pay payment and create a
/// Frame payment method are nested here to keep the public namespace tidy.
public class ApplePayRequests {

    // MARK: - Top-level request

    /// Top-level request body sent when creating an Apple Pay payment method.
    ///
    /// Wrap an ``ApplePayWallet`` and optionally associate the resulting payment
    /// method with either a customer or a connected account.
    public struct CreateApplePayPaymentMethodRequest: Encodable {
        /// Payment method type; always `"card"` for Apple Pay.
        let type: String = "card"
        /// Wallet envelope containing the Apple Pay token details.
        let wallet: ApplePayWallet
        /// Frame customer ID to associate with this payment method.
        let customer: String?  // use instead of account
        /// Connected account ID to associate with this payment method.
        let account: String?   // use instead of customer

        /// Creates a new ``CreateApplePayPaymentMethodRequest``.
        ///
        /// - Parameters:
        ///   - wallet: The Apple Pay wallet envelope.
        ///   - customer: Optional Frame customer ID. Mutually exclusive with `account`.
        ///   - account: Optional connected account ID. Mutually exclusive with `customer`.
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

    /// Wallet envelope that identifies the payment method as Apple Pay and
    /// carries its token details.
    public struct ApplePayWallet: Encodable {
        /// Wallet type; always `"apple_pay"`.
        let type: String = "apple_pay"
        /// Apple Pay-specific token and payer details.
        let applePay: ApplePayDetails

        /// Creates a new ``ApplePayWallet``.
        ///
        /// - Parameter applePay: The Apple Pay details to include in the wallet.
        public init(applePay: ApplePayDetails) {
            self.applePay = applePay
        }

        enum CodingKeys: String, CodingKey {
            case type
            case applePay = "apple_pay"
        }
    }

    // MARK: - Apple Pay details

    /// Payer and device information accompanying an Apple Pay token.
    ///
    /// Encapsulates the payment-request identifier, optional payer identity
    /// fields, the encrypted token, and device-attestation data used for
    /// fraud prevention.
    public struct ApplePayDetails: Encodable {
        /// Unique identifier for the originating payment request.
        let requestId: String
        /// Payment method name; always `"https://apple.com/apple-pay"`.
        let methodName: String = "https://apple.com/apple-pay"
        /// Display name of the payer, if provided by the device.
        let payerName: String?
        /// Email address of the payer, if provided by the device.
        let payerEmail: String?
        /// Encrypted Apple Pay token and optional billing contact.
        let details: ApplePayTokenDetails
        /// Key identifier for the device attestation key.
        let deviceKeyId: String?
        /// Base64-encoded device assertion blob for fraud signals.
        let deviceAssertion: String?
        /// Base64-encoded client data associated with the device assertion.
        let deviceClientData: String?

        /// Creates a new ``ApplePayDetails``.
        ///
        /// - Parameters:
        ///   - requestId: Unique identifier for the originating payment request.
        ///   - payerName: Optional display name of the payer.
        ///   - payerEmail: Optional email address of the payer.
        ///   - details: The encrypted Apple Pay token and billing contact.
        ///   - deviceKeyId: Optional device attestation key identifier.
        ///   - deviceAssertion: Optional base64-encoded device assertion.
        ///   - deviceClientData: Optional base64-encoded device client data.
        public init(requestId: String, payerName: String? = nil, payerEmail: String? = nil,
                    details: ApplePayTokenDetails,
                    deviceKeyId: String? = nil, deviceAssertion: String? = nil, deviceClientData: String? = nil) {
            self.requestId = requestId
            self.payerName = payerName
            self.payerEmail = payerEmail
            self.details = details
            self.deviceKeyId = deviceKeyId
            self.deviceAssertion = deviceAssertion
            self.deviceClientData = deviceClientData
        }

        enum CodingKeys: String, CodingKey {
            case requestId = "requestId"
            case methodName = "methodName"
            case payerName = "payerName"
            case payerEmail = "payerEmail"
            case details
            case deviceKeyId = "device_key_id"
            case deviceAssertion = "device_assertion"
            case deviceClientData = "device_client_data"
        }
    }

    /// Container for the Apple Pay token and optional billing contact.
    public struct ApplePayTokenDetails: Encodable {
        /// The encrypted Apple Pay payment token.
        let token: ApplePayToken
        /// Optional billing contact supplied by the Wallet sheet.
        let billingContact: ApplePayBillingContact?

        /// Creates a new ``ApplePayTokenDetails``.
        ///
        /// - Parameters:
        ///   - token: The encrypted Apple Pay payment token.
        ///   - billingContact: Optional billing contact returned by the Wallet sheet.
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

    /// Represents the full Apple Pay payment token returned by PassKit.
    ///
    /// Combines the encrypted payment data, card metadata, and a unique
    /// transaction identifier issued by Apple.
    public struct ApplePayToken: Encodable {
        /// Encrypted payment data containing the card credentials.
        let paymentData: ApplePayPaymentData
        /// Metadata describing the payment card (display name, network, type).
        let paymentMethod: ApplePayPaymentMethod
        /// Unique transaction identifier assigned by Apple.
        let transactionIdentifier: String

        /// Creates a new ``ApplePayToken``.
        ///
        /// - Parameters:
        ///   - paymentData: The encrypted payment data blob.
        ///   - paymentMethod: Card metadata for the selected payment method.
        ///   - transactionIdentifier: Apple-issued unique transaction identifier.
        public init(paymentData: ApplePayPaymentData, paymentMethod: ApplePayPaymentMethod, transactionIdentifier: String) {
            self.paymentData = paymentData
            self.paymentMethod = paymentMethod
            self.transactionIdentifier = transactionIdentifier
        }

        enum CodingKeys: String, CodingKey {
            case paymentData, paymentMethod, transactionIdentifier
        }
    }

    /// Encrypted payment data returned inside an Apple Pay token.
    ///
    /// Contains the ciphertext, version string, signature, and cryptographic
    /// header required to decrypt and verify the card credentials server-side.
    public struct ApplePayPaymentData: Encodable {
        /// Encryption protocol version (e.g. `"EC_v1"`).
        let version: String
        /// Base64-encoded encrypted payment data ciphertext.
        let data: String
        /// Base64-encoded detached CMS signature over the payment data.
        let signature: String
        /// Cryptographic header containing keys and identifiers for decryption.
        let header: ApplePayPaymentDataHeader

        /// Creates a new ``ApplePayPaymentData``.
        ///
        /// - Parameters:
        ///   - version: Encryption protocol version string.
        ///   - data: Base64-encoded encrypted ciphertext.
        ///   - signature: Base64-encoded CMS signature.
        ///   - header: Cryptographic header for decryption.
        public init(version: String, data: String, signature: String, header: ApplePayPaymentDataHeader) {
            self.version = version
            self.data = data
            self.signature = signature
            self.header = header
        }
    }

    /// Cryptographic header fields required to decrypt an Apple Pay payment data blob.
    public struct ApplePayPaymentDataHeader: Encodable {
        /// Base64-encoded ephemeral EC public key used for key agreement.
        let ephemeralPublicKey: String
        /// Base64-encoded SHA-256 hash of the merchant's public key certificate.
        let publicKeyHash: String
        /// Hex-encoded transaction identifier used as additional authenticated data.
        let transactionId: String

        /// Creates a new ``ApplePayPaymentDataHeader``.
        ///
        /// - Parameters:
        ///   - ephemeralPublicKey: Base64-encoded ephemeral EC public key.
        ///   - publicKeyHash: Base64-encoded SHA-256 hash of the merchant certificate.
        ///   - transactionId: Hex-encoded transaction identifier.
        public init(ephemeralPublicKey: String, publicKeyHash: String, transactionId: String) {
            self.ephemeralPublicKey = ephemeralPublicKey
            self.publicKeyHash = publicKeyHash
            self.transactionId = transactionId
        }
    }

    /// Metadata describing the payment card selected in the Apple Pay sheet.
    public struct ApplePayPaymentMethod: Encodable {
        /// Human-readable label for the card (e.g. `"Visa 1234"`).
        let displayName: String
        /// Card network identifier (e.g. `"Visa"`, `"MasterCard"`).
        let network: String
        /// Card type (e.g. `"debit"`, `"credit"`).
        let type: String

        /// Creates a new ``ApplePayPaymentMethod``.
        ///
        /// - Parameters:
        ///   - displayName: Human-readable card label.
        ///   - network: Card network identifier.
        ///   - type: Card type string.
        public init(displayName: String, network: String, type: String) {
            self.displayName = displayName
            self.network = network
            self.type = type
        }
    }

    // MARK: - Billing contact

    /// Optional billing contact returned from the Apple Pay payment sheet.
    ///
    /// All fields are optional; include only those requested from the user in the
    /// `PKPaymentRequest` billing contact fields configuration.
    public struct ApplePayBillingContact: Encodable {
        /// Street address lines (e.g. `["123 Main St", "Apt 4"]`).
        let addressLines: [String]?
        /// City or locality.
        let locality: String?
        /// State, province, or administrative area.
        let administrativeArea: String?
        /// Postal or ZIP code.
        let postalCode: String?
        /// ISO 3166-1 alpha-2 country code (e.g. `"US"`).
        let countryCode: String?

        /// Creates a new ``ApplePayBillingContact``.
        ///
        /// - Parameters:
        ///   - addressLines: Optional street address lines.
        ///   - locality: Optional city or locality.
        ///   - administrativeArea: Optional state or province.
        ///   - postalCode: Optional postal or ZIP code.
        ///   - countryCode: Optional ISO 3166-1 alpha-2 country code.
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
