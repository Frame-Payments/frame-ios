//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

public class AccountRequest {
    
    public struct CreateIndividualAccount: Codable, Sendable, Equatable {
        public let name: FrameObjects.AccountNameInfo
        public let email: String
        public let phone: FrameObjects.AccountPhoneNumber
        public let address: FrameObjects.BillingAddress?
        public let dob: String?
        public let ssn: String?
        
        public init(name: FrameObjects.AccountNameInfo, email: String, phone: FrameObjects.AccountPhoneNumber, address: FrameObjects.BillingAddress?, dob: String?, ssn: String?) {
            self.name = name
            self.email = email
            self.phone = phone
            self.address = address
            self.dob = dob
            self.ssn = ssn
        }
    }
    
    public struct CreateAccountProfile: Codable, Sendable, Equatable {
        public let business: FrameObjects.BusinessAccount?
        public let individual: CreateIndividualAccount?
        
        public init(business: FrameObjects.BusinessAccount?, individual: CreateIndividualAccount?) {
            self.business = business
            self.individual = individual
        }
    }
    
    public struct CreateAccountRequest: Codable {
        public var accountType: FrameObjects.AccountType
        public var externalId: String?
        public var termsOfService: FrameObjects.AccountTermsOfService?
        public var metadata: [String: String]?
        public var profile: CreateAccountProfile?
        
        public init(accountType: FrameObjects.AccountType, externalId: String? = nil, termsOfService: FrameObjects.AccountTermsOfService? = nil, metadata: [String : String]? = nil, profile: CreateAccountProfile? = nil) {
            self.accountType = accountType
            self.externalId = externalId
            self.termsOfService = termsOfService
            self.metadata = metadata
            self.profile = profile
        }
        
        enum CodingKeys: String, CodingKey {
            case profile, metadata
            case accountType = "type"
            case externalId = "external_id"
            case termsOfService = "terms_of_service"
        }
    }
    
    // Update Account Objects
    public struct UpdateAccountProfile: Codable, Sendable, Equatable {
        public let business: UpdateBusinessAccount?
        public let individual: UpdateIndividualAccount?
        
        public init(business: UpdateBusinessAccount?, individual: UpdateIndividualAccount?) {
            self.business = business
            self.individual = individual
        }
    }
    
    public struct UpdateIndividualAccount: Codable, Sendable, Equatable {
        public let name: FrameObjects.AccountNameInfo?
        public let email: String?
        public let phone: FrameObjects.AccountPhoneNumber?
        public let address: FrameObjects.BillingAddress?
        public let dob: String? // YYYY-MM-DD
        public let ssn: String?
        
        public init(name: FrameObjects.AccountNameInfo?, email: String?, phone: FrameObjects.AccountPhoneNumber?, address: FrameObjects.BillingAddress?, dob: String?, ssn: String?) {
            self.name = name
            self.email = email
            self.phone = phone
            self.address = address
            self.dob = dob
            self.ssn = ssn
        }
        
        enum CodingKeys: String, CodingKey {
            case name, email, phone, address, dob, ssn
        }
    }
    
    public struct UpdateBusinessAccount: Codable, Sendable, Equatable {
        public let legalBusinessName: String?
        public var doingBusinessAs: String?
        public let businessType: String?
        public let email: String?
        public var website: String?
        public var description: String?
        public var einLastFour: String?
        public var mcc: String?
        public var naics: String?
        public var address: FrameObjects.BillingAddress?
        public var phone: FrameObjects.AccountPhoneNumber?
        
        public init(legalBusinessName: String? = nil, doingBusinessAs: String? = nil, businessType: String? = nil, email: String? = nil, website: String? = nil, description: String? = nil, einLastFour: String? = nil, mcc: String? = nil, naics: String? = nil, address: FrameObjects.BillingAddress? = nil, phone: FrameObjects.AccountPhoneNumber? = nil) {
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
    
    public struct UpdateAccountRequest: Codable {
        public var accountType: FrameObjects.AccountType?
        public var externalId: String?
        public var termsOfService: FrameObjects.AccountTermsOfService?
        public var metadata: [String: String]?
        public var profile: UpdateAccountProfile?
        
        public init(accountType: FrameObjects.AccountType? = nil, externalId: String? = nil, termsOfService: FrameObjects.AccountTermsOfService? = nil, metadata: [String : String]? = nil, profile: UpdateAccountProfile) {
            self.accountType = accountType
            self.externalId = externalId
            self.termsOfService = termsOfService
            self.metadata = metadata
            self.profile = profile
        }
        
        enum CodingKeys: String, CodingKey {
            case profile, metadata
            case accountType = "type"
            case externalId = "external_id"
            case termsOfService = "terms_of_service"
        }
    }
}

