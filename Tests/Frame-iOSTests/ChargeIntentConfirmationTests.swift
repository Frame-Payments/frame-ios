//
//  ChargeIntentConfirmationTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame

/// Reports scripted outcomes and records how the challenge was driven.
private final class StubChallengePresenter: FrameThreeDSecureChallengePresenting, @unchecked Sendable {
    private let lock = NSLock()
    private var _presentCount = 0
    private var _lastSource: String?
    private let results: [FrameThreeDSecureChallengeResult]

    /// One result per presentation, in order; the last repeats.
    init(results: [FrameThreeDSecureChallengeResult]) {
        self.results = results
    }

    var presentCount: Int { lock.withLock { _presentCount } }
    var lastSource: String? { lock.withLock { _lastSource } }

    func presentChallenge(_ challenge: FrameObjects.UseFrameSDK,
                          for intent: FrameObjects.ChargeIntent) async -> FrameThreeDSecureChallengeResult {
        lock.withLock {
            _lastSource = challenge.source
            let result = results[min(_presentCount, results.count - 1)]
            _presentCount += 1
            return result
        }
    }
}

/// Counts reads and waits, so the timing contract is assertable without real seconds.
private final class PollRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _loadCount = 0
    private var _sleeps: [Duration] = []

    var loadCount: Int { lock.withLock { _loadCount } }
    var sleeps: [Duration] { lock.withLock { _sleeps } }

    func recordLoad() -> Int { lock.withLock { _loadCount += 1; return _loadCount } }
    func recordSleep(_ duration: Duration) { lock.withLock { _sleeps.append(duration) } }
}

final class ChargeIntentConfirmationTests: XCTestCase {

    private static let secret = "ci_f7d3af2f-1b2c-4d5e-8a9b-0c1d2e3f4a5b_secret_sk_token"
    private static let intentUUID = "f7d3af2f-1b2c-4d5e-8a9b-0c1d2e3f4a5b"

    private func intent(status: FrameObjects.ChargeIntentStatus,
                        nextAction: FrameObjects.NextAction? = nil,
                        latestCharge: FrameObjects.LatestCharge? = nil) -> FrameObjects.ChargeIntent {
        FrameObjects.ChargeIntent(id: Self.intentUUID,
                                  currency: "USD",
                                  latestCharge: latestCharge,
                                  shipping: FrameObjects.BillingAddress(postalCode: "94102"),
                                  status: status,
                                  authorizationMode: .automatic,
                                  object: "charge_intent",
                                  amount: 200,
                                  created: 0,
                                  livemode: false,
                                  nextAction: nextAction)
    }

    private var threeDSecureAction: FrameObjects.NextAction {
        FrameObjects.NextAction(type: "use_frame_sdk",
                                useFrameSDK: FrameObjects.UseFrameSDK(source: "sess_abc",
                                                                      directoryServerName: "visa"))
    }

    // MARK: - Client secret parsing

    /// A URL built from the unstripped secret 404s.
    func testClientSecretYieldsBareChargeIntentID() throws {
        let parsed = try ChargeIntentClientSecret(Self.secret)

        XCTAssertEqual(parsed.chargeIntentID, Self.intentUUID)
        XCTAssertFalse(parsed.chargeIntentID.hasPrefix("ci_"))
        XCTAssertFalse(parsed.chargeIntentID.contains("_secret_"))
        XCTAssertEqual(parsed.value, Self.secret)
    }

    /// Matches the browser SDK: no marker means the whole string is the id.
    func testClientSecretWithoutMarkerUsesWholeString() throws {
        let parsed = try ChargeIntentClientSecret("ci_\(Self.intentUUID)")
        XCTAssertEqual(parsed.chargeIntentID, Self.intentUUID)
    }

    /// A wrong-resource secret fails here, not as a confusing 401 later.
    func testNonChargeIntentSecretIsRejected() {
        for bad in ["pm_123_secret_x", "", "ci_", "secret_only"] {
            XCTAssertThrowsError(try ChargeIntentClientSecret(bad)) { error in
                XCTAssertEqual(error as? FrameChargeIntentError, .invalidClientSecret)
            }
        }
    }

    func testConfirmRejectsInvalidClientSecretBeforeAnyRequest() async {
        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: nil,
            confirmIntent: { _, _ in XCTFail("should not confirm"); return nil },
            loadIntent: { _, _ in _ = recorder.recordLoad(); return nil },
            sleep: { _ in })

        do {
            _ = try await confirmation.confirm(clientSecret: "pi_123_secret_abc")
            XCTFail("expected a throw")
        } catch {
            XCTAssertEqual(error as? FrameChargeIntentError, .invalidClientSecret)
        }
        XCTAssertEqual(recorder.loadCount, 0)
    }

    // MARK: - Terminal statuses short-circuit

    /// A charge that settles on confirm never polls.
    func testSucceededOnConfirmSkipsPolling() async throws {
        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: nil,
            confirmIntent: { id, _ in
                XCTAssertEqual(id, Self.intentUUID)
                return self.intent(status: .succeeded)
            },
            loadIntent: { _, _ in _ = recorder.recordLoad(); return nil },
            sleep: { recorder.recordSleep($0) })

        let outcome = try await confirmation.confirm(clientSecret: Self.secret)

        guard case .succeeded = outcome else { return XCTFail("expected success, got \(outcome)") }
        XCTAssertEqual(recorder.loadCount, 0)
        XCTAssertTrue(recorder.sleeps.isEmpty)
    }

    /// Treating `requires_capture` as pending would make authorize-only merchants time out.
    func testRequiresCaptureIsTerminalSuccess() async throws {
        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: nil,
            confirmIntent: { _, _ in self.intent(status: .requiresCapture) },
            loadIntent: { _, _ in _ = recorder.recordLoad(); return nil },
            sleep: { recorder.recordSleep($0) })

        let outcome = try await confirmation.confirm(clientSecret: Self.secret)

        guard case .succeeded = outcome else { return XCTFail("expected success, got \(outcome)") }
        XCTAssertEqual(recorder.loadCount, 0, "requires_capture must not be polled")
    }

    /// The decline reason comes from `latest_charge`.
    func testFailedConfirmCarriesDeclineReason() async throws {
        let charge = try JSONDecoder().decode(FrameObjects.LatestCharge.self, from: Data("""
        {
          "id": "ch_1", "currency": "USD", "amount": 200, "amount_captured": 0,
          "amount_refunded": 0, "created": 0, "updated": 0, "livemode": false,
          "captured": false, "disputed": false, "refunded": false,
          "charge_intent": "\(Self.intentUUID)",
          "failure_code": "card_declined",
          "failure_message": "Your card was declined."
        }
        """.utf8))

        let confirmation = ChargeIntentConfirmation(
            challengePresenter: nil,
            confirmIntent: { _, _ in self.intent(status: .failed, latestCharge: charge) },
            loadIntent: { _, _ in nil },
            sleep: { _ in })

        let outcome = try await confirmation.confirm(clientSecret: Self.secret)

        guard case .failed(_, let reason) = outcome else { return XCTFail("expected failure") }
        XCTAssertEqual(reason?.code, "card_declined")
        XCTAssertEqual(reason?.message, "Your card was declined.")
    }

    /// A terminal `failed` with no `latest_charge` is a real response, not a crash.
    func testFailedWithoutLatestChargeHasNoReason() async throws {
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: nil,
            confirmIntent: { _, _ in self.intent(status: .failed) },
            loadIntent: { _, _ in nil },
            sleep: { _ in })

        let outcome = try await confirmation.confirm(clientSecret: Self.secret)

        guard case .failed(_, let reason) = outcome else { return XCTFail("expected failure") }
        XCTAssertNil(reason)
    }

    // MARK: - 3D Secure challenge

    /// A completed challenge is a UI signal; the verdict comes from the API.
    func testCompletedChallengeThenPollsForVerdict() async throws {
        let presenter = StubChallengePresenter(results: [.completed])
        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: presenter,
            confirmIntent: { _, _ in self.intent(status: .requiresThreeDSecure, nextAction: self.threeDSecureAction) },
            loadIntent: { _, _ in
                _ = recorder.recordLoad()
                return self.intent(status: .succeeded)
            },
            sleep: { recorder.recordSleep($0) })

        let outcome = try await confirmation.confirm(clientSecret: Self.secret)

        guard case .succeeded = outcome else { return XCTFail("expected success, got \(outcome)") }
        XCTAssertEqual(presenter.presentCount, 1)
        XCTAssertEqual(presenter.lastSource, "sess_abc")
        XCTAssertEqual(recorder.loadCount, 1)
    }

    /// A failed challenge polls like a completed one: it is not itself the verdict.
    func testFailedChallengeAlsoPolls() async throws {
        let presenter = StubChallengePresenter(results: [.failed])
        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: presenter,
            confirmIntent: { _, _ in self.intent(status: .requiresThreeDSecure, nextAction: self.threeDSecureAction) },
            loadIntent: { _, _ in
                _ = recorder.recordLoad()
                return self.intent(status: .failed)
            },
            sleep: { recorder.recordSleep($0) })

        let outcome = try await confirmation.confirm(clientSecret: Self.secret)

        guard case .failed = outcome else { return XCTFail("expected failure, got \(outcome)") }
        XCTAssertEqual(presenter.presentCount, 1)
        XCTAssertEqual(recorder.loadCount, 1, "a failed challenge must still be polled")
    }

    /// A challenge that never ran throws, unlike one the cardholder failed.
    func testUnavailableChallengeThrowsWithoutPolling() async {
        let presenter = StubChallengePresenter(results: [.unavailable])
        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: presenter,
            confirmIntent: { _, _ in self.intent(status: .requiresThreeDSecure, nextAction: self.threeDSecureAction) },
            loadIntent: { _, _ in _ = recorder.recordLoad(); return nil },
            sleep: { recorder.recordSleep($0) })

        do {
            _ = try await confirmation.confirm(clientSecret: Self.secret)
            XCTFail("expected a throw")
        } catch {
            XCTAssertEqual(error as? FrameChargeIntentError, .threeDSecureUnavailable(underlying: nil))
        }
        XCTAssertEqual(presenter.presentCount, 1)
        XCTAssertEqual(recorder.loadCount, 0)
    }

    /// `requires_3d_secure` with no session is unactionable rather than an empty challenge.
    func testRequiresThreeDSecureWithoutChallengeThrows() async {
        let presenter = StubChallengePresenter(results: [.completed])
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: presenter,
            confirmIntent: { _, _ in self.intent(status: .requiresThreeDSecure) },
            loadIntent: { _, _ in nil },
            sleep: { _ in })

        do {
            _ = try await confirmation.confirm(clientSecret: Self.secret)
            XCTFail("expected a throw")
        } catch {
            XCTAssertEqual(error as? FrameChargeIntentError, .missingThreeDSecureChallenge)
        }
        XCTAssertEqual(presenter.presentCount, 0)
    }

    /// The status alone can be set without a challenge session having been produced.
    func testRequiresThreeDSecureChallengeNeedsBothStatusAndAction() {
        XCTAssertTrue(intent(status: .requiresThreeDSecure, nextAction: threeDSecureAction).requiresThreeDSecureChallenge)
        XCTAssertFalse(intent(status: .requiresThreeDSecure).requiresThreeDSecureChallenge)
        XCTAssertFalse(intent(status: .pending, nextAction: threeDSecureAction).requiresThreeDSecureChallenge)
    }

    /// A continuation resumed twice traps; a redirect racing a dismissal is that case.
    func testDoubleReportedChallengeResolvesOnce() async throws {
        /// Reports twice, as a racing teardown would.
        final class DoubleReportingPresenter: FrameThreeDSecureChallengePresenting, @unchecked Sendable {
            func presentChallenge(_ challenge: FrameObjects.UseFrameSDK,
                                  for intent: FrameObjects.ChargeIntent) async -> FrameThreeDSecureChallengeResult {
                await withCheckedContinuation { continuation in
                    let box = OnceBox(continuation)
                    box.resume(with: .completed)
                    box.resume(with: .failed)
                }
            }
        }

        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: DoubleReportingPresenter(),
            polling: .init(maxAttempts: 3, interval: .seconds(1)),
            confirmIntent: { _, _ in self.intent(status: .requiresThreeDSecure, nextAction: self.threeDSecureAction) },
            loadIntent: { _, _ in
                _ = recorder.recordLoad()
                return self.intent(status: .succeeded)
            },
            sleep: { recorder.recordSleep($0) })

        let outcome = try await confirmation.confirm(clientSecret: Self.secret)

        guard case .succeeded = outcome else { return XCTFail("expected success, got \(outcome)") }
        XCTAssertEqual(recorder.loadCount, 1, "the challenge must drive exactly one polling run")
    }

    /// A zero budget must still read once rather than trap on an empty range.
    func testZeroAttemptBudgetStillReadsOnce() async throws {
        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: nil,
            polling: .init(maxAttempts: 0, interval: .seconds(1)),
            confirmIntent: { _, _ in self.intent(status: .pending) },
            loadIntent: { _, _ in
                _ = recorder.recordLoad()
                return self.intent(status: .succeeded)
            },
            sleep: { recorder.recordSleep($0) })

        let outcome = try await confirmation.confirm(clientSecret: Self.secret)

        guard case .succeeded = outcome else { return XCTFail("expected success") }
        XCTAssertEqual(recorder.loadCount, 1)
    }

    // MARK: - Polling

    /// The lead-in precedes the first read, so the budget spans the full window.
    func testPollingSleepsBeforeFirstReadAndBetweenReads() async throws {
        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: nil,
            polling: .init(maxAttempts: 3, interval: .seconds(1)),
            confirmIntent: { _, _ in self.intent(status: .pending) },
            loadIntent: { _, _ in
                // Terminal on the second read, so one inter-read delay is observable.
                recorder.recordLoad() == 2 ? self.intent(status: .succeeded) : self.intent(status: .pending)
            },
            sleep: { recorder.recordSleep($0) })

        let outcome = try await confirmation.confirm(clientSecret: Self.secret)

        guard case .succeeded = outcome else { return XCTFail("expected success") }
        XCTAssertEqual(recorder.loadCount, 2)
        XCTAssertEqual(recorder.sleeps, [.seconds(1), .seconds(1)],
                       "one lead-in delay plus one after the non-terminal read")
    }

    /// Exhausting the budget is returned, not thrown: the charge may still settle.
    func testExhaustedBudgetReturnsTimedOut() async throws {
        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: StubChallengePresenter(results: [.completed]),
            polling: .init(maxAttempts: 10, interval: .seconds(1)),
            confirmIntent: { _, _ in self.intent(status: .requiresThreeDSecure, nextAction: self.threeDSecureAction) },
            loadIntent: { _, _ in
                _ = recorder.recordLoad()
                return self.intent(status: .pending)
            },
            sleep: { recorder.recordSleep($0) })

        let outcome = try await confirmation.confirm(clientSecret: Self.secret)

        XCTAssertEqual(outcome, .timedOut)
        XCTAssertEqual(recorder.loadCount, 10)
        // 11s of wall clock: the lead-in plus one delay per attempt.
        XCTAssertEqual(recorder.sleeps.count, 11)
    }

    /// A failing read consumes an attempt and waits, so a 5xx cannot burn the budget instantly.
    func testFailingReadsConsumeTheBudgetThenThrow() async {
        struct ServerError: Error {}
        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: nil,
            polling: .init(maxAttempts: 10, interval: .seconds(1)),
            confirmIntent: { _, _ in self.intent(status: .pending) },
            loadIntent: { _, _ in
                _ = recorder.recordLoad()
                throw ServerError()
            },
            sleep: { recorder.recordSleep($0) })

        do {
            _ = try await confirmation.confirm(clientSecret: Self.secret)
            XCTFail("expected a throw")
        } catch {
            XCTAssertEqual(error as? FrameChargeIntentError, .statusUnavailable(attempts: 10, underlying: nil))
        }
        XCTAssertEqual(recorder.loadCount, 10, "exactly the attempt budget, no fast-retrying")
        // The final failure throws instead of sleeping again.
        XCTAssertEqual(recorder.sleeps.count, 10)
    }

    /// Earlier failures are retried rather than fatal.
    func testTransientReadFailureIsRetried() async throws {
        struct ServerError: Error {}
        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: nil,
            polling: .init(maxAttempts: 5, interval: .seconds(1)),
            confirmIntent: { _, _ in self.intent(status: .pending) },
            loadIntent: { _, _ in
                if recorder.recordLoad() < 3 { throw ServerError() }
                return self.intent(status: .succeeded)
            },
            sleep: { recorder.recordSleep($0) })

        let outcome = try await confirmation.confirm(clientSecret: Self.secret)

        guard case .succeeded = outcome else { return XCTFail("expected success") }
        XCTAssertEqual(recorder.loadCount, 3)
    }

    // MARK: - Decoding

    /// `status` is non-optional, so an unknown state would otherwise fail the whole object.
    func testUnknownStatusDecodesToUnknownRatherThanFailing() throws {
        let json = Data("""
        {
          "id": "\(Self.intentUUID)", "currency": "USD", "status": "a_brand_new_state",
          "authorization_mode": "automatic", "object": "charge_intent",
          "amount": 200, "created": 0, "livemode": false
        }
        """.utf8)

        let decoded = try JSONDecoder().decode(FrameObjects.ChargeIntent.self, from: json)

        XCTAssertEqual(decoded.status, .unknown)
        XCTAssertFalse(decoded.status.isTerminal)
    }

    /// The API supplies the presentable page, since `source` alone is not navigable.
    func testNextActionDecodes() throws {
        let json = Data("""
        {
          "id": "\(Self.intentUUID)", "currency": "USD", "status": "requires_3d_secure",
          "authorization_mode": "automatic", "object": "charge_intent",
          "amount": 200, "created": 0, "livemode": false,
          "next_action": {
            "type": "use_frame_sdk",
            "use_frame_sdk": {
              "source": "sess_abc",
              "directory_server_name": "visa",
              "challenge_url": "https://3ds.evervault.com/?team=t&app=a&session=sess_abc"
            }
          }
        }
        """.utf8)

        let decoded = try JSONDecoder().decode(FrameObjects.ChargeIntent.self, from: json)

        XCTAssertEqual(decoded.status, .requiresThreeDSecure)
        XCTAssertEqual(decoded.nextAction?.type, "use_frame_sdk")
        XCTAssertEqual(decoded.nextAction?.useFrameSDK?.source, "sess_abc")
        XCTAssertEqual(decoded.nextAction?.useFrameSDK?.directoryServerName, "visa")
        XCTAssertEqual(decoded.nextAction?.useFrameSDK?.challengeURL?.host, "3ds.evervault.com")
        XCTAssertTrue(decoded.requiresThreeDSecureChallenge)
    }

    /// An older response without `challenge_url` still decodes; the presenter reports it as
    /// unavailable rather than the whole intent failing to parse.
    func testNextActionWithoutChallengeURLStillDecodes() throws {
        let json = Data("""
        {
          "id": "\(Self.intentUUID)", "currency": "USD", "status": "requires_3d_secure",
          "authorization_mode": "automatic", "object": "charge_intent",
          "amount": 200, "created": 0, "livemode": false,
          "next_action": {
            "type": "use_frame_sdk",
            "use_frame_sdk": { "source": "sess_abc" }
          }
        }
        """.utf8)

        let decoded = try JSONDecoder().decode(FrameObjects.ChargeIntent.self, from: json)

        XCTAssertNil(decoded.nextAction?.useFrameSDK?.challengeURL)
        XCTAssertTrue(decoded.requiresThreeDSecureChallenge)
    }

    /// The wrapped intent's secret is what drives confirmation.
    func testTransferDecodesClientSecretAndThreeDSecureStatus() throws {
        let json = Data("""
        {
          "id": "tr_1", "object": "transfer", "status": "requires_3d_secure", "amount": 200,
          "client_secret": "\(Self.secret)"
        }
        """.utf8)

        let decoded = try JSONDecoder().decode(FrameObjects.Transfer.self, from: json)

        XCTAssertEqual(decoded.status, .requiresThreeDSecure)
        XCTAssertEqual(decoded.clientSecret, Self.secret)
        XCTAssertEqual(try ChargeIntentClientSecret(decoded.clientSecret ?? "").chargeIntentID,
                       Self.intentUUID)
    }

    /// A deferred confirm is what lets the API hold the charge for a challenge; an inline one
    /// rejects any charge that is not already settled.
    func testCreateTransferEncodesDeferredConfirm() throws {
        let request = TransferRequests.CreateTransferRequest(amount: 200,
                                                             accountId: "acct_1",
                                                             sourcePaymentMethodId: "pm_1",
                                                             confirm: false)

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])

        XCTAssertEqual(json["confirm"] as? Bool, false)
    }

    /// Omitted rather than sent as null, so payouts keep the API's own default.
    func testCreateTransferOmitsConfirmWhenUnset() throws {
        let request = TransferRequests.CreateTransferRequest(amount: 200, accountId: "acct_1")

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])

        XCTAssertNil(json["confirm"])
    }

    /// The browser SDK sends all three on a publishable-key confirm.
    func testConfirmRequestEncodesBrowserSDKFields() throws {
        let request = ChargeIntentsRequests.ConfirmChargeIntentRequest(clientSecret: Self.secret)

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any])

        XCTAssertEqual(json["client_secret"] as? String, Self.secret)
        XCTAssertEqual(json["use_frame_sdk"] as? Bool, true)
        XCTAssertEqual(json["expected_payment_method_type"] as? String, "card")
    }
}


/// Mirrors the presenter's once-only guard.
private final class OnceBox: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<FrameThreeDSecureChallengeResult, Never>?

    init(_ continuation: CheckedContinuation<FrameThreeDSecureChallengeResult, Never>) {
        self.continuation = continuation
    }

    func resume(with result: FrameThreeDSecureChallengeResult) {
        let claimed: CheckedContinuation<FrameThreeDSecureChallengeResult, Never>? = lock.withLock {
            defer { continuation = nil }
            return continuation
        }
        claimed?.resume(returning: result)
    }
}
