//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

extension FrameObjects {
    
    public enum AccountType: String, Codable, Sendable {
        case individual, business
    }
    
    public enum AccountStatus: String, Codable, Sendable {
        case pending, active, restricted, disabled
    }
    
    public struct AccountTermsOfService: Codable {
        public var acceptedAt: Int?
        public var ipAddress: String?
        public var userAgent: String?
        
        public init(acceptedAt: Int?, ipAddress: String?, userAgent: String?) {
            self.acceptedAt = acceptedAt
            self.ipAddress = ipAddress
            self.userAgent = userAgent
        }
        
        enum CodingKeys: String, CodingKey {
            case acceptedAt = "accepted_at"
            case ipAddress = "ip_address"
            case userAgent = "user_agent"
        }
    }
    
    public struct AccountProfile: Codable, Sendable, Equatable {
        public let business: BusinessAccount?
        public let individual: IndividualAccount?
    }
    
    public struct AccountPhoneNumber: Codable, Sendable, Equatable {
        public let number: String
        public let countryCode: String
    }
    
    public struct BusinessAccount: Codable, Sendable, Equatable {
        public let legalBusinessName: String
        public var doingBusinessAs: String?
        public let businessType: String
        public let email: String
        public var website: String?
        public var description: String?
        public var einLastFour: String?
        public var mcc: String?
        public var naics: String?
        public var address: BillingAddress?
        public var phone: AccountPhoneNumber?
        
        public init(legalBusinessName: String, doingBusinessAs: String? = nil, businessType: String, email: String, website: String? = nil, description: String? = nil, einLastFour: String? = nil, mcc: String? = nil, naics: String? = nil, address: BillingAddress? = nil, phone: AccountPhoneNumber? = nil) {
            self.legalBusinessName = legalBusinessName
            self.doingBusinessAs = doingBusinessAs
            self.businessType = businessType
            self.email = email
            self.website = website
            self.description = description
            self.einLastFour = einLastFour
            self.mcc = mcc
            self.naics = naics
            self.address = address
            self.phone = phone
        }
        
        enum CodingKeys: String, CodingKey {
            case email, website, description, mcc, naics, address, phone
            case legalBusinessName = "legal_business_name"
            case doingBusinessAs = "doing_business_as"
            case businessType = "business_type"
            case einLastFour = "ein_last_four"
        }
    }
    
    public struct IndividualAccount: Codable, Sendable, Equatable {
        public let firstName: String
        public let middleName: String?
        public let lastName: String
        public let suffix: String?
        public let email: String
        public let ssnLastFour: String?
        
        enum CodingKeys: String, CodingKey {
            case suffix, email
            case firstName = "first_name"
            case middleName = "middle_name"
            case lastName = "last_name"
            case ssnLastFour = "ssn_last_four"
        }
    }
    
    public struct Account: Codable, Sendable, Identifiable, Equatable {
        public let id: String
        public let object: String
        public let accountType: AccountType
        public let accountStatus: AccountStatus
        public let externalId: String?
        public let metadata: [String: String]?
        public let profile: AccountProfile?
        public let capabilities: [Capability]?
        public let createdAt: Int
        public let updatedAt: Int
        public let livemode: Bool
        
        public enum CodingKeys: String, CodingKey {
            case id, object, metadata, profile, livemode, capabilities
            case accountType = "type"
            case accountStatus = "status"
            case externalId = "external_id"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
}
