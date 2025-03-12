//
//  ConfigurationAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/11/24.
//

import Foundation
import Security

// Protocol for Mock Testing
protocol ConfigurationProtocol {
    //async/await
    static func getEvervaultConfiguration() async throws -> ConfigurationResponses.GetEvervaultConfigurationResponse?
    static func getSiftConfiguration() async throws -> ConfigurationResponses.GetSiftConfigurationResponse?
}

enum ConfigurationKeys: String {
    case evervault
    case sift
}

// Charge Intents API
public class ConfigurationAPI: ConfigurationProtocol, @unchecked Sendable {
    //async/await
    public static func getEvervaultConfiguration() async throws -> ConfigurationResponses.GetEvervaultConfigurationResponse? {
        let endpoint = ConfigurationEndpoints.getEvervaultConfiguration
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetEvervaultConfigurationResponse.self, from: data) {
            // Save configuration to chain
            ConfigurationAPI.saveConfigurationToKeychain(key: ConfigurationKeys.evervault.rawValue, value: decodedResponse)
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func getSiftConfiguration() async throws -> ConfigurationResponses.GetSiftConfigurationResponse? {
        let endpoint = ConfigurationEndpoints.getSiftConfiguration
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetSiftConfigurationResponse.self, from: data) {
            // Save configuration to chain
            ConfigurationAPI.saveConfigurationToKeychain(key: ConfigurationKeys.sift.rawValue, value: decodedResponse)
            return decodedResponse
        } else {
            return nil
        }
    }
    
    public static func saveConfigurationToKeychain(key: String, value: Codable) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
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
