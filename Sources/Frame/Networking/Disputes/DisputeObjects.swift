//
//  DisputeObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/5/25.
//

extension FrameObjects {
    public enum DisputeReason: String, Codable, Sendable {
        case duplicate, fraudulent, general, unrecognized
        case bankCannotProcess = "bank_cannot_process"
        case checkReturned = "check_returned"
        case creditNotProcessed = "credit_not_processed"
        case customerInitiated = "customer_initiated"
        case debitNotAuthorized = "debit_not_authorized"
        case incorrectAccountDetails = "incorrect_account_details"
        case insufficientFunds = "insufficient_funds"
        case productNotReceived = "product_not_received"
        case productUnacceptable = "product_unacceptable"
        case subscriptionCanceled = "subscription_canceled"
    }
    
    public enum DisputeStatus: String, Codable, Sendable {
        case won, lost
        case warningNeedsResponse = "warning_needs_response"
        case warningUnderReview = "warning_under_review"
        case warningClosed = "warning_closed"
        case needsResponse = "needs_response"
        case underReview = "under_review"
    }
    
    public struct Dispute: Codable, Equatable, Sendable {
        public let id: String
        public let amount: Int
        public var charge: String?
        public let currency: String
        public var evidence: DisputeEvidence?
        public var chargeIntent: String?
        public let reason: DisputeReason
        public let status: DisputeStatus
        public let object: String
        public let livemode: Bool
        public let created: Int
        public let updated: Int
        
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
    
    public struct DisputeEvidence: Codable, Equatable, Sendable {
        public var evidenceAccessActivityLog: String?
        public var evidenceBillingAddress: String?
        public var evidenceCancellationPolicy: String?
        public var evidenceCancellationPolicyDisclosure: String?
        public var evidenceCancellationRebuttal: String?
        public var evidenceCustomerEmailAddress: String?
        public var evidenceCustomerName: String?
        public var evidenceCustomerPurchaseIP: String?
        public var evidenceDuplicateChargeExplanation: String?
        public var evidenceDuplicateChargeId: String?
        public var evidenceProductDescription: String?
        public var evidenceRefundPolicyDisclosure: String?
        public var evidenceShippingTrackingNumber: String?
        public var evidenceUncategorizedText: String?
        
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
