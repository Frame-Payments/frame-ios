import Foundation
import FingerprintPro

/// Configuration container for Fingerprint iOS SDK used by Frame.
public enum FingerprintConfiguration {
    /// Public API key obtained from the Fingerprint dashboard.
    public static var apiKey: String = "YEn02ZgQBqkN8wEwXQgU"

    /// Backend region associated with the API key.
    /// Defaults to `.global` (US). Make sure this matches your workspace region.
    public static var region: Region = .global

    /// Whether to request extended response format from Fingerprint.
    public static var extendedResponseFormat: Bool = false
}

enum FingerprintManager {
    private static var client: FingerprintClientProviding?

    private static func configuredClient() -> FingerprintClientProviding? {
        if let client {
            return client
        }

        guard !FingerprintConfiguration.apiKey.isEmpty else {
            // SDK consumer must set FingerprintConfiguration.apiKey before initialization.
            return nil
        }

        let configuration = Configuration(
            apiKey: FingerprintConfiguration.apiKey,
            region: FingerprintConfiguration.region,
            extendedResponseFormat: FingerprintConfiguration.extendedResponseFormat
        )

        let instance = FingerprintProFactory.getInstance(configuration)
        client = instance
        return instance
    }

    static func getVisitorId(timeout: TimeInterval? = nil) async throws -> String? {
        guard let client = configuredClient() else {
            return nil
        }

        if let timeout {
            return try await client.getVisitorId(timeout: timeout)
        } else {
            return try await client.getVisitorId()
        }
    }
}

