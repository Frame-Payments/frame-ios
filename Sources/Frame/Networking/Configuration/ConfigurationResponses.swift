//
//  ConfigurationResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/11/24.
//

import Foundation

/// Response model namespace for Configuration API calls.
public class ConfigurationResponses {
    /// Decoded response containing Evervault app and team identifiers returned by the configuration endpoint.
    public struct GetEvervaultConfigurationResponse: Codable {
        /// The Evervault application identifier.
        let appId: String?
        /// The Evervault team identifier.
        let teamId: String?

        enum CodingKeys: String, CodingKey {
            case appId = "app_id"
            case teamId = "team_id"
        }
    }

    /// Decoded response containing the Fingerprint credentials returned by the configuration endpoint.
    ///
    /// The three fields are one credential, not three settings. A key only works in
    /// the region it was minted for, and `environment` names the regime that key
    /// belongs to — so they are cached and read as a unit, never merged field by
    /// field against an older copy.
    public struct GetFingerprintConfigurationResponse: Codable {
        /// The Fingerprint public API key.
        let apiKey: String?
        /// The Fingerprint region associated with the API key (e.g. "us", "eu", "ap").
        let region: String?
        /// The Fingerprint environment the key belongs to (`"sealed"` or `"legacy"`).
        ///
        /// The API answers a capability it did not recognise with the legacy key and
        /// HTTP 200, so this stamp is the only way a client can tell which regime it
        /// was actually served.
        let environment: String?

        /// Whether the served credentials belong to the sealed environment.
        var isSealed: Bool { environment == FingerprintCapability.sealed }

        /// Whether the response names the environment its key belongs to.
        ///
        /// A cached copy without one was written before this build began declaring a
        /// capability, so nothing about it says which regime its key is from.
        var hasEnvironmentStamp: Bool { !(environment ?? "").isEmpty }

        enum CodingKeys: String, CodingKey {
            case apiKey = "api_key"
            case region
            case environment
        }
    }

    /// Decoded response containing Sift account and beacon key identifiers returned by the configuration endpoint.
    public struct GetSiftConfigurationResponse: Codable {
        /// The Sift account identifier.
        let accountId: String?
        /// The Sift beacon key used to initialise the Sift SDK.
        let beaconKey: String?

        enum CodingKeys: String, CodingKey {
            case accountId = "account_id"
            case beaconKey = "beacon_key"
        }
    }

    /// Decoded response containing Frame's legal document URLs (Privacy Policy, Terms of Service,
    /// Platform Agreement, and Card-Based Cash Terms & Conditions) returned by the configuration endpoint.
    public struct GetLegalConfigurationResponse: Codable {
        let privacyUrl: String?
        let termsUrl: String?
        let platformAgreementUrl: String?
        let cbcTermsAndConditions: String?

        enum CodingKeys: String, CodingKey {
            case privacyUrl = "privacy_url"
            case termsUrl = "terms_url"
            case platformAgreementUrl = "platform_agreement_url"
            case cbcTermsAndConditions = "cbc_terms_and_conditions"
        }
    }
}
