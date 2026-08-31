import Foundation
import FingerprintPro

/// The Fingerprint capability this build declares when fetching configuration.
enum FingerprintCapability {
    /// The header the configuration endpoint reads to pick an environment.
    static let header = "X-Frame-Sonar"
    /// The capability that earns the sealed environment's key.
    static let sealed = "sealed"
}

/// Configuration container for Fingerprint iOS SDK used by Frame.
///
/// The Fingerprint public API key and region are fetched from the Frame
/// configuration API (and cached in the keychain), so only client-side
/// behaviour toggles are exposed here.
public enum FingerprintConfiguration {
    /// Whether to request extended response format from Fingerprint.
    ///
    /// Forced on regardless of this setting when the configuration API serves a sealed
    /// key, since the sealed result is only present on the extended response.
    public static var extendedResponseFormat: Bool = false
    /// Whether Fingerprint is permitted to use device location data when generating a fingerprint.
    public static var allowUseOfLocationData: Bool = false
}

/// What we hand the sonar-session API to identify this device: the sealed result
/// when Fingerprint served one, and the plaintext visitor id when the
/// environment still serves that.
///
/// Both travel together on purpose. Before the sealed environment is activated
/// Fingerprint returns both; after activation the visitor id is withheld and
/// only the sealed result carries identity. Sending the pair means neither side
/// of that switch breaks us — and an environment with no sealing at all still
/// identifies by visitor id, which is the behaviour we have today.
struct FingerprintIdentification {
    /// Empty once the environment withholds it — the sealed result identifies instead.
    let visitorId: String
    /// Base64 sealed `/v4/events` payload. Absent when sealing is off or unavailable.
    let sealedResult: String?

    /// Whether this carries anything the API can identify the device by.
    var isUsable: Bool { !visitorId.isEmpty || sealedResult != nil }
}

enum FingerprintManager {
    private static var client: FingerprintClientProviding?

    /// Fetches the Fingerprint configuration from the Frame API, falling back to
    /// the keychain-cached copy when the network request is unavailable.
    ///
    /// Whatever the API serves is used as-is: the key is the whole instruction, and a
    /// client that refused a legacy key could not be moved back to one.
    ///
    /// The cached copy is only trusted when it carries a stamp at all. This build always
    /// declares its capability, so any config *it* cached names the environment the API
    /// chose — legacy included, which is the copy a rollback depends on offline. An
    /// unstamped one predates that and says nothing about which key it holds, so it is
    /// treated as a miss rather than used.
    private static func fetchConfiguration() async -> ConfigurationResponses.GetFingerprintConfigurationResponse? {
        if let configResponse = try? await ConfigurationAPI.getFingerprintConfiguration() {
            return configResponse
        }

        if let data = ConfigurationAPI.retrieveFromKeychain(key: ConfigurationKeys.fingerprint.rawValue),
           let cachedResponse = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetFingerprintConfigurationResponse.self, from: data),
           cachedResponse.hasEnvironmentStamp {
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

        // A sealed result only appears on the extended response, so a sealed key forces
        // the format on regardless of the integrator's setting. Left to the public flag
        // — which defaults to off — `sealedResult` comes back nil for every request and
        // the session silently posts nothing to identify the device with.
        let configuration = Configuration(
            apiKey: apiKey,
            region: region(from: configResponse.region),
            extendedResponseFormat: configResponse.isSealed || FingerprintConfiguration.extendedResponseFormat,
            allowUseOfLocationData: FingerprintConfiguration.allowUseOfLocationData
        )

        let instance = FingerprintProFactory.getInstance(configuration)
        client = instance
        return instance
    }

    #if DEBUG
    /// Stands in for Fingerprint in tests, so a test can exercise what the SDK does
    /// with an identification without depending on Fingerprint answering.
    ///
    /// Fingerprint needs a real API key and a live service to identify anything, which
    /// makes every session path untestable without a seam here. Returning `nil` models
    /// the environment being unavailable.
    nonisolated(unsafe) static var identificationOverride: (() -> FingerprintIdentification?)?

    /// Drops the memoised client and any test override so a test starts from a known state.
    ///
    /// The client is a static built from whatever configuration the first caller
    /// resolved, so without this one test's credentials survive into the next.
    static func resetForTesting() {
        client = nil
        identificationOverride = nil
    }
    #endif

    /// Asks Fingerprint to identify this device.
    ///
    /// Uses `getVisitorIdResponse` rather than `getVisitorId`: the latter returns a
    /// bare string and discards the sealed result entirely, which is the whole
    /// payload once the environment is activated.
    ///
    /// - Important: The result is never cached. The API rejects a sealed payload
    ///   stamped outside a ten-minute window in either direction, so every request
    ///   that needs one has to mint its own.
    static func identify(timeout: TimeInterval? = nil) async throws -> FingerprintIdentification? {
        #if DEBUG
        if let identificationOverride {
            return identificationOverride()
        }
        #endif

        guard let client = await configuredClient() else {
            return nil
        }

        let response: FingerprintResponse
        if let timeout {
            response = try await client.getVisitorIdResponse(timeout: timeout)
        } else {
            response = try await client.getVisitorIdResponse()
        }

        return FingerprintIdentification(visitorId: response.visitorId, sealedResult: response.sealedResult)
    }
}
