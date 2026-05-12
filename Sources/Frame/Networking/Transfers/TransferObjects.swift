//
//  TransferObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 5/11/26.
//

import Foundation

extension FrameObjects {
    public enum TransferStatus: String, Codable, Sendable {
        case pending, succeeded, completed, failed, reversed, canceled, blocked
    }

    public struct Transfer: Codable, Sendable, Identifiable, Equatable {
        public let id: String
        public let object: String?
        public let status: TransferStatus?
        public let amount: Int
        public let currency: String?
        public let platformFee: Int?
        public let frameFee: Int?
        public let totalFees: Int?
        public let grossAmount: Int?
        public let netAmount: Int?
        public let description: String?
        public let failureReason: String?
        public let chargeIntent: String?
        public let payout: String?
        public let billingAgreement: String?
        public let sourcePaymentMethod: FrameObjects.PaymentMethod?
        public let destinationPaymentMethod: FrameObjects.PaymentMethod?
        public let metadata: [String: String]?
        public let livemode: Bool?
        public let created: Int?

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
