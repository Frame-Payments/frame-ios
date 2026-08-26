import Foundation
import EvervaultCore

/// Configures the Evervault client once and lets concurrent callers await that same work.
///
/// `Evervault.shared.configure` is synchronous but the credentials behind it are fetched, so a
/// caller that kicks off configuration and encrypts on the next line can encrypt before the client
/// exists. Awaiting ``ensureConfigured()`` closes that window.
actor EvervaultConfigurator {
    static let shared = EvervaultConfigurator()

    private var inFlight: Task<Bool, Never>?

    /// Configures Evervault if it is not already configured, joining any configuration already in
    /// progress rather than starting a second one.
    ///
    /// - Returns: `true` once Evervault holds credentials, `false` if none could be resolved.
    @discardableResult
    func ensureConfigured() async -> Bool {
        if FrameNetworking.shared.isEvervaultConfigured { return true }

        if let inFlight { return await inFlight.value }

        let task = Task<Bool, Never> { await Self.configure() }
        inFlight = task
        let configured = await task.value
        inFlight = nil
        return configured
    }

    /// Resolves Evervault credentials from the API, falling back to the keychain-cached copy.
    private static func configure() async -> Bool {
        if let response = try? await ConfigurationAPI.getEvervaultConfiguration(),
           let credentials = Credentials(response) {
            return apply(credentials)
        }

        if let data = ConfigurationAPI.retrieveFromKeychain(key: ConfigurationKeys.evervault.rawValue),
           let cached = try? FrameNetworking.shared.jsonDecoder.decode(
               ConfigurationResponses.GetEvervaultConfigurationResponse.self, from: data
           ),
           let credentials = Credentials(cached) {
            return apply(credentials)
        }

        return false
    }

    private static func apply(_ credentials: Credentials) -> Bool {
        Evervault.shared.configure(teamId: credentials.teamId, appId: credentials.appId)
        FrameNetworking.shared.isEvervaultConfigured = true
        return true
    }

    /// A team/app pair that is actually usable, so empty credentials are treated as a failed
    /// configuration instead of being handed to Evervault as empty strings.
    private struct Credentials {
        let teamId: String
        let appId: String

        init?(_ response: ConfigurationResponses.GetEvervaultConfigurationResponse) {
            guard let teamId = response.teamId, !teamId.isEmpty,
                  let appId = response.appId, !appId.isEmpty else { return nil }
            self.teamId = teamId
            self.appId = appId
        }
    }
}
