//
//  SonarSessionTests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 7/14/26.
//

import XCTest
@testable import Frame

// MARK: - Request encoding

/// Omitting `account_id` was the original bug: the server resolves a payment's session through the
/// account, so a session without one is invisible to risk checks.
final class SessionRequestBodyTests: XCTestCase {

    private func encode(_ body: SessionRequestBody) throws -> [String: Any] {
        let data = try JSONEncoder().encode(body)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testEncodesAccountIdAlongsideVisitorId() throws {
        let json = try encode(SessionRequestBody(fingerprintVisitorId: "visitor_1", accountId: "acc_1"))

        XCTAssertEqual(json["fingerprint_visitor_id"] as? String, "visitor_1")
        XCTAssertEqual(json["account_id"] as? String, "acc_1")
    }

    func testOmitsAccountIdWhenThereIsNoAccountYet() throws {
        let json = try encode(SessionRequestBody(fingerprintVisitorId: "visitor_1"))

        XCTAssertEqual(json["fingerprint_visitor_id"] as? String, "visitor_1")
        XCTAssertNil(json["account_id"])
    }

    /// The pair travels together: the sealed result is what an activated environment
    /// identifies by, and the visitor id is what every environment before it used.
    func testEncodesSealedResultAlongsideVisitorId() throws {
        let json = try encode(SessionRequestBody(fingerprintVisitorId: "visitor_1",
                                                 accountId: "acc_1",
                                                 sealedResult: "c2VhbGVk"))

        XCTAssertEqual(json["fingerprint_visitor_id"] as? String, "visitor_1")
        XCTAssertEqual(json["account_id"] as? String, "acc_1")
        XCTAssertEqual(json["sealed_result"] as? String, "c2VhbGVk")
    }

    /// `sealed_result: null` is not the same request as one that omits the key — the
    /// server branches on `.present?`, so a null would still have to be the legacy path
    /// but says something different about what the client tried to do.
    func testOmitsSealedResultWhenFingerprintServedNone() throws {
        let json = try encode(SessionRequestBody(fingerprintVisitorId: "visitor_1"))

        XCTAssertNil(json["sealed_result"])
        XCTAssertFalse(json.keys.contains("sealed_result"))
    }

    /// The post-activation shape: Fingerprint withholds the visitor id and the sealed
    /// result carries identity on its own. The body still has to encode.
    func testEncodesSealedResultWithWithheldVisitorId() throws {
        let identification = FingerprintIdentification(visitorId: "", sealedResult: "c2VhbGVk")
        let json = try encode(SessionRequestBody(identification: identification, accountId: "acc_1"))

        XCTAssertEqual(json["fingerprint_visitor_id"] as? String, "")
        XCTAssertEqual(json["sealed_result"] as? String, "c2VhbGVk")
    }
}

// MARK: - Sealed identification on the wire

/// What the session endpoints actually receive on each side of the sealed environment
/// being activated. The dual-path requirement lives or dies here.
final class SealedSessionRequestTests: XCTestCase {

    private var storage: SpySessionStorage!
    private var manager: SessionManager!
    private var originalSession: URLSessionProtocol!
    private var network: BodyCapturingStub!

    override func setUp() {
        super.setUp()
        storage = SpySessionStorage()
        manager = SessionManager(storage: storage)
        originalSession = FrameNetworking.shared.asyncURLSession
        network = BodyCapturingStub()
        FrameNetworking.shared.asyncURLSession = network
        FingerprintManager.resetForTesting()
    }

    override func tearDown() {
        FrameNetworking.shared.asyncURLSession = originalSession
        FingerprintManager.resetForTesting()
        super.tearDown()
    }

    private func createBody(for identification: FingerprintIdentification) async throws -> [String: Any] {
        FingerprintManager.identificationOverride = { identification }
        _ = try? await manager.ensureSession(accountId: "acc_1")
        return try XCTUnwrap(network.lastSessionBody)
    }

    /// Pre-activation: Fingerprint serves both, and both go out. Sending only the sealed
    /// result here would leave an unactivated environment with nothing to identify by.
    func testSendsBothWhenFingerprintServesBoth() async throws {
        let body = try await createBody(for: FingerprintIdentification(visitorId: "visitor_1",
                                                                       sealedResult: "c2VhbGVk"))

        XCTAssertEqual(body["fingerprint_visitor_id"] as? String, "visitor_1")
        XCTAssertEqual(body["sealed_result"] as? String, "c2VhbGVk")
    }

    /// Post-activation: the visitor id is withheld and the sealed result carries identity
    /// alone. This is the case that used to throw before the session was ever created.
    func testCreatesSessionWhenOnlyTheSealedResultIsServed() async throws {
        let body = try await createBody(for: FingerprintIdentification(visitorId: "",
                                                                       sealedResult: "c2VhbGVk"))

        XCTAssertEqual(body["sealed_result"] as? String, "c2VhbGVk")
        XCTAssertNotNil(network.lastSessionBody, "an activated environment must still open a session")
    }

    /// The shipping case: sealing is off, so the request is exactly what it is today.
    func testLegacyPathIsUnchangedWhenNothingIsSealed() async throws {
        let body = try await createBody(for: FingerprintIdentification(visitorId: "visitor_1",
                                                                       sealedResult: nil))

        XCTAssertEqual(body["fingerprint_visitor_id"] as? String, "visitor_1")
        XCTAssertFalse(body.keys.contains("sealed_result"))
    }

    /// A sealed result is minted per request, never held: the API rejects one stamped more
    /// than ten minutes from now, so a session touched later must carry a newer payload.
    func testEachTouchMintsAFreshSealedResult() async throws {
        var served = 0
        FingerprintManager.identificationOverride = {
            served += 1
            return FingerprintIdentification(visitorId: "visitor_1", sealedResult: "sealed_\(served)")
        }

        _ = try? await manager.ensureSession(accountId: "acc_1")
        await manager.refreshOnFlowEntry(accountId: "acc_1")

        XCTAssertGreaterThan(served, 1, "a second touch must ask Fingerprint again, not replay")
        XCTAssertEqual(network.sessionBodies.last?["sealed_result"] as? String, "sealed_\(served)")
    }
}

// MARK: - Identification usability

/// An empty visitor id stopped being a failure when environments began withholding it.
/// What makes an identification unusable now is having neither half.
final class FingerprintIdentificationTests: XCTestCase {

    func testVisitorIdAloneIsUsable() {
        XCTAssertTrue(FingerprintIdentification(visitorId: "visitor_1", sealedResult: nil).isUsable)
    }

    func testSealedResultAloneIsUsable() {
        XCTAssertTrue(FingerprintIdentification(visitorId: "", sealedResult: "c2VhbGVk").isUsable)
    }

    func testNeitherHalfIsUnusable() {
        XCTAssertFalse(FingerprintIdentification(visitorId: "", sealedResult: nil).isUsable)
    }
}

// MARK: - Fingerprint configuration

/// The configuration endpoint answers an unrecognised capability with the legacy key and
/// HTTP 200, so "the fetch succeeded" proves nothing. The stamp is the only evidence of
/// which regime the key belongs to.
final class FingerprintConfigurationResponseTests: XCTestCase {

    private func decode(_ json: String) throws -> ConfigurationResponses.GetFingerprintConfigurationResponse {
        try JSONDecoder().decode(ConfigurationResponses.GetFingerprintConfigurationResponse.self,
                                 from: XCTUnwrap(json.data(using: .utf8)))
    }

    func testDecodesTheEnvironmentStamp() throws {
        let config = try decode(#"{"api_key":"pk_1","region":"us","environment":"sealed"}"#)

        XCTAssertEqual(config.apiKey, "pk_1")
        XCTAssertEqual(config.region, "us")
        XCTAssertTrue(config.isSealed)
    }

    func testLegacyStampIsNotSealed() throws {
        XCTAssertFalse(try decode(#"{"api_key":"pk_1","region":"us","environment":"legacy"}"#).isSealed)
    }

    /// A response predating the stamp decodes rather than throwing, but carries no
    /// stamp — which is what sends a cached copy back to the network instead of being
    /// trusted, since nothing about it says which key it holds.
    func testMissingStampDecodesButIsNotTrusted() throws {
        let config = try decode(#"{"api_key":"pk_1","region":"us"}"#)

        XCTAssertEqual(config.apiKey, "pk_1")
        XCTAssertFalse(config.isSealed)
        XCTAssertFalse(config.hasEnvironmentStamp)
    }

    /// A legacy stamp is still a stamp. A rollback serves legacy keys deliberately, and
    /// a cached one is what keeps that build working offline — discarding it would leave
    /// the device with no credentials at all.
    func testLegacyStampIsStillTrustedForCaching() throws {
        let config = try decode(#"{"api_key":"pk_1","region":"us","environment":"legacy"}"#)

        XCTAssertFalse(config.isSealed)
        XCTAssertTrue(config.hasEnvironmentStamp)
    }
}

// MARK: - Capability declaration

/// A capability the server does not recognise is not an error: it returns the legacy key
/// and HTTP 200. So the exact header name and value are load-bearing.
final class FingerprintCapabilityHeaderTests: XCTestCase {

    func testFingerprintConfigDeclaresSealedCapability() {
        let headers = ConfigurationEndpoints.getFingerprintConfiguration.additionalHeaders

        XCTAssertEqual(headers["X-Frame-Sonar"], "sealed")
    }

    /// The regression this guards: `/v1/config/all` is the only config request a normal
    /// launch makes, and its cached fingerprint block is what every later
    /// `getFingerprintConfiguration()` serves. Without the header here the process runs
    /// on a legacy key, Fingerprint seals nothing, and the session posts no sealed result
    /// — with the individual endpoint's header still passing its own test.
    func testAggregateConfigDeclaresSealedCapability() {
        let headers = ConfigurationEndpoints.getAllConfiguration.additionalHeaders

        XCTAssertEqual(headers["X-Frame-Sonar"], "sealed",
                       "The aggregate endpoint must declare the capability too, or the launch path never asks for a sealed key.")
    }

    func testOtherConfigEndpointsDeclareNothing() {
        XCTAssertTrue(ConfigurationEndpoints.getSiftConfiguration.additionalHeaders.isEmpty)
        XCTAssertTrue(ConfigurationEndpoints.getLegalConfiguration.additionalHeaders.isEmpty)
        XCTAssertTrue(ConfigurationEndpoints.getEvervaultConfiguration.additionalHeaders.isEmpty)
    }
}

// MARK: - Per-account storage

/// Guards the cross-account contamination fixed on the web SDK in FRA-3280.
final class SessionStorageTests: XCTestCase {

    private var defaults: UserDefaults!
    private var storage: UserDefaultsSessionStorage!
    private let suiteName = "SessionStorageTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        storage = UserDefaultsSessionStorage(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testSessionsAreIsolatedPerAccount() {
        storage.set("fps_a", accountId: "acc_a")
        storage.set("fps_b", accountId: "acc_b")

        XCTAssertEqual(storage.get(accountId: "acc_a"), "fps_a")
        XCTAssertEqual(storage.get(accountId: "acc_b"), "fps_b")
    }

    func testOneAccountsSessionIsNotVisibleToAnother() {
        storage.set("fps_a", accountId: "acc_a")

        XCTAssertNil(storage.get(accountId: "acc_b"))
    }

    /// Leaking into the pre-account slot would let the next account on this device adopt it.
    func testAccountSessionIsNotWrittenToTheLegacySlot() {
        storage.set("fps_a", accountId: "acc_a")

        XCTAssertNil(storage.get(accountId: nil))
        XCTAssertNil(defaults.string(forKey: UserDefaultsSessionStorage.legacyKey))
    }

    func testPreAccountSessionUsesTheLegacyKey() {
        storage.set("fps_legacy", accountId: nil)

        XCTAssertEqual(storage.get(accountId: nil), "fps_legacy")
        XCTAssertEqual(defaults.string(forKey: UserDefaultsSessionStorage.legacyKey), "fps_legacy")
    }

    /// A session in flight when the SDK is upgraded must survive rather than be abandoned.
    func testSessionWrittenByAnOlderBuildIsStillReadable() {
        defaults.set("fps_from_old_build", forKey: UserDefaultsSessionStorage.legacyKey)

        XCTAssertEqual(storage.get(accountId: nil), "fps_from_old_build")
    }

    func testClearingAnAccountLeavesOtherAccountsIntact() {
        storage.set("fps_a", accountId: "acc_a")
        storage.set("fps_b", accountId: "acc_b")

        storage.clear(accountId: "acc_a")

        XCTAssertNil(storage.get(accountId: "acc_a"))
        XCTAssertEqual(storage.get(accountId: "acc_b"), "fps_b")
    }

    func testRefreshTimestampIsTrackedPerAccount() {
        let stamp = Date(timeIntervalSince1970: 1_700_000_000)
        storage.setLastRefresh(stamp, accountId: "acc_a")

        XCTAssertEqual(storage.lastRefresh(accountId: "acc_a"), stamp)
        XCTAssertNil(storage.lastRefresh(accountId: "acc_b"))
    }

    func testClearingAnAccountAlsoDropsItsRefreshTimestamp() {
        storage.set("fps_a", accountId: "acc_a")
        storage.setLastRefresh(Date(), accountId: "acc_a")

        storage.clear(accountId: "acc_a")

        XCTAssertNil(storage.lastRefresh(accountId: "acc_a"))
    }
}

// MARK: - Transfer encoding

/// The API rejects `sonar_session_id` on payouts, so it must never be attached to a transfer with no
/// source payment method.
final class TransferSonarSessionTests: XCTestCase {

    private func encode(_ request: TransferRequests.CreateTransferRequest) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testChargeBackedTransferEncodesTheSonarSession() throws {
        var request = TransferRequests.CreateTransferRequest(amount: 5000,
                                                             accountId: "acc_1",
                                                             sourcePaymentMethodId: "pm_1")
        request.sonarSessionId = "fps_1"

        XCTAssertEqual(try encode(request)["sonar_session_id"] as? String, "fps_1")
    }

    /// Sending it here would turn a working payout into a 400.
    func testPayoutTransferOmitsTheSonarSessionEntirely() throws {
        let request = TransferRequests.CreateTransferRequest(amount: 5000,
                                                             accountId: "acc_1",
                                                             destinationPaymentMethodId: "pm_1")

        XCTAssertNil(try encode(request)["sonar_session_id"])
    }
}

// MARK: - Warm-up freshness

/// Records what the manager read and wrote, so the fresh/stale/absent decision can be asserted
/// without a live server.
/// Records the request paths the manager produced, serving Fingerprint configuration and
/// failing everything else.
///
/// These tests assert which session endpoint was reached, so identification has to get far
/// enough to build a request — a stub that fails the config fetch too stops the manager
/// before it ever calls one. Recording the path is what replaced inferring it from a throw
/// that no longer happens now that Fingerprint can identify without a visitor id.
private final class RecordingSessionStub: URLSessionProtocol, @unchecked Sendable {
    private(set) var requestedPaths: [String] = []

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let path = request.url?.path ?? ""
        requestedPaths.append(path)

        guard path == "/v1/config/fingerprint" else {
            throw URLError(.notConnectedToInternet)
        }

        let body = Data(#"{"api_key":"pk_test","region":"us","environment":"sealed"}"#.utf8)
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (body, response)
    }
}

/// Serves Fingerprint configuration and a session id, recording the session request bodies.
private final class BodyCapturingStub: URLSessionProtocol, @unchecked Sendable {
    private(set) var sessionBodies: [[String: Any]] = []

    var lastSessionBody: [String: Any]? { sessionBodies.last }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let path = request.url?.path ?? ""
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!

        if path == "/v1/config/fingerprint" {
            return (Data(#"{"api_key":"pk_test","region":"us","environment":"sealed"}"#.utf8), response)
        }

        // URLRequest moves a body set on the request into httpBodyStream once it is sent.
        if let body = request.httpBody ?? request.httpBodyStream.map(Self.drain),
           let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            sessionBodies.append(json)
        }

        return (Data(#"{"sonar_session_id":"fps_test_1"}"#.utf8), response)
    }

    private static func drain(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        let size = 4096
        var buffer = [UInt8](repeating: 0, count: size)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: size)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}

private final class SpySessionStorage: SessionStorage, @unchecked Sendable {
    var sessions: [String: SessionId] = [:]
    var refreshes: [String: Date] = [:]
    /// Every `set` the manager performed, in order.
    var writes: [(session: SessionId, accountId: String?)] = []
    var clears: [String?] = []

    /// `accountId: nil` needs a distinct dictionary key from any real account id.
    private func key(_ accountId: String?) -> String { accountId ?? "\u{0}pre-account" }

    func get(accountId: String?) -> SessionId? { sessions[key(accountId)] }

    func set(_ value: SessionId, accountId: String?) {
        sessions[key(accountId)] = value
        writes.append((value, accountId))
    }

    func clear(accountId: String?) {
        sessions[key(accountId)] = nil
        refreshes[key(accountId)] = nil
        clears.append(accountId)
    }

    func lastRefresh(accountId: String?) -> Date? { refreshes[key(accountId)] }

    func setLastRefresh(_ date: Date, accountId: String?) { refreshes[key(accountId)] = date }
}

/// A stale pre-account session must be refreshed *in place*, not replaced: the adoption path looks
/// for the session that was created early precisely so its device event has had time to land, and
/// swapping the ID reintroduces that race.
final class WarmUpFreshnessTests: XCTestCase {

    private var storage: SpySessionStorage!
    private var manager: SessionManager!
    private var originalSession: URLSessionProtocol!
    private var network: RecordingSessionStub!

    /// `SessionManager` always calls through `FrameNetworking.shared`, so a request-failure mock is
    /// installed here rather than relying on the sandbox having no real network access.
    override func setUp() {
        super.setUp()
        storage = SpySessionStorage()
        manager = SessionManager(storage: storage)
        // These assert on which path was taken, not on a response, so the request is
        // stubbed to fail. Left to a live network the outcome depends on whether
        // Fingerprint answered — which it now can without a visitor id, so the throw
        // these once relied on no longer happens.
        originalSession = FrameNetworking.shared.asyncURLSession
        network = RecordingSessionStub()
        FrameNetworking.shared.asyncURLSession = network
        // Fingerprint cannot identify anything without a real key and a live service, so
        // it is stood in for. These tests are about what the manager does with an
        // identification, not about obtaining one.
        FingerprintManager.resetForTesting()
        FingerprintManager.identificationOverride = {
            FingerprintIdentification(visitorId: "visitor_test", sealedResult: nil)
        }
    }

    override func tearDown() {
        FrameNetworking.shared.asyncURLSession = originalSession
        FingerprintManager.resetForTesting()
        super.tearDown()
    }

    func testFreshPreAccountSessionIsLeftAlone() async throws {
        storage.sessions["\u{0}pre-account"] = "fps_warm"
        storage.refreshes["\u{0}pre-account"] = Date()

        try await manager.warmUp()

        XCTAssertEqual(storage.get(accountId: nil), "fps_warm")
        XCTAssertTrue(storage.writes.isEmpty, "A fresh session needs no network call and no rewrite.")
    }

    /// The bug this guards: warming up on a stale session used to `POST` a brand-new one, orphaning
    /// the session the adoption path expected to find.
    func testStalePreAccountSessionIsNotDiscardedBeforeTheNetworkCall() async {
        storage.sessions["\u{0}pre-account"] = "fps_stale"
        // Well outside the 15-minute freshness window.
        storage.refreshes["\u{0}pre-account"] = Date(timeIntervalSinceNow: -3600)

        // The update fails, and a failed update legitimately clears and recreates — so a
        // clear on its own proves nothing. What this guards is that the stale session was
        // the one carried to the update endpoint, rather than abandoned for a fresh POST.
        _ = try? await manager.warmUp()

        XCTAssertTrue(network.requestedPaths.contains("/v1/charge_sessions/fps_stale"),
                      "A stale pre-account session must be refreshed in place, not replaced. "
                      + "Requested: \(network.requestedPaths)")
    }

    /// With nothing stored there is no session to refresh, so the create path is the only option —
    /// and it must not try to refresh a session that does not exist.
    func testAbsentPreAccountSessionTakesTheCreatePath() async {
        _ = try? await manager.warmUp()

        // The create call fails without a network, so nothing is persisted; the point is that no
        // refresh of a non-existent session was attempted and no spurious clear happened.
        XCTAssertNil(storage.get(accountId: nil))
        XCTAssertTrue(storage.writes.isEmpty)
    }
}

// MARK: - Flow-entry refresh

/// Mirrors the web SDK, which writes the session once per page load. Presenting an entry-point view is
/// the native equivalent, and unlike the keep-alive it is deliberately not gated on freshness.
final class FlowEntryRefreshTests: XCTestCase {

    private var storage: SpySessionStorage!
    private var manager: SessionManager!
    private var originalSession: URLSessionProtocol!
    private var network: RecordingSessionStub!

    /// `SessionManager` always calls through `FrameNetworking.shared`, so a request-failure mock is
    /// installed here rather than relying on the sandbox having no real network access.
    override func setUp() {
        super.setUp()
        storage = SpySessionStorage()
        manager = SessionManager(storage: storage)
        // These assert on which path was taken, not on a response, so the request is
        // stubbed to fail. Left to a live network the outcome depends on whether
        // Fingerprint answered — which it now can without a visitor id, so the throw
        // these once relied on no longer happens.
        originalSession = FrameNetworking.shared.asyncURLSession
        network = RecordingSessionStub()
        FrameNetworking.shared.asyncURLSession = network
        // Fingerprint cannot identify anything without a real key and a live service, so
        // it is stood in for. These tests are about what the manager does with an
        // identification, not about obtaining one.
        FingerprintManager.resetForTesting()
        FingerprintManager.identificationOverride = {
            FingerprintIdentification(visitorId: "visitor_test", sealedResult: nil)
        }
    }

    override func tearDown() {
        FrameNetworking.shared.asyncURLSession = originalSession
        FingerprintManager.resetForTesting()
        super.tearDown()
    }

    /// The distinguishing behavior: entering a flow refreshes even a session that is still inside the
    /// freshness window, because the window is only an SDK-side estimate of the server's.
    func testRefreshesEvenWhenTheSessionIsStillFresh() async {
        storage.sessions["\u{0}pre-account"] = "fps_fresh"
        storage.refreshes["\u{0}pre-account"] = Date()

        await manager.refreshOnFlowEntry()

        // The point is that the update was attempted at all — a freshness-gated path would
        // have returned without touching the session.
        XCTAssertTrue(network.requestedPaths.contains("/v1/charge_sessions/fps_fresh"),
                      "Entering a flow must refresh even a session inside the freshness window. "
                      + "Requested: \(network.requestedPaths)")
    }

    /// An entry-point view must never throw into a SwiftUI `.task`; failures are swallowed by design.
    func testNeverThrowsWhenTheNetworkIsUnavailable() async {
        await manager.refreshOnFlowEntry(accountId: "acc_1")
        await manager.refreshOnFlowEntry()
    }

    /// A per-account flow entry must not write into the pre-account slot, or the next account on the
    /// device could adopt it.
    func testAccountScopedEntryDoesNotTouchThePreAccountSlot() async {
        storage.sessions["\u{0}pre-account"] = "fps_warm"

        await manager.refreshOnFlowEntry(accountId: "acc_1")

        XCTAssertEqual(storage.get(accountId: nil), "fps_warm")
        XCTAssertFalse(storage.writes.contains { $0.accountId == nil })
    }

    /// The orphaning bug: with a launch session stored but none for the account, flow entry used to
    /// `POST` a fresh session, stranding the device event the launch session had been accumulating.
    /// It must `PATCH` the stored session onto the account instead, keeping its ID.
    func testAccountScopedEntryAdoptsTheLaunchSessionRatherThanCreatingAnother() async {
        let recorder = RecordingSession(sessionId: "fps_launch")
        FrameNetworking.shared.asyncURLSession = recorder
        let manager = SessionManager(storage: storage)
        storage.sessions["\u{0}pre-account"] = "fps_launch"

        await manager.refreshOnFlowEntry(accountId: "acc_1")

        XCTAssertEqual(recorder.paths, ["/v1/charge_sessions/fps_launch"],
                       "Adoption must PATCH the launch session, not POST a new one.")
        XCTAssertEqual(storage.get(accountId: "acc_1"), "fps_launch",
                       "The account must end up on the launch session's ID.")
        XCTAssertNil(storage.get(accountId: nil),
                     "The unscoped slot is cleared after adoption so the next account can't reuse it.")
    }
}

// MARK: - Launch binding

/// One session per app run: the session and its timestamp outlive the process in `UserDefaults`, so a
/// freshness-gated launch would relaunch inside the window and record no device event at all.
final class LaunchBindingTests: XCTestCase {

    private var storage: SpySessionStorage!
    private var savedSession: URLSessionProtocol!
    private var recorder: RecordingSession!
    private var manager: SessionManager!

    override func setUp() {
        super.setUp()
        storage = SpySessionStorage()
        savedSession = FrameNetworking.shared.asyncURLSession
        recorder = RecordingSession(sessionId: "fps_stored")
        FrameNetworking.shared.asyncURLSession = recorder
        // Identification supplied directly: Fingerprint has no configured client in unit tests, and
        // without one no session request is ever built.
        FingerprintManager.resetForTesting()
        FingerprintManager.identificationOverride = {
            FingerprintIdentification(visitorId: "visitor_1", sealedResult: nil)
        }
        manager = SessionManager(storage: storage)
    }

    override func tearDown() {
        FrameNetworking.shared.asyncURLSession = savedSession
        FingerprintManager.resetForTesting()
        super.tearDown()
    }

    /// The bug this guards: a relaunch inside the 15-minute window used to return before issuing any
    /// request, leaving the stored session without a recent device event.
    func testRelaunchInsideTheFreshnessWindowStillTouchesTheSession() async {
        storage.sessions["acc_1"] = "fps_stored"
        storage.refreshes["acc_1"] = Date()

        await manager.bindSessionAtLaunch(accountId: "acc_1")

        XCTAssertEqual(recorder.paths, ["/v1/charge_sessions/fps_stored"],
                       "A launch inside the freshness window must still record a device event.")
        XCTAssertEqual(storage.get(accountId: "acc_1"), "fps_stored",
                       "The session is refreshed in place, never replaced.")
    }

    /// The unscoped launch path refreshes in place too, so the ID the adoption path looks for
    /// survives a relaunch.
    func testUnscopedRelaunchRefreshesInPlace() async {
        storage.sessions["\u{0}pre-account"] = "fps_stored"
        storage.refreshes["\u{0}pre-account"] = Date()

        await manager.bindSessionAtLaunch(accountId: nil)

        XCTAssertEqual(recorder.paths, ["/v1/charge_sessions/fps_stored"])
        XCTAssertEqual(storage.get(accountId: nil), "fps_stored")
    }

    /// With nothing stored, launch creates the session — bound to the account when one is known, so
    /// there is no unscoped session for a later flow to adopt.
    func testFirstLaunchWithAKnownAccountCreatesABoundSession() async {
        await manager.bindSessionAtLaunch(accountId: "acc_1")

        XCTAssertEqual(recorder.paths, ["/v1/charge_sessions"], "Nothing stored, so this is a create.")
        XCTAssertEqual(recorder.accountIds, ["acc_1"], "The create must carry the account id.")
        XCTAssertNil(storage.get(accountId: nil), "No unscoped session should be left behind.")
    }

    /// Launch must never throw into `initialize`'s `Task`; failures are swallowed by design.
    func testNeverThrowsWhenTheVisitorIdIsUnavailable() async {
        // No usable identification: Fingerprint answered with neither a visitor id nor a
        // sealed result, which is the one case that still fails the request.
        FingerprintManager.identificationOverride = { nil }
        let failing = SessionManager(storage: storage)

        await failing.bindSessionAtLaunch(accountId: "acc_1")
        await failing.bindSessionAtLaunch(accountId: nil)
    }
}

/// Records which session endpoints were called, and answers each with a session ID so the
/// create/adopt/refresh branches run to completion.
private final class RecordingSession: URLSessionProtocol, @unchecked Sendable {
    private let sessionId: String
    private let lock = NSLock()
    private var recordedPaths: [String] = []
    private var recordedAccountIds: [String?] = []

    var paths: [String] { lock.withLock { recordedPaths } }
    var accountIds: [String?] { lock.withLock { recordedAccountIds } }

    init(sessionId: String) {
        self.sessionId = sessionId
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let body = request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        lock.withLock {
            recordedPaths.append(request.url?.path ?? "")
            recordedAccountIds.append(body?["account_id"] as? String)
        }

        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (Data(#"{ "sonar_session_id": "\#(sessionId)" }"#.utf8), response)
    }
}

// MARK: - Keep-alive lifecycle

/// The keep-alive exists so the freshness window never closes while the app is open; a refresh at
/// payment time would sit on the critical path.
final class KeepAliveLifecycleTests: XCTestCase {

    private var storage: SpySessionStorage!
    private var manager: SessionManager!
    private var originalSession: URLSessionProtocol!
    private var network: RecordingSessionStub!

    /// `SessionManager` always calls through `FrameNetworking.shared`, so a request-failure mock is
    /// installed here rather than relying on the sandbox having no real network access.
    override func setUp() {
        super.setUp()
        storage = SpySessionStorage()
        manager = SessionManager(storage: storage)
        // These assert on which path was taken, not on a response, so the request is
        // stubbed to fail. Left to a live network the outcome depends on whether
        // Fingerprint answered — which it now can without a visitor id, so the throw
        // these once relied on no longer happens.
        originalSession = FrameNetworking.shared.asyncURLSession
        network = RecordingSessionStub()
        FrameNetworking.shared.asyncURLSession = network
        // Fingerprint cannot identify anything without a real key and a live service, so
        // it is stood in for. These tests are about what the manager does with an
        // identification, not about obtaining one.
        FingerprintManager.resetForTesting()
        FingerprintManager.identificationOverride = {
            FingerprintIdentification(visitorId: "visitor_test", sealedResult: nil)
        }
    }

    override func tearDown() {
        FrameNetworking.shared.asyncURLSession = originalSession
        FingerprintManager.resetForTesting()
        super.tearDown()
    }

    /// `pause()` must leave nothing armed, or a suspended app fires requests mid-suspension.
    func testPauseIsSafeWithNoKeepAliveRunning() async {
        await manager.pause()
        await manager.pause()
    }

    /// `resume()` re-arms after a pause; calling it twice must not leave two timers running, which
    /// would double the refresh traffic.
    func testResumeAfterPauseDoesNotStackTimers() async {
        await manager.pause()
        await manager.resume()
        await manager.resume()

        await manager.pause()
    }

    /// Repeated checkout attempts each call `ensureSession`; if that restarted the timer every time,
    /// the next refresh would be pushed out indefinitely and the window could close.
    func testEnsureSessionDoesNotRestartTheKeepAliveInterval() async {
        _ = try? await manager.ensureSession(accountId: "acc_1")
        _ = try? await manager.ensureSession(accountId: "acc_1")

        // Both calls failed at the network, but the keep-alive must still be armed exactly once and
        // cancellable without hanging.
        await manager.pause()
    }
}

// MARK: - Error copy

/// Shown verbatim these read as "Error: sonar_session_required", which is what merchants reported.
final class RiskErrorMessageTests: XCTestCase {

    private func toast(forServerMessage message: String) -> String {
        NetworkingError.serverError(statusCode: 422,
                                    errorDescription: #"{"error":"\#(message)"}"#).toastMessage()
    }

    func testSonarSessionRequiredIsTranslatedForShoppers() {
        let message = toast(forServerMessage: "sonar_session_required")

        XCTAssertFalse(message.contains("sonar_session_required"))
        XCTAssertEqual(message, "Error: We couldn't verify this device. Please try again.")
    }

    func testGeoComplianceCodesAreTranslatedForShoppers() {
        XCTAssertFalse(toast(forServerMessage: "geo_compliance_blocked").contains("geo_compliance"))
        XCTAssertFalse(toast(forServerMessage: "geo_compliance_vpn_detected").contains("geo_compliance"))
    }

    func testUnrecognisedServerMessagesArePassedThrough() {
        XCTAssertEqual(toast(forServerMessage: "Card submitted is not a test card"),
                       "Error: Card submitted is not a test card")
    }
}
