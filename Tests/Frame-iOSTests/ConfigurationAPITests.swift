//
//  ConfigurationAPITests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/26/26.
//

import XCTest
@testable import Frame

final class ConfigurationAPITests: XCTestCase {
    private let session = MockURLAsyncSession(
        data: nil,
        response: HTTPURLResponse(
            url: URL(string: "https://api.framepayments.com/v1/config/all")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ),
        error: nil
    )

    private let allKeys: [ConfigurationKeys] = [.evervault, .fingerprint, .legal, .mapbox, .sift]
    private var savedStore: ConfigurationStore?
    private var savedSession: URLSessionProtocol?

    /// Both the config store and the URL session are process-wide, so each is swapped for a test
    /// double and restored: real keychain writes would leak cached credentials into suites that
    /// expect the network to be unavailable.
    override func setUp() {
        super.setUp()
        savedStore = ConfigurationAPI.store
        ConfigurationAPI.store = InMemoryConfigurationStore()
        savedSession = FrameNetworking.shared.asyncURLSession
        FrameNetworking.shared.asyncURLSession = session
    }

    override func tearDown() {
        if let savedStore {
            ConfigurationAPI.store = savedStore
        }
        savedStore = nil
        if let savedSession {
            FrameNetworking.shared.asyncURLSession = savedSession
        }
        savedSession = nil
        super.tearDown()
    }

    private func cached<T: Decodable>(_ type: T.Type, _ key: ConfigurationKeys) -> T? {
        guard let data = ConfigurationAPI.retrieveFromKeychain(key: key.rawValue) else { return nil }
        return try? FrameNetworking.shared.jsonDecoder.decode(type, from: data)
    }

    func testDecodesEveryBlockAndCachesEach() async throws {
        session.data = Data("""
        {
          "evervault": { "app_id": "app_123", "team_id": "team_123" },
          "fingerprint": { "environment": "legacy", "api_key": "fp_key", "region": "eu" },
          "legal": {
            "privacy_url": "https://example.com/privacy",
            "terms_url": "https://example.com/terms",
            "platform_agreement_url": "https://example.com/platform",
            "cbc_terms_and_conditions": "https://example.com/cbc"
          },
          "mapbox": { "access_token": "pk.token", "expires_at": null },
          "sift": { "account_id": "sift_acct", "beacon_key": "sift_beacon" }
        }
        """.utf8)

        let response = try await ConfigurationAPI.getAllConfiguration()

        // Every block must be non-nil: `@Lenient` on a block property would silently null all five.
        XCTAssertEqual(response?.evervault?.appId, "app_123")
        XCTAssertEqual(response?.fingerprint?.apiKey, "fp_key")
        XCTAssertEqual(response?.legal?.termsUrl, "https://example.com/terms")
        XCTAssertEqual(response?.mapbox?.accessToken, "pk.token")
        XCTAssertEqual(response?.sift?.beaconKey, "sift_beacon")

        XCTAssertEqual(cached(ConfigurationResponses.GetEvervaultConfigurationResponse.self, .evervault)?.teamId, "team_123")
        XCTAssertEqual(cached(ConfigurationResponses.GetFingerprintConfigurationResponse.self, .fingerprint)?.region, "eu")
        XCTAssertEqual(cached(ConfigurationResponses.GetLegalConfigurationResponse.self, .legal)?.privacyUrl, "https://example.com/privacy")
        XCTAssertEqual(cached(ConfigurationResponses.GetMapboxConfigurationResponse.self, .mapbox)?.accessToken, "pk.token")
        XCTAssertEqual(cached(ConfigurationResponses.GetSiftConfigurationResponse.self, .sift)?.accountId, "sift_acct")
    }

    /// The API omits a block whose backing service failed, which must leave the cached copy intact
    /// rather than clear it.
    func testOmittedBlockLeavesCachedValueIntact() async throws {
        session.data = Data("""
        { "sift": { "account_id": "first_acct", "beacon_key": "first_beacon" } }
        """.utf8)
        _ = try await ConfigurationAPI.getAllConfiguration()
        XCTAssertEqual(cached(ConfigurationResponses.GetSiftConfigurationResponse.self, .sift)?.accountId, "first_acct")

        session.data = Data("""
        { "legal": { "privacy_url": "https://example.com/privacy" } }
        """.utf8)
        let response = try await ConfigurationAPI.getAllConfiguration()

        XCTAssertNil(response?.sift)
        XCTAssertEqual(cached(ConfigurationResponses.GetSiftConfigurationResponse.self, .sift)?.accountId, "first_acct")
        XCTAssertEqual(cached(ConfigurationResponses.GetLegalConfigurationResponse.self, .legal)?.privacyUrl, "https://example.com/privacy")
    }

    func testMalformedLeafFieldDoesNotDiscardSiblings() async throws {
        session.data = Data("""
        {
          "evervault": { "app_id": 42, "team_id": "team_123" },
          "sift": { "account_id": "sift_acct", "beacon_key": "sift_beacon" }
        }
        """.utf8)

        let response = try await ConfigurationAPI.getAllConfiguration()

        XCTAssertNotNil(response?.evervault)
        XCTAssertNil(response?.evervault?.appId)
        XCTAssertEqual(response?.evervault?.teamId, "team_123")
        XCTAssertEqual(response?.sift?.accountId, "sift_acct")
    }

    func testEmptyPayloadDecodesAndCachesNothing() async throws {
        session.data = Data("{}".utf8)

        let response = try await ConfigurationAPI.getAllConfiguration()

        XCTAssertNotNil(response)
        XCTAssertNil(response?.evervault)
        XCTAssertNil(response?.sift)
        allKeys.forEach { XCTAssertNil(ConfigurationAPI.retrieveFromKeychain(key: $0.rawValue)) }
    }

    func testMalformedPayloadReturnsNil() async throws {
        session.data = Data("[]".utf8)

        let response = try await ConfigurationAPI.getAllConfiguration()

        XCTAssertNil(response)
    }
}

/// An in-memory stand-in for the keychain, so tests never touch device-wide state.
private final class InMemoryConfigurationStore: ConfigurationStore, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    func data(forKey key: String) -> Data? {
        lock.withLock { storage[key] }
    }

    func set(_ data: Data, forKey key: String) {
        lock.withLock { storage[key] = data }
    }

    func remove(forKey key: String) {
        lock.withLock { storage[key] = nil }
    }
}
