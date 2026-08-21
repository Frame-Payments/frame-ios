//
//  TransferObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 5/11/26.
//

import Foundation

extension FrameObjects {
    /// Represents the lifecycle state of a transfer within the Frame platform.
    ///
    /// Mirrors the charge-intent state machine, since a card transfer wraps a charge intent.
    /// An unrecognised value decodes to ``unknown`` rather than failing the ``Transfer``.
    public enum TransferStatus: String, Codable, Sendable {
        /// The transfer has been created but not yet processed.
        case pending
        /// The transfer is incomplete and requires additional action.
        case incomplete
        /// The transfer needs an account or customer before it can proceed.
        case requiresAccountOrCustomer = "requires_account_or_customer"
        /// The transfer needs a payment method before it can proceed.
        case requiresPaymentMethod = "requires_payment_method"
        /// The transfer is waiting to be confirmed.
        case requiresConfirmation = "requires_confirmation"
        /// A 3D Secure challenge is required to authenticate the cardholder.
        case requiresThreeDSecure = "requires_3d_secure"
        /// The transfer is authorized and awaiting a merchant-initiated capture.
        case requiresCapture = "requires_capture"
        /// The transfer is being processed.
        case processing
        /// The transfer was processed successfully.
        case succeeded
        /// The transfer could not be completed.
        case failed
        /// The transfer expired before it could be completed.
        case expired
        /// The transfer was canceled before processing.
        case canceled
        /// The transfer was reversed after completion.
        case reversed
        /// The transfer was refunded.
        case refunded
        /// The transfer has been disputed by the customer.
        case disputed
        /// A dispute on the transfer was resolved in the merchant's favour.
        case disputedWon = "disputed_won"
        /// A dispute on the transfer was resolved in the customer's favour.
        case disputedLost = "disputed_lost"
        /// The transfer is held for manual fraud review.
        case fraudReview = "fraud_review"
        /// The transfer was declined by fraud screening.
        case fraudDeclined = "fraud_declined"
        /// A status this version of the SDK does not recognise.
        case unknown

        /// The transfer has fully settled.
        ///
        /// Not a status the API emits; retained so existing call sites keep compiling.
        @available(*, deprecated, message: "Not an API status. Use `succeeded`.")
        case completed
        /// The transfer was blocked, typically due to compliance or risk rules.
        ///
        /// Not a status the API emits; retained so existing call sites keep compiling.
        @available(*, deprecated, message: "Not an API status. Use `fraudDeclined` or `failed`.")
        case blocked

        /// Creates a status from its API string, mapping anything unrecognised to ``unknown``.
        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = TransferStatus(rawValue: raw) ?? .unknown
        }
    }

    /// A record of a funds movement between a source and destination payment method on the Frame platform.
    public struct Transfer: Codable, Sendable, Identifiable, Equatable {
        /// Unique identifier for the transfer.
        public let id: String

        /// The object type identifier returned by the Frame API, typically `"transfer"`.
        @Lenient public private(set) var object: String?

        /// Current lifecycle status of the transfer.
        @Lenient public private(set) var status: TransferStatus?

        /// Transfer amount in the smallest currency unit (e.g. cents for USD).
        public let amount: Int

        /// ISO 4217 currency code for the transfer (e.g. `"usd"`).
        @Lenient public private(set) var currency: String?

        /// Fee retained by the platform, in the smallest currency unit.
        @Lenient public private(set) var platformFee: Int?

        /// Fee retained by Frame, in the smallest currency unit.
        @Lenient public private(set) var frameFee: Int?

        /// Sum of all fees applied to the transfer, in the smallest currency unit.
        @Lenient public private(set) var totalFees: Int?

        /// Total amount before fees are deducted, in the smallest currency unit.
        @Lenient public private(set) var grossAmount: Int?

        /// Amount received after all fees are deducted, in the smallest currency unit.
        @Lenient public private(set) var netAmount: Int?

        /// Human-readable description of the transfer.
        @Lenient public private(set) var description: String?

        /// Machine-readable reason the transfer failed, if applicable.
        @Lenient public private(set) var failureReason: String?

        /// Identifier of the charge intent that initiated this transfer.
        @Lenient public private(set) var chargeIntent: String?

        /// Identifier of the payout associated with this transfer.
        @Lenient public private(set) var payout: String?

        /// Identifier of the billing agreement linked to this transfer.
        @Lenient public private(set) var billingAgreement: String?

        /// Payment method from which funds were drawn.
        @Lenient public private(set) var sourcePaymentMethod: FrameObjects.PaymentMethod?

        /// Payment method to which funds were sent.
        @Lenient public private(set) var destinationPaymentMethod: FrameObjects.PaymentMethod?

        /// Arbitrary key-value pairs attached to the transfer for application use.
        @Lenient public private(set) var metadata: [String: String]?

        /// Whether this transfer was created in live mode (`true`) or test mode (`false`).
        @Lenient public private(set) var livemode: Bool?

        /// Unix timestamp (seconds since epoch) when the transfer was created.
        @Lenient public private(set) var created: Int?

        /// The wrapped charge intent's `client_secret` (`ci_<id>_secret_…`), when one exists.
        ///
        /// Authorizes confirming this one charge: never log, persist, or send it to analytics.
        @Lenient public private(set) var clientSecret: String?

        /// Creates a new `Transfer` model with the provided field values.
        ///
        /// - Parameters:
        ///   - id: Unique identifier for the transfer.
        ///   - object: Object type string returned by the API.
        ///   - status: Current lifecycle status.
        ///   - amount: Amount in the smallest currency unit.
        ///   - currency: ISO 4217 currency code.
        ///   - platformFee: Fee retained by the platform.
        ///   - frameFee: Fee retained by Frame.
        ///   - totalFees: Combined total of all fees.
        ///   - grossAmount: Amount before fees.
        ///   - netAmount: Amount after fees.
        ///   - description: Human-readable description.
        ///   - failureReason: Reason the transfer failed, if applicable.
        ///   - chargeIntent: Associated charge intent identifier.
        ///   - payout: Associated payout identifier.
        ///   - billingAgreement: Associated billing agreement identifier.
        ///   - sourcePaymentMethod: Payment method funds were drawn from.
        ///   - destinationPaymentMethod: Payment method funds were sent to.
        ///   - metadata: Arbitrary key-value metadata.
        ///   - livemode: `true` if created in live mode.
        ///   - created: Unix timestamp of creation.
        ///   - clientSecret: The wrapped charge intent's `client_secret`.
        public init(id: String,
                    object: String? = nil,
                    status: TransferStatus? = nil,
                    amount: Int,
                    currency: String? = nil,
                    platformFee: Int? = nil,
                    frameFee: Int? = nil,
                    totalFees: Int? = nil,
                    grossAmount: Int? = nil,
                    netAmount: Int? = nil,
                    description: String? = nil,
                    failureReason: String? = nil,
                    chargeIntent: String? = nil,
                    payout: String? = nil,
                    billingAgreement: String? = nil,
                    sourcePaymentMethod: FrameObjects.PaymentMethod? = nil,
                    destinationPaymentMethod: FrameObjects.PaymentMethod? = nil,
                    metadata: [String: String]? = nil,
                    livemode: Bool? = nil,
                    created: Int? = nil,
                    clientSecret: String? = nil) {
            self.id = id
            self.object = object
            self.status = status
            self.amount = amount
            self.currency = currency
            self.platformFee = platformFee
            self.frameFee = frameFee
            self.totalFees = totalFees
            self.grossAmount = grossAmount
            self.netAmount = netAmount
            self.description = description
            self.failureReason = failureReason
            self.chargeIntent = chargeIntent
            self.payout = payout
            self.billingAgreement = billingAgreement
            self.sourcePaymentMethod = sourcePaymentMethod
            self.destinationPaymentMethod = destinationPaymentMethod
            self.metadata = metadata
            self.livemode = livemode
            self.created = created
            self.clientSecret = clientSecret
        }

        /// Maps Swift property names to their snake_case JSON keys from the Frame API.
        public enum CodingKeys: String, CodingKey {
            case id, object, status, amount, currency, description, payout, metadata, livemode, created
            case clientSecret = "client_secret"
            case platformFee = "platform_fee"
            case frameFee = "frame_fee"
            case totalFees = "total_fees"
            case grossAmount = "gross_amount"
            case netAmount = "net_amount"
            case failureReason = "failure_reason"
            case chargeIntent = "charge_intent"
            case billingAgreement = "billing_agreement"
            case sourcePaymentMethod = "source_payment_method"
            case destinationPaymentMethod = "destination_payment_method"
        }
    }
}
