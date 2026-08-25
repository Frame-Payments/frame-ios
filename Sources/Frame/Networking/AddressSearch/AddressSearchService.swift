//
//  AddressSearchService.swift
//  Frame-iOS
//

import Foundation

/// Errors raised while searching for an address.
///
/// Autocomplete is an accelerator rather than a gate, so callers are expected to fall back to
/// manual entry on any of these rather than surfacing them to the user.
enum AddressSearchError: Error {
    /// No Mapbox token is available from either the Frame API or the keychain cache.
    case unavailable
    /// Mapbox rejected the request or the response could not be decoded.
    case requestFailed
}

/// Looks up addresses through the Mapbox Search Box API.
///
/// The access token is served by Frame's configuration API rather than embedded in the SDK, so it
/// can be rotated without a release. Requests go straight to Mapbox: `FrameNetworking` builds
/// every URL against Frame's own host, so it cannot reach a third-party one.
actor AddressSearchService {
    static let shared = AddressSearchService()

    private let session: URLSessionProtocol
    private let tokenProvider: @Sendable () async -> String?
    private var cachedToken: String?

    /// Groups a sequence of keystrokes with the retrieve that ends it, which is how Mapbox bills a
    /// search. A fresh token per session would bill every keystroke as its own lookup.
    private var sessionToken = UUID().uuidString

    private let decoder = JSONDecoder()

    init(
        session: URLSessionProtocol = URLSession.shared,
        tokenProvider: (@Sendable () async -> String?)? = nil
    ) {
        self.session = session
        self.tokenProvider = tokenProvider ?? { await AddressSearchService.fetchToken() }
    }

    /// Fetches the Mapbox token from the Frame API, falling back to the keychain-cached copy when
    /// the network request is unavailable.
    private static func fetchToken() async -> String? {
        if let response = try? await ConfigurationAPI.getMapboxConfiguration(),
           let token = response.accessToken, !token.isEmpty {
            return token
        }

        if let data = ConfigurationAPI.retrieveFromKeychain(key: ConfigurationKeys.mapbox.rawValue),
           let cached = try? FrameNetworking.shared.jsonDecoder.decode(
               ConfigurationResponses.GetMapboxConfigurationResponse.self, from: data
           ),
           let token = cached.accessToken, !token.isEmpty {
            return token
        }

        return nil
    }

    private func token() async throws -> String {
        if let cachedToken { return cachedToken }

        guard let fetched = await tokenProvider() else { throw AddressSearchError.unavailable }

        cachedToken = fetched
        return fetched
    }

    /// Returns the addresses matching a partial query, restricted to one country.
    ///
    /// - Parameters:
    ///   - query: What the user has typed so far.
    ///   - countryCode: ISO 3166-1 alpha-2 code the results are limited to, so a checkout locked
    ///     to one country does not surface addresses from another.
    func suggest(query: String, countryCode: String?) async throws -> [AddressSuggestion] {
        var components = URLComponents(string: "https://api.mapbox.com/search/searchbox/v1/suggest")
        var items = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "session_token", value: sessionToken),
            URLQueryItem(name: "types", value: "address"),
            URLQueryItem(name: "access_token", value: try await token())
        ]
        if let countryCode, !countryCode.isEmpty {
            items.append(URLQueryItem(name: "country", value: countryCode.lowercased()))
        }
        components?.queryItems = items

        guard let url = components?.url else { throw AddressSearchError.requestFailed }

        let decoded: MapboxSearchResponses.SuggestResponse = try await perform(url: url)
        return decoded.suggestions.map {
            AddressSuggestion(id: $0.mapboxId, title: $0.name, subtitle: $0.placeFormatted ?? "")
        }
    }

    /// Resolves a suggestion into a full address.
    ///
    /// Ends the billing session: the next `suggest` starts a new one.
    func retrieve(suggestion: AddressSuggestion) async throws -> FrameObjects.BillingAddress {
        var components = URLComponents(
            string: "https://api.mapbox.com/search/searchbox/v1/retrieve/\(suggestion.id)"
        )
        components?.queryItems = [
            URLQueryItem(name: "session_token", value: sessionToken),
            URLQueryItem(name: "access_token", value: try await token())
        ]

        guard let url = components?.url else { throw AddressSearchError.requestFailed }

        let decoded: MapboxSearchResponses.RetrieveResponse = try await perform(url: url)
        guard let feature = decoded.features.first else { throw AddressSearchError.requestFailed }

        sessionToken = UUID().uuidString
        return AddressSuggestionMapper.billingAddress(from: feature)
    }

    private func perform<T: Decodable>(url: URL) async throws -> T {
        do {
            let (data, response) = try await session.data(for: URLRequest(url: url))

            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                // A rejected token is worth dropping: the next call refetches rather than
                // repeating a request that cannot succeed.
                if http.statusCode == 401 || http.statusCode == 403 { cachedToken = nil }
                throw AddressSearchError.requestFailed
            }

            return try decoder.decode(T.self, from: data)
        } catch let error as AddressSearchError {
            throw error
        } catch {
            throw AddressSearchError.requestFailed
        }
    }
}
