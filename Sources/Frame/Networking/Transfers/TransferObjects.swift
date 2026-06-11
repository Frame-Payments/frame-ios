//
//  TransferObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 5/11/26.
//

import Foundation

extension FrameObjects {
    /// Represents the lifecycle state of a transfer within the Frame platform.
    public enum TransferStatus: String, Codable, Sendable {
        /// The transfer has been created but not yet processed.
        case pending
        /// The transfer was processed successfully.
        case succeeded
        /// The transfer has fully settled.
        case completed
        /// The transfer could not be completed.
        case failed
        /// The transfer was reversed after completion.
        case reversed
        /// The transfer was canceled before processing.
        case canceled
        /// The transfer was blocked, typically due to compliance or risk rules.
        case blocked
    }

    /// A record of a funds movement between a source and destination payment method on the Frame platform.
    public struct Transfer: Codable, Sendable, Identifiable, Equatable {
        /// Unique identifier for the transfer.
        public let id: String

        /// The object type identifier returned by the Frame API, typically `"transfer"`.
        public let object: String?

        /// Current lifecycle status of the transfer.
        public let status: TransferStatus?

        /// Transfer amount in the smallest currency unit (e.g. cents for USD).
        public let amount: Int

        /// ISO 4217 currency code for the transfer (e.g. `"usd"`).
        public let currency: String?

        /// Fee retained by the platform, in the smallest currency unit.
        public let platformFee: Int?

        /// Fee retained by Frame, in the smallest currency unit.
        public let frameFee: Int?

        /// Sum of all fees applied to the transfer, in the smallest currency unit.
        public let totalFees: Int?

        /// Total amount before fees are deducted, in the smallest currency unit.
        public let grossAmount: Int?

        /// Amount received after all fees are deducted, in the smallest currency unit.
        public let netAmount: Int?

        /// Human-readable description of the transfer.
        public let description: String?

        /// Machine-readable reason the transfer failed, if applicable.
        public let failureReason: String?

        /// Identifier of the charge intent that initiated this transfer.
        public let chargeIntent: String?

        /// Identifier of the payout associated with this transfer.
        public let payout: String?

        /// Identifier of the billing agreement linked to this transfer.
        public let billingAgreement: String?

        /// Payment method from which funds were drawn.
        public let sourcePaymentMethod: FrameObjects.PaymentMethod?

        /// Payment method to which funds were sent.
        public let destinationPaymentMethod: FrameObjects.PaymentMethod?

        /// Arbitrary key-value pairs attached to the transfer for application use.
        public let metadata: [String: String]?

        /// Whether this transfer was created in live mode (`true`) or test mode (`false`).
        public let livemode: Bool?

        /// Unix timestamp (seconds since epoch) when the transfer was created.
        public let created: Int?

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
                    created: Int? = nil) {
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
        }

        /// Maps Swift property names to their snake_case JSON keys from the Frame API.
        public enum CodingKeys: String, CodingKey {
            case id, object, status, amount, currency, description, payout, metadata, livemode, created
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
