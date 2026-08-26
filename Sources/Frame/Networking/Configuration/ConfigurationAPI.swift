//
//  ConfigurationAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/11/24.
//

import Foundation
import Security

/// Internal protocol used to abstract `ConfigurationAPI` for mock testing.
protocol ConfigurationProtocol {
    //async/await
    static func getEvervaultConfiguration() async throws -> ConfigurationResponses.GetEvervaultConfigurationResponse?
    static func getFingerprintConfiguration() async throws -> ConfigurationResponses.GetFingerprintConfigurationResponse?
    static func getSiftConfiguration() async throws -> ConfigurationResponses.GetSiftConfigurationResponse?
    static func getLegalConfiguration() async throws -> ConfigurationResponses.GetLegalConfigurationResponse?
    static func getMapboxConfiguration() async throws -> ConfigurationResponses.GetMapboxConfigurationResponse?
    static func getAllConfiguration() async throws -> ConfigurationResponses.GetAllConfigurationResponse?
}

/// Keys used to identify configuration entries stored in the keychain.
enum ConfigurationKeys: String {
    /// Key for the Evervault encryption configuration.
    case evervault
    /// Key for the Fingerprint device-intelligence configuration.
    case fingerprint
    /// Key for the Sift fraud-detection configuration.
    case sift
    case legal
    /// Key for the Mapbox address-autocomplete configuration.
    case mapbox
}

/// Manages SDK configuration resources, including fetching and caching third-party service
/// credentials (Evervault, Fingerprint, Sift) from the Frame API and persisting them in the system keychain.
public class ConfigurationAPI: ConfigurationProtocol, @unchecked Sendable {
    //async/await
    /// Fetches the Evervault encryption configuration from the Frame API and caches it in the keychain.
    ///
    /// - Returns: A ``ConfigurationResponses/GetEvervaultConfigurationResponse`` containing the
    ///   Evervault app and team identifiers, or `nil` if the response cannot be decoded.
    /// - Throws: A networking error if the request fails.
    public static func getEvervaultConfiguration() async throws -> ConfigurationResponses.GetEvervaultConfigurationResponse? {
        let endpoint = ConfigurationEndpoints.getEvervaultConfiguration
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .publishable)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetEvervaultConfigurationResponse.self, from: data) {
            // Save configuration to chain
            ConfigurationAPI.saveConfigurationToKeychain(key: ConfigurationKeys.evervault.rawValue, value: decodedResponse)
            return decodedResponse
        } else {
            return nil
        }
    }
    
    /// Fetches the Fingerprint device-intelligence configuration from the Frame API and caches it in the keychain.
    ///
    /// - Returns: A ``ConfigurationResponses/GetFingerprintConfigurationResponse`` containing the
    ///   Fingerprint public API key and region, or `nil` if the response cannot be decoded.
    /// - Throws: A networking error if the request fails.
    public static func getFingerprintConfiguration() async throws -> ConfigurationResponses.GetFingerprintConfigurationResponse? {
        let endpoint = ConfigurationEndpoints.getFingerprintConfiguration
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .publishable)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetFingerprintConfigurationResponse.self, from: data) {
            // Save configuration to chain
            ConfigurationAPI.saveConfigurationToKeychain(key: ConfigurationKeys.fingerprint.rawValue, value: decodedResponse)
            return decodedResponse
        } else {
            return nil
        }
    }

    /// Fetches the Sift fraud-detection configuration from the Frame API and caches it in the keychain.
    ///
    /// - Returns: A ``ConfigurationResponses/GetSiftConfigurationResponse`` containing the
    ///   Sift account identifier and beacon key, or `nil` if the response cannot be decoded.
    /// - Throws: A networking error if the request fails.
    public static func getSiftConfiguration() async throws -> ConfigurationResponses.GetSiftConfigurationResponse? {
        let endpoint = ConfigurationEndpoints.getSiftConfiguration
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .publishable)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetSiftConfigurationResponse.self, from: data) {
            // Save configuration to chain
            ConfigurationAPI.saveConfigurationToKeychain(key: ConfigurationKeys.sift.rawValue, value: decodedResponse)
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func getLegalConfiguration() async throws -> ConfigurationResponses.GetLegalConfigurationResponse? {
        let endpoint = ConfigurationEndpoints.getLegalConfiguration
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .publishable)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetLegalConfigurationResponse.self, from: data) {
            ConfigurationAPI.saveConfigurationToKeychain(key: ConfigurationKeys.legal.rawValue, value: decodedResponse)
            return decodedResponse
        } else {
            return nil
        }
    }

    /// Fetches the Mapbox address-autocomplete configuration from the Frame API and caches it in the keychain.
    ///
    /// - Returns: A ``ConfigurationResponses/GetMapboxConfigurationResponse`` containing the
    ///   search-scoped Mapbox access token, or `nil` if the response cannot be decoded.
    /// - Throws: A networking error if the request fails.
    public static func getMapboxConfiguration() async throws -> ConfigurationResponses.GetMapboxConfigurationResponse? {
        let endpoint = ConfigurationEndpoints.getMapboxConfiguration
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .publishable)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetMapboxConfigurationResponse.self, from: data) {
            ConfigurationAPI.saveConfigurationToKeychain(key: ConfigurationKeys.mapbox.rawValue, value: decodedResponse)
            return decodedResponse
        } else {
            return nil
        }
    }

    /// Fetches every configuration block in one request and caches each present block under the same
    /// keychain key its individual endpoint uses, turning those fetches into cache hits. An omitted
    /// block is skipped rather than cleared, so a service that failed server-side keeps its cache.
    ///
    /// - Returns: A ``ConfigurationResponses/GetAllConfigurationResponse``, or `nil` if the response
    ///   cannot be decoded.
    /// - Throws: A networking error if the request fails.
    public static func getAllConfiguration() async throws -> ConfigurationResponses.GetAllConfigurationResponse? {
        let endpoint = ConfigurationEndpoints.getAllConfiguration
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, auth: .publishable)
        guard let data,
              let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetAllConfigurationResponse.self, from: data) else {
            return nil
        }

        cache(decodedResponse.evervault, as: .evervault)
        cache(decodedResponse.fingerprint, as: .fingerprint)
        cache(decodedResponse.legal, as: .legal)
        cache(decodedResponse.mapbox, as: .mapbox)
        cache(decodedResponse.sift, as: .sift)

        return decodedResponse
    }

    private static func cache(_ block: Codable?, as key: ConfigurationKeys) {
        guard let block else { return }
        ConfigurationAPI.saveConfigurationToKeychain(key: key.rawValue, value: block)
    }

    /// Encodes a `Codable` value and writes (or updates) it in the keychain under the given key.
    ///
    /// - Parameters:
    ///   - key: The keychain account identifier used to store the value.
    ///   - value: The `Codable` object to encode and persist.
    public static func saveConfigurationToKeychain(key: String, value: Codable) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        store.set(data, forKey: key)
    }

    /// Retrieves raw data previously stored in the keychain under the given key.
    ///
    /// - Parameter key: The keychain account identifier to look up.
    /// - Returns: The stored `Data`, or `nil` if no matching entry is found.
    public static func retrieveFromKeychain(key: String) -> Data? {
        store.data(forKey: key)
    }
}

/// The backing store for cached configuration, so tests can swap the real keychain for an in-memory
/// one instead of writing device-wide state that leaks between suites.
protocol ConfigurationStore: Sendable {
    func data(forKey key: String) -> Data?
    func set(_ data: Data, forKey key: String)
    func remove(forKey key: String)
}

extension ConfigurationAPI {
    /// The active store. Tests replace this; production always uses the keychain.
    nonisolated(unsafe) static var store: ConfigurationStore = KeychainConfigurationStore()
}

/// Stores configuration in the system keychain as a generic password per key.
struct KeychainConfigurationStore: ConfigurationStore {
    private func query(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key]
    }

    func data(forKey key: String) -> Data? {
        var query = self.query(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    func set(_ data: Data, forKey key: String) {
        let query = self.query(key)
        let attributes: [String: Any] = [kSecValueData as String: data]
        if SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func remove(forKey key: String) {
        SecItemDelete(query(key) as CFDictionary)
    }
}
