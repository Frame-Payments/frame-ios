import Foundation
import FingerprintPro

/// Configuration container for Fingerprint iOS SDK used by Frame.
///
/// The Fingerprint public API key and region are fetched from the Frame
/// configuration API (and cached in the keychain), so only client-side
/// behaviour toggles are exposed here.
public enum FingerprintConfiguration {
    /// Whether to request extended response format from Fingerprint.
    public static var extendedResponseFormat: Bool = false
    /// Whether Fingerprint is permitted to use device location data when generating a fingerprint.
    public static var allowUseOfLocationData: Bool = false
}

enum FingerprintManager {
    private static var client: FingerprintClientProviding?

    /// Fetches the Fingerprint configuration from the Frame API, falling back to
    /// the keychain-cached copy when the network request is unavailable.
    private static func fetchConfiguration() async -> ConfigurationResponses.GetFingerprintConfigurationResponse? {
        if let configResponse = try? await ConfigurationAPI.getFingerprintConfiguration() {
            return configResponse
        }

        if let data = ConfigurationAPI.retrieveFromKeychain(key: ConfigurationKeys.fingerprint.rawValue),
           let cachedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetFingerprintConfigurationResponse.self, from: data) {
            return cachedResponse
        }

        return nil
    }

    private static func region(from rawValue: String?) -> Region {
        switch rawValue {
        case "eu":
            return .eu
        case "ap":
            return .ap
        default:
            return .global
        }
    }

    private static func configuredClient() async -> FingerprintClientProviding? {
        if let client {
            return client
        }

        guard let configResponse = await fetchConfiguration(),
              let apiKey = configResponse.apiKey, !apiKey.isEmpty else {
            // Fingerprint credentials are unavailable from both the Frame API and the keychain cache.
            return nil
        }

        let configuration = Configuration(
            apiKey: apiKey,
            region: region(from: configResponse.region),
            extendedResponseFormat: FingerprintConfiguration.extendedResponseFormat,
            allowUseOfLocationData: FingerprintConfiguration.allowUseOfLocationData
        )

        let instance = FingerprintProFactory.getInstance(configuration)
        client = instance
        return instance
    }

    static func getVisitorId(timeout: TimeInterval? = nil) async throws -> String? {
        guard let client = await configuredClient() else {
            return nil
        }

        if let timeout {
            return try await client.getVisitorId(timeout: timeout)
        } else {
            return try await client.getVisitorId()
        }
    }
}
