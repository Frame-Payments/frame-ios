//
//  DisputeObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/5/25.
//

extension FrameObjects {
    /// The reason a dispute was opened against a charge.
    public enum DisputeReason: String, Codable, Sendable {
        /// The disputed charge is a duplicate of another transaction.
        case duplicate
        /// The cardholder claims the transaction was fraudulent.
        case fraudulent
        /// A general or catch-all dispute reason.
        case general
        /// The cardholder does not recognise the transaction.
        case unrecognized
        /// The bank was unable to process the transaction.
        case bankCannotProcess = "bank_cannot_process"
        /// A check associated with the transaction was returned.
        case checkReturned = "check_returned"
        /// The customer claims a credit was not applied to their account.
        case creditNotProcessed = "credit_not_processed"
        /// The dispute was initiated by the customer directly.
        case customerInitiated = "customer_initiated"
        /// The debit was not authorised by the account holder.
        case debitNotAuthorized = "debit_not_authorized"
        /// The account details used for the transaction were incorrect.
        case incorrectAccountDetails = "incorrect_account_details"
        /// The account had insufficient funds at the time of the transaction.
        case insufficientFunds = "insufficient_funds"
        /// The product or service was never received by the customer.
        case productNotReceived = "product_not_received"
        /// The product or service received was not as described or was defective.
        case productUnacceptable = "product_unacceptable"
        /// The customer cancelled their subscription before the charge was applied.
        case subscriptionCanceled = "subscription_canceled"
    }

    /// The current lifecycle status of a dispute.
    public enum DisputeStatus: String, Codable, Sendable {
        /// The dispute was resolved in the merchant's favour.
        case won
        /// The dispute was resolved in the cardholder's favour.
        case lost
        /// An early-fraud-warning has been issued and requires a merchant response.
        case warningNeedsResponse = "warning_needs_response"
        /// An early-fraud-warning is currently under review.
        case warningUnderReview = "warning_under_review"
        /// An early-fraud-warning has been closed without escalation.
        case warningClosed = "warning_closed"
        /// The dispute requires a response from the merchant.
        case needsResponse = "needs_response"
        /// The dispute is currently under review by the card network.
        case underReview = "under_review"
    }

    /// A dispute raised against a charge, representing a cardholder chargeback or inquiry.
    public struct Dispute: Codable, Equatable, Sendable {
        /// Unique identifier for the dispute.
        public let id: String
        /// Disputed amount in the smallest currency unit (e.g. cents).
        public let amount: Int
        /// Identifier of the charge associated with this dispute.
        public var charge: String?
        /// Three-letter ISO 4217 currency code for the disputed amount.
        public let currency: String
        /// Evidence submitted to contest the dispute, if any.
        public var evidence: DisputeEvidence?
        /// Identifier of the payment intent associated with the disputed charge, if applicable.
        public var chargeIntent: String?
        /// The reason the dispute was opened.
        public let reason: DisputeReason
        /// The current status of the dispute.
        public let status: DisputeStatus
        /// The object type identifier, always `"dispute"`.
        public let object: String
        /// Indicates whether the dispute was created in live mode (`true`) or test mode (`false`).
        public let livemode: Bool
        /// Unix timestamp (seconds) when the dispute was created.
        public let created: Int
        /// Unix timestamp (seconds) when the dispute was last updated.
        public let updated: Int

        /// Creates a new ``Dispute`` instance.
        /// - Parameters:
        ///   - id: Unique identifier for the dispute.
        ///   - amount: Disputed amount in the smallest currency unit.
        ///   - charge: Identifier of the associated charge.
        ///   - currency: Three-letter ISO 4217 currency code.
        ///   - evidence: Evidence submitted to contest the dispute.
        ///   - chargeIntent: Identifier of the associated payment intent.
        ///   - reason: The reason the dispute was opened.
        ///   - status: The current status of the dispute.
        ///   - object: The object type identifier.
        ///   - livemode: Whether the dispute exists in live mode.
        ///   - created: Unix timestamp when the dispute was created.
        ///   - updated: Unix timestamp when the dispute was last updated.
        public init(id: String, amount: Int, charge: String? = nil, currency: String, evidence: DisputeEvidence? = nil, chargeIntent: String? = nil, reason: DisputeReason, status: DisputeStatus, object: String, livemode: Bool, created: Int, updated: Int) {
            self.id = id
            self.amount = amount
            self.charge = charge
            self.currency = currency
            self.evidence = evidence
            self.chargeIntent = chargeIntent
            self.reason = reason
            self.status = status
            self.object = object
            self.livemode = livemode
            self.created = created
            self.updated = updated
        }

        enum CodingKeys: String, CodingKey {
            case id, amount, charge, currency, evidence, reason, status, object, livemode, created, updated
            case chargeIntent
        }
    }

    /// Supporting evidence provided by the merchant to contest a dispute.
    public struct DisputeEvidence: Codable, Equatable, Sendable {
        /// Log or narrative describing customer access activity relevant to the dispute.
        public var evidenceAccessActivityLog: String?
        /// Billing address on file for the customer at the time of the transaction.
        public var evidenceBillingAddress: String?
        /// A copy of or reference to the merchant's cancellation policy.
        public var evidenceCancellationPolicy: String?
        /// Explanation of how and when the cancellation policy was disclosed to the customer.
        public var evidenceCancellationPolicyDisclosure: String?
        /// Merchant's rebuttal to the customer's cancellation claim.
        public var evidenceCancellationRebuttal: String?
        /// Email address of the customer at the time of purchase.
        public var evidenceCustomerEmailAddress: String?
        /// Full name of the customer as provided during purchase.
        public var evidenceCustomerName: String?
        /// IP address from which the customer completed the purchase.
        public var evidenceCustomerPurchaseIP: String?
        /// Explanation of why the disputed charge is not a duplicate.
        public var evidenceDuplicateChargeExplanation: String?
        /// Identifier of the original charge that the disputed charge allegedly duplicates.
        public var evidenceDuplicateChargeId: String?
        /// Description of the product or service that was sold.
        public var evidenceProductDescription: String?
        /// Explanation of how and when the refund policy was disclosed to the customer.
        public var evidenceRefundPolicyDisclosure: String?
        /// Shipping or delivery tracking number for the order.
        public var evidenceShippingTrackingNumber: String?
        /// Any additional free-form text evidence not covered by other fields.
        public var evidenceUncategorizedText: String?

        /// Creates a new ``DisputeEvidence`` instance with all fields optional.
        /// - Parameters:
        ///   - evidenceAccessActivityLog: Log describing customer access activity.
        ///   - evidenceBillingAddress: Customer billing address on file.
        ///   - evidenceCancellationPolicy: Merchant's cancellation policy.
        ///   - evidenceCancellationPolicyDisclosure: How the cancellation policy was disclosed.
        ///   - evidenceCancellationRebuttal: Rebuttal to the customer's cancellation claim.
        ///   - evidenceCustomerEmailAddress: Customer's email address at purchase time.
        ///   - evidenceCustomerName: Customer's full name.
        ///   - evidenceCustomerPurchaseIP: IP address used during purchase.
        ///   - evidenceDuplicateChargeExplanation: Explanation that the charge is not a duplicate.
        ///   - evidenceDuplicateChargeId: ID of the charge alleged to be a duplicate.
        ///   - evidenceProductDescription: Description of the product or service sold.
        ///   - evidenceRefundPolicyDisclosure: How the refund policy was disclosed.
        ///   - evidenceShippingTrackingNumber: Shipping or delivery tracking number.
        ///   - evidenceUncategorizedText: Additional free-form evidence text.
        public init(evidenceAccessActivityLog: String? = nil, evidenceBillingAddress: String? = nil, evidenceCancellationPolicy: String? = nil, evidenceCancellationPolicyDisclosure: String? = nil, evidenceCancellationRebuttal: String? = nil, evidenceCustomerEmailAddress: String? = nil, evidenceCustomerName: String? = nil, evidenceCustomerPurchaseIP: String? = nil, evidenceDuplicateChargeExplanation: String? = nil, evidenceDuplicateChargeId: String? = nil, evidenceProductDescription: String? = nil, evidenceRefundPolicyDisclosure: String? = nil, evidenceShippingTrackingNumber: String? = nil, evidenceUncategorizedText: String? = nil) {
            self.evidenceAccessActivityLog = evidenceAccessActivityLog
            self.evidenceBillingAddress = evidenceBillingAddress
            self.evidenceCancellationPolicy = evidenceCancellationPolicy
            self.evidenceCancellationPolicyDisclosure = evidenceCancellationPolicyDisclosure
            self.evidenceCancellationRebuttal = evidenceCancellationRebuttal
            self.evidenceCustomerEmailAddress = evidenceCustomerEmailAddress
            self.evidenceCustomerName = evidenceCustomerName
            self.evidenceCustomerPurchaseIP = evidenceCustomerPurchaseIP
            self.evidenceDuplicateChargeExplanation = evidenceDuplicateChargeExplanation
            self.evidenceDuplicateChargeId = evidenceDuplicateChargeId
            self.evidenceProductDescription = evidenceProductDescription
            self.evidenceRefundPolicyDisclosure = evidenceRefundPolicyDisclosure
            self.evidenceShippingTrackingNumber = evidenceShippingTrackingNumber
            self.evidenceUncategorizedText = evidenceUncategorizedText
        }

        enum CodingKeys: String, CodingKey {
            case evidenceAccessActivityLog = "evidence.access_activity_log"
            case evidenceBillingAddress = "evidence.billing_address"
            case evidenceCancellationPolicy = "evidence.cancellation_policy"
            case evidenceCancellationPolicyDisclosure = "evidence.cancellation_policy_disclosure"
            case evidenceCancellationRebuttal = "evidence.cancellation_rebuttal"
            case evidenceCustomerEmailAddress = "evidence.customer_email_address"
            case evidenceCustomerName = "evidence.customer_name"
            case evidenceCustomerPurchaseIP = "evidence.customer_purchase_ip"
            case evidenceDuplicateChargeExplanation = "evidence.duplicate_charge_explanation"
            case evidenceDuplicateChargeId = "evidence.duplicate_charge_id"
            case evidenceProductDescription = "evidence.product_description"
            case evidenceRefundPolicyDisclosure = "evidence.refund_policy_disclosure"
            case evidenceShippingTrackingNumber = "evidence.shipping_tracking_number"
            case evidenceUncategorizedText = "evidence.uncategorized_text"
        }
    }
}
