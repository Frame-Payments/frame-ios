//
//  SonarSessionTests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 7/14/26.
//

import XCTest
@testable import Frame

// MARK: - Request encoding

/// The server resolves a payment's Sonar session through the account, so a session created without
/// an `account_id` is invisible to risk checks and the payment is rejected with
/// `sonar_session_required`. Omitting the field was the original bug.
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

/// Sessions are keyed per account so one account's session can never be adopted by the next account
/// on the same device — the cross-account contamination fixed on the web SDK in FRA-3280.
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

    /// The A→B regression: account B must never read account A's session.
    func testOneAccountsSessionIsNotVisibleToAnother() {
        storage.set("fps_a", accountId: "acc_a")

        XCTAssertNil(storage.get(accountId: "acc_b"))
    }

    /// A session stored for an account must not leak into the pre-account slot, or the next account
    /// on this device would adopt it.
    func testAccountSessionIsNotWrittenToTheLegacySlot() {
        storage.set("fps_a", accountId: "acc_a")

        XCTAssertNil(storage.get(accountId: nil))
        XCTAssertNil(defaults.string(forKey: UserDefaultsSessionStorage.legacyKey))
    }

    /// A session created before an account was known lives in the legacy slot, which is what makes
    /// it adoptable later.
    func testPreAccountSessionUsesTheLegacyKey() {
        storage.set("fps_legacy", accountId: nil)

        XCTAssertEqual(storage.get(accountId: nil), "fps_legacy")
        XCTAssertEqual(defaults.string(forKey: UserDefaultsSessionStorage.legacyKey), "fps_legacy")
    }

    /// A session persisted by an older SDK build must still be readable after upgrade, so an
    /// in-flight session survives rather than being silently abandoned.
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

/// The API accepts `sonar_session_id` only on charge-backed transfers and rejects it on payouts, so
/// the field must never be attached to a transfer that has no source payment method.
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

    /// Sending the field on a payout would turn a working transfer into a 400.
    func testPayoutTransferOmitsTheSonarSessionEntirely() throws {
        let request = TransferRequests.CreateTransferRequest(amount: 5000,
                                                             accountId: "acc_1",
                                                             destinationPaymentMethodId: "pm_1")

        XCTAssertNil(try encode(request)["sonar_session_id"])
    }
}

// MARK: - Error copy

/// The server reports these rejections as bare codes; shown verbatim they read as
/// "Error: sonar_session_required", which is what merchants reported.
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

    /// Server messages that are already human must be passed through untouched.
    func testUnrecognisedServerMessagesArePassedThrough() {
        XCTAssertEqual(toast(forServerMessage: "Card submitted is not a test card"),
                       "Error: Card submitted is not a test card")
    }
}
