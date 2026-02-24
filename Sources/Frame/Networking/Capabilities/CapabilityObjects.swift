//
//  CapabilityObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

extension FrameObjects {
    
    public enum Capabilities: String, Codable {
        case kyc
        case phoneVerification = "phone_verification"
        case creatorShield = "creator_shield"
        case cardSend = "card_send"
        case cardReceive = "card_receive"
        case bankAccountSend = "bank_account_send"
        case bankAccountReceive = "bank_account_receive"
        case geoCompliance = "geo_compliance"
        case addressVerification = "address_verification"
        case cardVerification = "card_verification" // Also enables card send capability
        case bankAccountVerification = "bank_account_verification"
        case kycPrefill = "kyc_prefill" // Also enables kyc capability
        case ageVerification = "age_verification"
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
        public let status: String
        public let disabledReason: String?
        public let requirements: [CapabilityRequirement]?
        public let createdAt: Int
        public let updatedAt: Int
        
        enum CodingKeys: String, CodingKey {
            case id, object, name, status, requirements
            case disabledReason = "disabled_reason"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
}
