//
//  ConfigurationAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/11/24.
//

import Foundation

// Protocol for Mock Testing
protocol ConfigurationProtocol {
    //async/await
    static func getEvervaultConfiguration() async throws -> ConfigurationResponses.GetConfigurationResponse?
}

// Charge Intents API
public class ConfigurationAPI: ConfigurationProtocol, @unchecked Sendable {
    //async/await
    public static func getEvervaultConfiguration() async throws -> ConfigurationResponses.GetConfigurationResponse? {
        let endpoint = ConfigurationEndpoints.getConfiguration
        let (data, _) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)
        if let data, let decodedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetConfigurationResponse.self, from: data) {
            return decodedResponse
        } else {
            return nil
        }
    }
}
