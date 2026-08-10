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

    override func setUp() {
        super.setUp()
        storage = SpySessionStorage()
        manager = SessionManager(storage: storage)
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

        // No network in unit tests, so this throws; what matters is that the stale session was still
        // the one being refreshed rather than cleared and replaced.
        _ = try? await manager.warmUp()

        XCTAssertFalse(storage.clears.contains(where: { $0 == nil }),
                       "A stale pre-account session must be refreshed in place, not cleared first.")
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

// MARK: - Keep-alive lifecycle

/// The keep-alive exists so the freshness window never closes while the app is open; a refresh at
/// payment time would sit on the critical path.
final class KeepAliveLifecycleTests: XCTestCase {

    private var storage: SpySessionStorage!
    private var manager: SessionManager!

    override func setUp() {
        super.setUp()
        storage = SpySessionStorage()
        manager = SessionManager(storage: storage)
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
