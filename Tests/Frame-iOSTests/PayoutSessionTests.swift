//
//  PayoutSessionTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame

final class PayoutSessionTests: XCTestCase {
    func testClientSecretExpires() {
        let live = FramePayoutClientSecret(
            clientSecret: "pyt_sess_live",
            expiresAt: Date(timeIntervalSinceNow: 1_800),
            amountCents: 5_000
        )
        XCTAssertFalse(live.isExpired)
        XCTAssertEqual(live.amountCurrency, "usd")

        let dead = FramePayoutClientSecret(
            clientSecret: "pyt_sess_old",
            expiresAt: Date(timeIntervalSince1970: 0),
            amountCents: 5_000,
            amountCurrency: "usd"
        )
        XCTAssertTrue(dead.isExpired)
    }

    func testDecodesSlimPayoutAccount() {
        let data = Data("""
        {"id":"acc_1","object":"account","payout_payment_method_id":"pm_bank"}
        """.utf8)
        let account = decodeAccountResource(data)
        XCTAssertEqual(account?.id, "acc_1")
        XCTAssertEqual(account?.payoutPaymentMethodId, "pm_bank")
    }

    func testDecodesStrippedPaymentMethodList() {
        let data = Data("""
        {"data":[{"id":"pm_1","object":"payment_method","type":"ach","status":"active","ach":{"account_type":"checking","last_four":"6789"}}]}
        """.utf8)
        let methods = decodeSessionPaymentMethods(data)
        XCTAssertEqual(methods?.map(\.id), ["pm_1"])
        XCTAssertEqual(methods?.first?.ach?.lastFour, "6789")
        XCTAssertNil(methods?.first?.card)
    }

    func testBeginOnboardingSessionAcceptsPayoutSessionToken() async throws {
        FrameNetworking.shared.initialize(publishableKey: "pk_test_123", secretKey: "sk_test_456")
        let session = HeaderCapturingAsyncSession()
        FrameNetworking.shared.asyncURLSession = session
        FrameNetworking.shared.beginOnboardingSession(clientSecret: "pyt_sess_live")
        defer {
            FrameNetworking.shared.endOnboardingSession()
            FrameNetworking.shared.asyncURLSession = URLSession.shared
        }

        let endpoint = MockFrameEndpoints(endpointURL: "/v1/accounts/acc_1/elect_payout_method", httpMethod: .POST, queryItems: nil)
        _ = try await FrameNetworking.shared.performDataTask(endpoint: endpoint)

        XCTAssertEqual(
            session.authorizationHeader(forPath: "/v1/accounts/acc_1/elect_payout_method"),
            "Bearer pyt_sess_live"
        )
    }
}
