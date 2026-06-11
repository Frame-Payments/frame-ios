//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

/// Request body namespace for Accounts API calls.
public class AccountRequest {

    /// Request body for creating a new individual account.
    public struct CreateIndividualAccount: Codable, Sendable, Equatable {
        /// The account holder's full name.
        public let name: FrameObjects.AccountNameInfo
        /// The account holder's email address.
        public let email: String
        /// The account holder's phone number.
        public let phone: FrameObjects.AccountPhoneNumber
        /// The account holder's billing address.
        public let address: FrameObjects.BillingAddress?
        /// The account holder's date of birth in `YYYY-MM-DD` format.
        public let birthdate: String?
        /// The account holder's full Social Security Number.
        public let ssn: String?
        /// The last four digits of the account holder's SSN.
        public let ssnLastFour: String?
        /// A URL pointing to the account holder's profile image or page.
        public let profileURL: String?

        /// Creates a new individual account creation request.
        ///
        /// - Parameters:
        ///   - name: The account holder's full name.
        ///   - email: The account holder's email address.
        ///   - phone: The account holder's phone number.
        ///   - address: The account holder's billing address.
        ///   - birthdate: The account holder's date of birth in `YYYY-MM-DD` format.
        ///   - ssn: The account holder's full Social Security Number.
        ///   - ssnLastFour: The last four digits of the account holder's SSN.
        ///   - profileURL: A URL pointing to the account holder's profile image or page.
        public init(
            name: FrameObjects.AccountNameInfo, email: String, phone: FrameObjects.AccountPhoneNumber, address: FrameObjects.BillingAddress?, birthdate: String?, ssn: String?, ssnLastFour: String? = nil, profileURL: String? = nil) {
            self.name = name
            self.email = email
            self.phone = phone
            self.address = address
            self.birthdate = birthdate
            self.ssn = ssn
            self.ssnLastFour = ssnLastFour
            self.profileURL = profileURL
        }

        enum CodingKeys: String, CodingKey {
            case name, email, phone, address, ssn
            case birthdate
            case ssnLastFour = "ssn_last_four"
            case profileURL = "profile_url"
        }
    }

    /// Request body for creating a new business account.
    public struct CreateBusinessAccount: Codable, Sendable, Equatable {
        /// The legal registered name of the business.
        public let legalBusinessName: String
        /// The type or structure of the business (e.g. `"llc"`, `"corporation"`).
        public let businessType: String
        /// The business contact email address.
        public let email: String
        /// An optional trade name or DBA ("doing business as") for the business.
        public let doingBusinessAs: String?
        /// The business's public website URL.
        public let website: String?
        /// A short description of the business.
        public let description: String?
        /// The business phone number.
        public let phone: FrameObjects.AccountPhoneNumber?
        /// The business's physical address.
        public let address: FrameObjects.BillingAddress?
        /// The Employer Identification Number of the business.
        public let ein: String?
        /// The Merchant Category Code for the business.
        public let mcc: String?
        /// The North American Industry Classification System code for the business.
        public let naics: String?

        /// Creates a new business account creation request.
        ///
        /// - Parameters:
        ///   - legalBusinessName: The legal registered name of the business.
        ///   - businessType: The type or structure of the business.
        ///   - email: The business contact email address.
        ///   - doingBusinessAs: An optional trade name or DBA for the business.
        ///   - website: The business's public website URL.
        ///   - description: A short description of the business.
        ///   - phone: The business phone number.
        ///   - address: The business's physical address.
        ///   - ein: The Employer Identification Number of the business.
        ///   - mcc: The Merchant Category Code for the business.
        ///   - naics: The North American Industry Classification System code for the business.
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

    /// A profile container used when creating an account, holding either a business or individual profile.
    public struct CreateAccountProfile: Codable, Sendable, Equatable {
        /// The business profile to associate with the new account.
        public let business: CreateBusinessAccount?
        /// The individual profile to associate with the new account.
        public let individual: CreateIndividualAccount?

        /// Creates a new account profile for account creation.
        ///
        /// - Parameters:
        ///   - business: The business profile to associate with the new account.
        ///   - individual: The individual profile to associate with the new account.
        public init(business: CreateBusinessAccount?, individual: CreateIndividualAccount?) {
            self.business = business
            self.individual = individual
        }
    }

    /// Top-level request body for creating a new Frame account.
    public struct CreateAccountRequest: Codable {
        /// The type of account being created.
        public var accountType: FrameObjects.AccountType
        /// An optional caller-supplied identifier to link the account to an external system.
        public var externalId: String?
        /// Terms of service acceptance details for the account.
        public var termsOfService: FrameObjects.AccountTermsOfService?
        /// Arbitrary key-value metadata to attach to the account.
        public var metadata: [String: String]?
        /// The individual or business profile for the new account.
        public var profile: CreateAccountProfile?
        /// The set of capabilities to request for the account.
        public var capabilities: [FrameObjects.Capabilities]?

        /// Creates a new account creation request.
        ///
        /// - Parameters:
        ///   - accountType: The type of account being created.
        ///   - externalId: An optional caller-supplied identifier to link the account to an external system.
        ///   - termsOfService: Terms of service acceptance details for the account.
        ///   - metadata: Arbitrary key-value metadata to attach to the account.
        ///   - profile: The individual or business profile for the new account.
        ///   - capabilities: The set of capabilities to request for the account.
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

    /// A profile container used when updating an existing account, holding either a business or individual profile.
    public struct UpdateAccountProfile: Codable, Sendable, Equatable {
        /// The updated business profile fields to apply.
        public let business: UpdateBusinessAccount?
        /// The updated individual profile fields to apply.
        public let individual: UpdateIndividualAccount?

        /// Creates an account profile update payload.
        ///
        /// - Parameters:
        ///   - business: The updated business profile fields to apply.
        ///   - individual: The updated individual profile fields to apply.
        public init(business: UpdateBusinessAccount?, individual: UpdateIndividualAccount?) {
            self.business = business
            self.individual = individual
        }
    }

    /// Request body for updating an existing individual account's profile fields.
    public struct UpdateIndividualAccount: Codable, Sendable, Equatable {
        /// The updated full name for the account holder.
        public let name: FrameObjects.AccountNameInfo?
        /// The updated email address for the account holder.
        public let email: String?
        /// The updated phone number for the account holder.
        public let phone: FrameObjects.AccountPhoneNumber?
        /// The updated billing address for the account holder.
        public let address: FrameObjects.BillingAddress?
        /// The updated date of birth in `YYYY-MM-DD` format.
        public let birthdate: String? // YYYY-MM-DD
        /// The updated full Social Security Number for the account holder.
        public let ssn: String?
        /// The updated last four digits of the account holder's SSN.
        public let ssnLastFour: String?
        /// The updated profile image or page URL for the account holder.
        public let profileURL: String?

        /// Creates an individual account update request.
        ///
        /// - Parameters:
        ///   - name: The updated full name for the account holder.
        ///   - email: The updated email address for the account holder.
        ///   - phone: The updated phone number for the account holder.
        ///   - address: The updated billing address for the account holder.
        ///   - birthdate: The updated date of birth in `YYYY-MM-DD` format.
        ///   - ssn: The updated full Social Security Number for the account holder.
        ///   - ssnLastFour: The updated last four digits of the account holder's SSN.
        ///   - profileURL: The updated profile image or page URL for the account holder.
        public init(
            name: FrameObjects.AccountNameInfo? = nil,
            email: String? = nil,
            phone: FrameObjects.AccountPhoneNumber? = nil,
            address: FrameObjects.BillingAddress? = nil,
            birthdate: String? = nil,
            ssn: String? = nil,
            ssnLastFour: String? = nil,
            profileURL: String? = nil
        ) {
            self.name = name
            self.email = email
            self.phone = phone
            self.address = address
            self.birthdate = birthdate
            self.ssn = ssn
            self.ssnLastFour = ssnLastFour
            self.profileURL = profileURL
        }

        enum CodingKeys: String, CodingKey {
            case name, email, address, ssn, phone
            case birthdate
            case ssnLastFour = "ssn_last_four"
            case profileURL = "profile_url"
        }
    }

    /// Request body for updating an existing business account's profile fields.
    public struct UpdateBusinessAccount: Codable, Sendable, Equatable {
        /// The updated legal registered name of the business.
        public let legalBusinessName: String?
        /// The updated trade name or DBA for the business.
        public var doingBusinessAs: String?
        /// Alternate DBA field; use `doingBusinessAs` when possible.
        public var dba: String?
        /// The updated type or structure of the business.
        public let businessType: String?
        /// The updated business contact email address.
        public let email: String?
        /// The updated public website URL for the business.
        public var website: String?
        /// The updated description of the business.
        public var description: String?
        /// The updated primary phone number for the business.
        public var phoneNumber: String?
        /// The updated country calling code for the business phone number.
        public var phoneCountryCode: String?
        /// The updated physical address for the business.
        public var address: FrameObjects.BillingAddress?
        /// The updated Employer Identification Number for the business.
        public var ein: String?
        /// The updated Merchant Category Code for the business.
        public var mcc: String?
        /// The updated North American Industry Classification System code for the business.
        public var naics: String?

        /// Creates a business account update request.
        ///
        /// - Parameters:
        ///   - legalBusinessName: The updated legal registered name of the business.
        ///   - doingBusinessAs: The updated trade name or DBA for the business.
        ///   - dba: Alternate DBA field.
        ///   - businessType: The updated type or structure of the business.
        ///   - email: The updated business contact email address.
        ///   - website: The updated public website URL for the business.
        ///   - description: The updated description of the business.
        ///   - phoneNumber: The updated primary phone number for the business.
        ///   - phoneCountryCode: The updated country calling code for the business phone number.
        ///   - address: The updated physical address for the business.
        ///   - ein: The updated Employer Identification Number for the business.
        ///   - mcc: The updated Merchant Category Code for the business.
        ///   - naics: The updated North American Industry Classification System code for the business.
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

    /// Top-level request body for updating an existing Frame account.
    public struct UpdateAccountRequest: Codable {
        /// The updated account type.
        public var accountType: FrameObjects.AccountType?
        /// The updated caller-supplied external identifier for the account.
        public var externalId: String?
        /// Updated terms of service acceptance details for the account.
        public var termsOfService: FrameObjects.AccountTermsOfService?
        /// Updated arbitrary key-value metadata for the account.
        public var metadata: [String: String]?
        /// The updated individual or business profile for the account.
        public var profile: UpdateAccountProfile?

        /// Creates a new account update request.
        ///
        /// - Parameters:
        ///   - accountType: The updated account type.
        ///   - externalId: The updated caller-supplied external identifier for the account.
        ///   - termsOfService: Updated terms of service acceptance details for the account.
        ///   - metadata: Updated arbitrary key-value metadata for the account.
        ///   - profile: The updated individual or business profile for the account.
        public init(accountType: FrameObjects.AccountType? = nil, externalId: String? = nil, termsOfService: FrameObjects.AccountTermsOfService? = nil, metadata: [String : String]? = nil, profile: UpdateAccountProfile? = nil) {
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
