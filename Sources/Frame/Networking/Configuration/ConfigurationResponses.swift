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
        @Lenient private(set) var appId: String?
        /// The Evervault team identifier.
        @Lenient private(set) var teamId: String?

        enum CodingKeys: String, CodingKey {
            case appId = "app_id"
            case teamId = "team_id"
        }
    }

    /// Decoded response containing the Fingerprint public API key and region returned by the configuration endpoint.
    public struct GetFingerprintConfigurationResponse: Codable {
        /// The Fingerprint public API key.
        @Lenient private(set) var apiKey: String?
        /// The Fingerprint region associated with the API key (e.g. "us", "eu", "ap").
        @Lenient private(set) var region: String?

        enum CodingKeys: String, CodingKey {
            case apiKey = "api_key"
            case region
        }
    }

    /// Decoded response containing Sift account and beacon key identifiers returned by the configuration endpoint.
    public struct GetSiftConfigurationResponse: Codable {
        /// The Sift account identifier.
        @Lenient private(set) var accountId: String?
        /// The Sift beacon key used to initialise the Sift SDK.
        @Lenient private(set) var beaconKey: String?

        enum CodingKeys: String, CodingKey {
            case accountId = "account_id"
            case beaconKey = "beacon_key"
        }
    }

    /// Decoded response containing Frame's legal document URLs (Privacy Policy, Terms of Service,
    /// Platform Agreement, and Card-Based Cash Terms & Conditions) returned by the configuration endpoint.
    public struct GetLegalConfigurationResponse: Codable {
        @Lenient private(set) var privacyUrl: String?
        @Lenient private(set) var termsUrl: String?
        @Lenient private(set) var platformAgreementUrl: String?
        @Lenient private(set) var cbcTermsAndConditions: String?

        enum CodingKeys: String, CodingKey {
            case privacyUrl = "privacy_url"
            case termsUrl = "terms_url"
            case platformAgreementUrl = "platform_agreement_url"
            case cbcTermsAndConditions = "cbc_terms_and_conditions"
        }
    }

    /// Decoded response containing the search-scoped Mapbox access token used for address
    /// autocomplete, returned by the configuration endpoint.
    public struct GetMapboxConfigurationResponse: Codable {
        /// The Mapbox access token, scoped to search and geocoding only.
        @Lenient private(set) var accessToken: String?
        /// When the token stops working, as an ISO-8601 string, or `nil` when it does not expire.
        ///
        /// Held as a `String` rather than a `Date`: the shared decoder uses the default
        /// `deferredToDate` strategy, which reads a number, so an ISO-8601 string would decode
        /// to `nil` here and read as "never expires".
        @Lenient private(set) var expiresAt: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresAt = "expires_at"
        }

        /// Whether ``expiresAt`` is in the past. `false` when absent or unparseable — an
        /// unreadable expiry shouldn't discard a working token.
        var hasExpired: Bool {
            guard let expiresAt,
                  let date = ISO8601DateFormatter().date(from: expiresAt) else { return false }
            return date <= Date()
        }
    }

    /// Decoded response of `/v1/config/all`, carrying every configuration block in one payload.
    ///
    /// Blocks are optional because the API omits one whose service failed rather than nulling it, so
    /// an absent block leaves the cached copy intact. Not `@Lenient`: it decodes via `Value(from:)`,
    /// which fails for a struct in a keyed container.
    public struct GetAllConfigurationResponse: Codable {
        public private(set) var evervault: GetEvervaultConfigurationResponse?
        public private(set) var fingerprint: GetFingerprintConfigurationResponse?
        public private(set) var legal: GetLegalConfigurationResponse?
        public private(set) var mapbox: GetMapboxConfigurationResponse?
        public private(set) var sift: GetSiftConfigurationResponse?
    }
}
