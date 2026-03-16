//
//  CapabilityObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

extension FrameObjects {
    
    public enum Capabilities: String, Codable {
        // View - Identity and Phone Verification
        case kyc
        case kycPrefill = "kyc_prefill" // Also enables base kyc capability
        case phoneVerification = "phone_verification"
        // Backend capability, the merchant should provide a profile_url when creating an account.
        case creatorShield = "creator_shield"
        case ageVerification = "age_verification"
        
        // View - Add or Select Payment Method (Card)
        case cardVerification = "card_verification" // Also enables card send capability
        case cardSend = "card_send"
        case cardReceive = "card_receive"
        case addressVerification = "address_verification" // pertains only to credit and debit card with AVS done on backend, require address if capability is present.
        
        // View - Add or Select Payment Method (ACH)
        case bankAccountVerification = "bank_account_verification"
        case bankAccountSend = "bank_account_send"
        case bankAccountReceive = "bank_account_receive"
        
        // View - Geocompliance Flow
        case geoCompliance = "geo_compliance"
        
        // View - Upload Documents
    }
    
    public struct CapabilityRequirement: Codable, Sendable, Equatable {
        public let id: String
        public let object: String
        public let type: String
        public let status: String
        public let source: String?
        
        enum CodingKeys: String, CodingKey {
            case id, object, type, status, source
        }
    }
    
    public struct Capability: Codable, Sendable, Equatable {
        public let id: String
        public let object: String
        public let name: String
        public let accountId: String
        public let status: String
        public let disabledReason: String?
        public let currentlyDue: [String]
        public let created: String
        public let updated: String
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
