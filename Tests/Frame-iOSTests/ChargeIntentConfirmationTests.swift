//
//  ChargeIntentConfirmationTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame

/// Records how a challenge was driven and reports a scripted outcome.
private final class StubChallengePresenter: FrameThreeDSecureChallengePresenting, @unchecked Sendable {
    private let lock = NSLock()
    private var _presentCount = 0
    private var _lastSource: String?
    private let results: [FrameThreeDSecureChallengeResult]

    /// - Parameter results: One result per presentation, in order. The last repeats if needed.
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

/// Counts polling reads and the waits between them, so the timing contract is assertable
/// without spending real seconds.
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

    /// The resource id is the bare UUID: the `ci_` prefix and `_secret_…` suffix belong to the
    /// secret, and a URL built from the unstripped string 404s.
    func testClientSecretYieldsBareChargeIntentID() throws {
        let parsed = try ChargeIntentClientSecret(Self.secret)

        XCTAssertEqual(parsed.chargeIntentID, Self.intentUUID)
        XCTAssertFalse(parsed.chargeIntentID.hasPrefix("ci_"))
        XCTAssertFalse(parsed.chargeIntentID.contains("_secret_"))
        XCTAssertEqual(parsed.value, Self.secret)
    }

    /// A secret with no `_secret_` marker is treated as the id alone, matching the browser SDK.
    func testClientSecretWithoutMarkerUsesWholeString() throws {
        let parsed = try ChargeIntentClientSecret("ci_\(Self.intentUUID)")
        XCTAssertEqual(parsed.chargeIntentID, Self.intentUUID)
    }

    /// A mistyped or wrong-resource secret fails at the call site, not as a confusing 401 later.
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

    /// A charge that settles on confirm resolves immediately, with no polling at all.
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

    /// `requires_capture` is terminal, not pending. Treating it as pending would make
    /// authorize-only merchants appear to time out.
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

    /// A terminal failure carries the decline reason from `latest_charge`.
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

    /// A terminal `failed` with no `latest_charge` is a real API response: the outcome is a
    /// failure with no machine-readable reason, not a crash and not a success.
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

    /// A completed challenge is only a UI signal; the verdict still comes from the API.
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

    /// A failed challenge polls exactly like a completed one — the cardholder failing the
    /// challenge is not itself the payment verdict.
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

    /// A challenge that could not load never ran, which is a thrown error and distinct from
    /// the cardholder failing one that did.
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

    /// `requires_3d_secure` without a challenge session is unactionable, and is reported as
    /// such rather than presenting an empty challenge.
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

    /// Both halves are required to present a challenge: the status alone can be set without a
    /// challenge session having been produced.
    func testRequiresThreeDSecureChallengeNeedsBothStatusAndAction() {
        XCTAssertTrue(intent(status: .requiresThreeDSecure, nextAction: threeDSecureAction).requiresThreeDSecureChallenge)
        XCTAssertFalse(intent(status: .requiresThreeDSecure).requiresThreeDSecureChallenge)
        XCTAssertFalse(intent(status: .pending, nextAction: threeDSecureAction).requiresThreeDSecureChallenge)
    }

    /// A presenter that fires twice must not resume the caller twice — a continuation resumed
    /// twice traps, and a redirect racing a dismissal during teardown is exactly that case.
    func testDoubleReportedChallengeResolvesOnce() async throws {
        /// Reports two outcomes for one presentation, as a racing teardown would.
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

    /// A zero attempt budget must still perform one read rather than trapping on an empty range.
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

    /// The lead-in delay comes before the first read, and every non-terminal read is followed
    /// by one, so the budget spans the full wall-clock window rather than burning instantly.
    func testPollingSleepsBeforeFirstReadAndBetweenReads() async throws {
        let recorder = PollRecorder()
        let confirmation = ChargeIntentConfirmation(
            challengePresenter: nil,
            polling: .init(maxAttempts: 3, interval: .seconds(1)),
            confirmIntent: { _, _ in self.intent(status: .pending) },
            loadIntent: { _, _ in
                // Terminal only on the second read, so one inter-read delay is observable.
                recorder.recordLoad() == 2 ? self.intent(status: .succeeded) : self.intent(status: .pending)
            },
            sleep: { recorder.recordSleep($0) })

        let outcome = try await confirmation.confirm(clientSecret: Self.secret)

        guard case .succeeded = outcome else { return XCTFail("expected success") }
        XCTAssertEqual(recorder.loadCount, 2)
        XCTAssertEqual(recorder.sleeps, [.seconds(1), .seconds(1)],
                       "one lead-in delay plus one after the non-terminal read")
    }

    /// Exhausting the budget on non-terminal statuses is *returned*, not thrown: the charge may
    /// still settle, so the caller should re-check rather than treat it as a failure.
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

    /// A failing read consumes an attempt and still waits: fast-retrying a transient 5xx would
    /// burn the whole budget in milliseconds.
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

    /// A read that recovers before the budget runs out resolves normally: earlier failures are
    /// retried rather than being fatal.
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

    /// An unknown status must not fail the whole object: `status` is non-optional, so a state
    /// added server-side would otherwise make the intent undecodable.
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

    /// `next_action` decodes into the two fields the API actually serialises.
    func testNextActionDecodes() throws {
        let json = Data("""
        {
          "id": "\(Self.intentUUID)", "currency": "USD", "status": "requires_3d_secure",
          "authorization_mode": "automatic", "object": "charge_intent",
          "amount": 200, "created": 0, "livemode": false,
          "next_action": {
            "type": "use_frame_sdk",
            "use_frame_sdk": { "source": "sess_abc", "directory_server_name": "visa" }
          }
        }
        """.utf8)

        let decoded = try JSONDecoder().decode(FrameObjects.ChargeIntent.self, from: json)

        XCTAssertEqual(decoded.status, .requiresThreeDSecure)
        XCTAssertEqual(decoded.nextAction?.type, "use_frame_sdk")
        XCTAssertEqual(decoded.nextAction?.useFrameSDK?.source, "sess_abc")
        XCTAssertEqual(decoded.nextAction?.useFrameSDK?.directoryServerName, "visa")
        XCTAssertTrue(decoded.requiresThreeDSecureChallenge)
    }

    /// A transfer exposes the wrapped charge intent's secret, which is what drives confirmation.
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
}


/// Resumes a continuation at most once, mirroring the presenter's own guard.
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
