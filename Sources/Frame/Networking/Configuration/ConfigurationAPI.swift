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
}

/// Keys used to identify configuration entries stored in the keychain.
enum ConfigurationKeys: String {
    /// Key for the Evervault encryption configuration.
    case evervault
    /// Key for the Fingerprint device-intelligence configuration.
    case fingerprint
    /// Key for the Sift fraud-detection configuration.
    case sift
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
    
    /// Encodes a `Codable` value and writes (or updates) it in the system keychain under the given key.
    ///
    /// - Parameters:
    ///   - key: The keychain account identifier used to store the value.
    ///   - value: The `Codable` object to encode and persist.
    public static func saveConfigurationToKeychain(key: String, value: Codable) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }
    
    /// Retrieves raw data previously stored in the keychain under the given key.
    ///
    /// - Parameter key: The keychain account identifier to look up.
    /// - Returns: The stored `Data`, or `nil` if no matching entry is found.
    public static func retrieveFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        if let data = result as? Data {
            return data
        }
        return nil
    }
}
