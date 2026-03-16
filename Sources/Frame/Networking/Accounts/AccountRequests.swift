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
        public let birthdate: String?
        public let ssn: String?
        public let ssnLast4: String?
        public let profileURL: String?

        public init(
            name: FrameObjects.AccountNameInfo, email: String, phone: FrameObjects.AccountPhoneNumber, address: FrameObjects.BillingAddress?, birthdate: String?, ssn: String?, ssnLast4: String?, profileURL: String?) {
            self.name = name
            self.email = email
            self.phone = phone
            self.address = address
            self.birthdate = birthdate
            self.ssn = ssn
            self.ssnLast4 = ssnLast4
            self.profileURL = profileURL
        }

        enum CodingKeys: String, CodingKey {
            case name, email, phone, address, ssn
            case birthdate
            case ssnLast4 = "ssn_last4"
            case profileURL = "profile_url"
        }
    }
    
    public struct CreateBusinessAccount: Codable, Sendable, Equatable {
        public let legalBusinessName: String
        public let businessType: String
        public let email: String
        public let doingBusinessAs: String?
        public let website: String?
        public let description: String?
        public let phone: FrameObjects.AccountPhoneNumber?
        public let address: FrameObjects.BillingAddress?
        public let ein: String?
        public let mcc: String?
        public let naics: String?

        public init(
            legalBusinessName: String,
            businessType: String,
            email: String,
            doingBusinessAs: String? = nil,
            website: String? = nil,
            description: String? = nil,
            phone: FrameObjects.AccountPhoneNumber? = nil,
            address: FrameObjects.BillingAddress? = nil,
            ein: String? = nil,
            mcc: String? = nil,
            naics: String? = nil
        ) {
            self.legalBusinessName = legalBusinessName
            self.businessType = businessType
            self.email = email
            self.doingBusinessAs = doingBusinessAs
            self.website = website
            self.description = description
            self.phone = phone
            self.address = address
            self.ein = ein
            self.mcc = mcc
            self.naics = naics
        }

        enum CodingKeys: String, CodingKey {
            case email, website, description, phone, address, ein, mcc, naics
            case legalBusinessName = "legal_business_name"
            case businessType = "business_type"
            case doingBusinessAs = "doing_business_as"
        }
    }
    
    public struct CreateAccountProfile: Codable, Sendable, Equatable {
        public let business: CreateBusinessAccount?
        public let individual: CreateIndividualAccount?
        
        public init(business: CreateBusinessAccount?, individual: CreateIndividualAccount?) {
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
        public var capabilities: [FrameObjects.Capabilities]?
        
        public init(accountType: FrameObjects.AccountType, externalId: String? = nil, termsOfService: FrameObjects.AccountTermsOfService? = nil, metadata: [String : String]? = nil, profile: CreateAccountProfile? = nil, capabilities: [FrameObjects.Capabilities]? = nil) {
            self.accountType = accountType
            self.externalId = externalId
            self.termsOfService = termsOfService
            self.metadata = metadata
            self.profile = profile
            self.capabilities = capabilities
        }
        
        enum CodingKeys: String, CodingKey {
            case profile, metadata, capabilities
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
        public let phoneNumber: String?
        public let phoneCountryCode: String?
        public let address: FrameObjects.BillingAddress?
        public let birthdate: String? // YYYY-MM-DD
        public let ssn: String?
        public let ssnLast4: String?
        public let profileURL: String?

        public init(
            name: FrameObjects.AccountNameInfo? = nil,
            email: String? = nil,
            phoneNumber: String? = nil,
            phoneCountryCode: String? = nil,
            address: FrameObjects.BillingAddress? = nil,
            birthdate: String? = nil,
            ssn: String? = nil,
            ssnLast4: String? = nil,
            profileURL: String? = nil
        ) {
            self.name = name
            self.email = email
            self.phoneNumber = phoneNumber
            self.phoneCountryCode = phoneCountryCode
            self.address = address
            self.birthdate = birthdate
            self.ssn = ssn
            self.ssnLast4 = ssnLast4
            self.profileURL = profileURL
        }

        enum CodingKeys: String, CodingKey {
            case name, email, address, ssn
            case birthdate
            case phoneNumber = "phone_number"
            case phoneCountryCode = "phone_country_code"
            case ssnLast4 = "ssn_last4"
            case profileURL = "profile_url"
        }
    }
    
    public struct UpdateBusinessAccount: Codable, Sendable, Equatable {
        public let legalBusinessName: String?
        public var doingBusinessAs: String?
        public var dba: String?
        public let businessType: String?
        public let email: String?
        public var website: String?
        public var description: String?
        public var phoneNumber: String?
        public var phoneCountryCode: String?
        public var address: FrameObjects.BillingAddress?
        public var ein: String?
        public var mcc: String?
        public var naics: String?

        public init(
            legalBusinessName: String? = nil,
            doingBusinessAs: String? = nil,
            dba: String? = nil,
            businessType: String? = nil,
            email: String? = nil,
            website: String? = nil,
            description: String? = nil,
            phoneNumber: String? = nil,
            phoneCountryCode: String? = nil,
            address: FrameObjects.BillingAddress? = nil,
            ein: String? = nil,
            mcc: String? = nil,
            naics: String? = nil
        ) {
            self.legalBusinessName = legalBusinessName
            self.doingBusinessAs = doingBusinessAs
            self.dba = dba
            self.businessType = businessType
            self.email = email
            self.website = website
            self.description = description
            self.phoneNumber = phoneNumber
            self.phoneCountryCode = phoneCountryCode
            self.address = address
            self.ein = ein
            self.mcc = mcc
            self.naics = naics
        }

        enum CodingKeys: String, CodingKey {
            case email, website, description, mcc, naics, address, dba, ein
            case legalBusinessName = "legal_business_name"
            case doingBusinessAs = "doing_business_as"
            case businessType = "business_type"
            case phoneNumber = "phone_number"
            case phoneCountryCode = "phone_country_code"
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

