//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/14/26.
//

import Foundation

extension FrameObjects {

    /// Distinguishes whether a Frame account belongs to an individual or a business entity.
    public enum AccountType: String, Codable, Sendable {
        /// A personal account owned by an individual.
        case individual
        /// A business or merchant account.
        case business
    }

    /// Represents the lifecycle state of a Frame account.
    public enum AccountStatus: String, Codable, Sendable {
        /// The account has been created but verification is not yet complete.
        case pending
        /// The account is fully verified and operational.
        case active
        /// The account is active but has limitations due to incomplete requirements.
        case restricted
        /// The account has been deactivated and cannot process transactions.
        case disabled
    }

    /// Records acceptance of the Frame terms of service for an account.
    public struct AccountTermsOfService: Codable, Equatable {
        /// Unique token identifying the version of the terms that was accepted.
        public var token: String?
        /// IP address from which the terms were accepted.
        public var ipAddress: String?
        /// ISO 8601 timestamp indicating when the terms were accepted.
        public var acceptedAt: String?

        /// Creates a terms-of-service acceptance record.
        /// - Parameters:
        ///   - token: Token identifying the accepted terms version.
        ///   - ipAddress: IP address of the acceptor.
        ///   - acceptedAt: Timestamp of acceptance.
        public init(token: String?, ipAddress: String? = nil, acceptedAt: String? = nil) {
            self.token = token
            self.ipAddress = ipAddress
            self.acceptedAt = acceptedAt
        }

        enum CodingKeys: String, CodingKey {
            case token
            case ipAddress = "ip_address"
            case acceptedAt = "accepted_at"
        }
    }

    /// Name components for an individual associated with an account.
    public struct AccountNameInfo: Codable, Sendable, Equatable {
        /// Given name of the individual. Required when creating an account.
        public let firstName: String?
        /// Middle name of the individual.
        public let middleName: String?
        /// Family name of the individual. Required when creating an account.
        public let lastName: String?
        /// Name suffix (e.g., Jr., Sr., III).
        public let suffix: String?

        /// Creates a name info value.
        /// - Parameters:
        ///   - firstName: Given name.
        ///   - middleName: Middle name.
        ///   - lastName: Family name.
        ///   - suffix: Name suffix.
        public init(firstName: String? = nil, middleName: String? = nil, lastName: String? = nil, suffix: String? = nil) {
            self.firstName = firstName
            self.middleName = middleName
            self.lastName = lastName
            self.suffix = suffix
        }

        enum CodingKeys: String, CodingKey {
            case suffix
            case firstName = "first_name"
            case middleName = "middle_name"
            case lastName = "last_name"
        }
    }

    /// Container for the account's detailed profile, holding either business or individual sub-profile data.
    public struct AccountProfile: Codable, Sendable, Equatable {
        /// Business-specific profile details, present when `accountType` is `.business`.
        public let business: BusinessAccount?
        /// Individual-specific profile details, present when `accountType` is `.individual`.
        public let individual: IndividualAccount?
    }

    /// A phone number with its associated country dialing code.
    public struct AccountPhoneNumber: Codable, Sendable, Equatable {
        /// Local phone number, without the country code.
        public let number: String
        /// ISO 3166-1 alpha-2 country code (e.g., "US").
        public let countryCode: String

        /// Creates a phone number value.
        /// - Parameters:
        ///   - number: Local phone number digits.
        ///   - countryCode: ISO 3166-1 alpha-2 country code.
        public init(number: String, countryCode: String) {
            self.number = number
            self.countryCode = countryCode
        }

        enum CodingKeys: String, CodingKey {
            case number
            case countryCode = "country_code"
        }
    }

    /// Profile data specific to a business account.
    public struct BusinessAccount: Codable, Sendable, Equatable {
        /// Full legal name of the business.
        public let legalBusinessName: String
        /// Trade name or DBA name, if different from the legal name.
        public var doingBusinessAs: String?
        /// Classification of the business structure (e.g., "llc", "corporation").
        public let businessType: String
        /// Primary contact email address for the business.
        public let email: String
        /// Public-facing website URL of the business.
        public var website: String?
        /// Short description of the business and its products or services.
        public var description: String?
        /// Last four digits of the business's Employer Identification Number.
        public var einLastFour: String?
        /// Merchant Category Code that classifies the business's primary activity.
        public var mcc: String?
        /// North American Industry Classification System code for the business.
        public var naics: String?
        /// Physical or mailing address of the business.
        public var address: AccountBillingAddress?
        /// Primary contact phone number for the business.
        public var phone: AccountPhoneNumber?

        /// Creates a business account profile.
        /// - Parameters:
        ///   - legalBusinessName: Full legal name of the business.
        ///   - doingBusinessAs: Optional trade name.
        ///   - businessType: Business structure classification.
        ///   - email: Contact email address.
        ///   - website: Optional public website URL.
        ///   - description: Optional business description.
        ///   - einLastFour: Optional last four digits of the EIN.
        ///   - mcc: Optional Merchant Category Code.
        ///   - naics: Optional NAICS code.
        ///   - address: Optional business address.
        ///   - phone: Optional contact phone number.
        public init(legalBusinessName: String, doingBusinessAs: String? = nil, businessType: String, email: String, website: String? = nil, description: String? = nil, einLastFour: String? = nil, mcc: String? = nil, naics: String? = nil, address: AccountBillingAddress? = nil, phone: AccountPhoneNumber? = nil) {
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

    /// Profile data specific to an individual account holder.
    public struct IndividualAccount: Codable, Sendable, Equatable {
        /// Legal name of the individual.
        public let name: FrameObjects.AccountNameInfo?
        /// Contact email address of the individual.
        public let email: String?
        /// Last four digits of the individual's Social Security Number.
        public let ssnLastFour: String?
        /// Structured phone number for the individual.
        public let phone: FrameObjects.AccountPhoneNumber?
        /// Raw phone number string, used when `phone` is not present.
        public let phoneNumber: String?
        /// Country dialing code associated with `phoneNumber`.
        public let phoneCountryCode: String?
        /// Billing address of the individual.
        public let address: FrameObjects.BillingAddress?
        /// Date of birth in YYYY-MM-DD format.
        public let birthdate: String?

        /// - Note: `CodingKeys` is public to allow external decoders to reference key names if needed.
        public enum CodingKeys: String, CodingKey {
            case email, address, birthdate, name, phone
            case ssnLastFour = "ssn_last_four"
            case phoneNumber = "phone_number"
            case phoneCountryCode = "phone_country_code"
        }
    }

    /// A billing or mailing address associated with an account.
    public struct AccountBillingAddress: Codable, Sendable, Equatable {
        /// City or locality.
        public var city: String?
        /// ISO 3166-1 alpha-2 country code (e.g., "US").
        public var country: String?
        /// State, province, or region.
        public var state: String?
        /// Postal or ZIP code.
        public var postalCode: String
        /// Primary street address line.
        public var addressLine1: String?
        /// Secondary address line (suite, apartment, etc.).
        public var addressLine2: String?

        /// Creates an account billing address.
        /// - Parameters:
        ///   - city: City or locality.
        ///   - country: ISO 3166-1 alpha-2 country code.
        ///   - state: State or province.
        ///   - postalCode: Postal or ZIP code.
        ///   - addressLine1: Primary street address.
        ///   - addressLine2: Optional secondary address line.
        public init(city: String? = nil, country: String? = nil, state: String? = nil, postalCode: String, addressLine1: String? = nil, addressLine2: String? = nil) {
            self.city = city
            self.country = country
            self.state = state
            self.postalCode = postalCode
            self.addressLine1 = addressLine1
            self.addressLine2 = addressLine2
        }

        public enum CodingKeys: String, CodingKey {
            case city, country
            case state = "state_or_province"
            case postalCode = "postal_code"
            case addressLine1 = "line_1"
            case addressLine2 = "line_2"
        }
    }

    /// Represents a single onboarding or compliance step that must be completed for an account.
    public struct AccountStep: Codable, Sendable, Equatable {
        /// Machine-readable identifier for this step.
        public let key: String
        /// Current completion status of the step (e.g., "complete", "pending").
        public let status: String
        /// Human-readable label describing the step.
        public let label: String
        /// All field keys that are part of this step.
        public let fields: [String]
        /// Field keys that must be submitted before this step can advance.
        public let currentlyDue: [String]

        /// Creates an account step.
        /// - Parameters:
        ///   - key: Machine-readable step identifier.
        ///   - status: Current status of the step.
        ///   - label: Human-readable step label.
        ///   - fields: All fields belonging to the step.
        ///   - currentlyDue: Fields that are currently required.
        public init(key: String, status: String, label: String, fields: [String], currentlyDue: [String]) {
            self.key = key
            self.status = status
            self.label = label
            self.fields = fields
            self.currentlyDue = currentlyDue
        }

        enum CodingKeys: String, CodingKey {
            case key, status, label, fields
            case currentlyDue = "currently_due"
        }
    }

    /// A Frame account representing an individual or business that can send and receive payments.
    public struct Account: Codable, Sendable, Identifiable, Equatable {
        /// Unique identifier for the account.
        public let id: String
        /// API object type, always `"account"`.
        public let object: String
        /// Whether this is an individual or business account.
        public let accountType: AccountType
        /// Current lifecycle status of the account.
        public let accountStatus: AccountStatus
        /// Optional caller-supplied identifier for cross-referencing with external systems.
        public let externalId: String?
        /// Arbitrary key-value pairs for storing additional information.
        public let metadata: [String: String]?
        /// Terms-of-service acceptance record for the account.
        public var termsOfService: AccountTermsOfService?
        /// Detailed profile information for the account holder.
        public let profile: AccountProfile?
        /// Payment capabilities that have been enabled for this account.
        public let capabilities: [Capability]?
        /// Onboarding or compliance steps associated with the account.
        public let steps: [AccountStep]?
        /// Unix timestamp (seconds) when the account was created.
        public let created: Int
        /// Unix timestamp (seconds) when the account was last updated.
        public let updated: Int
        /// `true` when the account is operating in live mode; `false` for test mode.
        public let livemode: Bool

        /// Creates an account object.
        /// - Parameters:
        ///   - id: Unique account identifier.
        ///   - object: API object type string.
        ///   - accountType: Individual or business classification.
        ///   - accountStatus: Current lifecycle status.
        ///   - externalId: Optional external reference identifier.
        ///   - metadata: Optional arbitrary key-value metadata.
        ///   - termsOfService: Optional terms-of-service acceptance record.
        ///   - profile: Optional detailed profile for the account holder.
        ///   - capabilities: Optional list of enabled payment capabilities.
        ///   - steps: Optional onboarding steps for the account.
        ///   - created: Unix timestamp of account creation.
        ///   - updated: Unix timestamp of the last update.
        ///   - livemode: Whether the account is in live mode.
        public init(
            id: String,
            object: String,
            accountType: AccountType,
            accountStatus: AccountStatus,
            externalId: String? = nil,
            metadata: [String: String]? = nil,
            termsOfService: AccountTermsOfService? = nil,
            profile: AccountProfile? = nil,
            capabilities: [Capability]? = nil,
            steps: [AccountStep]? = nil,
            created: Int,
            updated: Int,
            livemode: Bool
        ) {
            self.id = id
            self.object = object
            self.accountType = accountType
            self.accountStatus = accountStatus
            self.externalId = externalId
            self.metadata = metadata
            self.termsOfService = termsOfService
            self.profile = profile
            self.capabilities = capabilities
            self.steps = steps
            self.created = created
            self.updated = updated
            self.livemode = livemode
        }

        public enum CodingKeys: String, CodingKey {
            case id, object, metadata, profile, livemode, capabilities, steps, created, updated
            case accountType = "type"
            case accountStatus = "status"
            case externalId = "external_id"
            case termsOfService = "terms_of_service"
        }
    }

    /// A paginated list response containing an array of ``Account`` objects.
    public struct AccountListResponse: Codable, Sendable, Equatable {
        /// The accounts returned for the current page of results.
        public let data: [Account]
    }
}
