//
//  CapabilityObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

extension FrameObjects {

    /// Represents the full set of capabilities that can be enabled or required for a Frame account.
    public enum Capabilities: String, Codable {
        // View - Identity and Phone Verification

        /// Capability that enables KYC (Know Your Customer) identity verification for an account.
        case kyc

        /// Capability that enables KYC with pre-fill support; also enables the base `kyc` capability.
        case kycPrefill = "kyc_prefill"

        /// Capability that enables phone-number verification for an account.
        case phoneVerification = "phone_verification"

        /// Backend capability that enables creator-shield protection; requires a `profile_url` when creating an account.
        case creatorShield = "creator_shield"

        /// Capability that enables age-verification checks for an account.
        case ageVerification = "age_verification"

        // View - Add or Select Payment Method (Card)

        /// Capability that enables card verification; also enables the `cardSend` capability.
        case cardVerification = "card_verification"

        /// Capability that allows an account to send funds via card.
        case cardSend = "card_send"

        /// Capability that allows an account to receive funds via card.
        case cardReceive = "card_receive"

        /// Capability that requires address verification (AVS) for credit and debit cards; performed on the backend.
        case addressVerification = "address_verification"

        // View - Add or Select Payment Method (ACH)

        /// Capability that enables bank-account verification for an account.
        case bankAccountVerification = "bank_account_verification"

        /// Capability that allows an account to send funds via bank account (ACH).
        case bankAccountSend = "bank_account_send"

        /// Capability that allows an account to receive funds via bank account (ACH).
        case bankAccountReceive = "bank_account_receive"

        // View - Geocompliance Flow

        /// Capability that enforces geo-compliance checks for an account.
        case geoCompliance = "geo_compliance"

        // View - Upload Documents
    }

    /// Describes a single requirement that must be satisfied in order to enable a capability.
    public struct CapabilityRequirement: Codable, Sendable, Equatable {
        /// Unique identifier for this capability requirement.
        public let id: String

        /// Object type identifier returned by the Frame API.
        public let object: String

        /// The kind of requirement (e.g., `"document"`, `"verification"`).
        public let type: String

        /// Current fulfillment status of the requirement (e.g., `"pending"`, `"satisfied"`).
        public let status: String

        /// Optional source that surfaced this requirement, if applicable.
        public let source: String?

        enum CodingKeys: String, CodingKey {
            case id, object, type, status, source
        }
    }

    /// Represents a Frame capability and its current state on a given account.
    public struct Capability: Codable, Sendable, Equatable {
        /// Unique identifier for this capability record.
        public let id: String

        /// Object type identifier returned by the Frame API.
        public let object: String

        /// Human-readable name of the capability.
        public let name: String

        /// Identifier of the account this capability is associated with.
        public let accountId: String

        /// Current status of the capability (e.g., `"active"`, `"inactive"`, `"pending"`).
        public let status: String

        /// Reason the capability is disabled, if applicable.
        public let disabledReason: String?

        /// List of requirement keys that are currently outstanding and must be resolved.
        public let currentlyDue: [String]?

        /// ISO 8601 timestamp indicating when the capability was created.
        public let created: String

        /// ISO 8601 timestamp indicating when the capability was last updated.
        public let updated: String

        /// Whether the capability is currently disabled.
        public let disabled: Bool?

        enum CodingKeys: String, CodingKey {
            case id, object, name, status
            case accountId = "account_id"
            case disabledReason = "disabled_reason"
            case currentlyDue = "currently_due"
            case created, updated, disabled
        }
    }
}
