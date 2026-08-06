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

    /// Decoded response containing the Fingerprint public API key and region returned by the configuration endpoint.
    public struct GetFingerprintConfigurationResponse: Codable {
        /// The Fingerprint public API key.
        let apiKey: String?
        /// The Fingerprint region associated with the API key (e.g. "us", "eu", "ap").
        let region: String?

        enum CodingKeys: String, CodingKey {
            case apiKey = "api_key"
            case region
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
