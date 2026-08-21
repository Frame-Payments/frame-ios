//
//  ChargeIntentConfirmation.swift
//  Frame-iOS
//

import Foundation

/// Presents a 3D Secure challenge and reports how it ended.
///
/// The three outcomes are a *UI lifecycle* signal, not a payment verdict: only the Frame API
/// decides whether the cardholder was charged. ``completed`` and ``failed`` are therefore
/// handled identically by the caller — both lead to polling — and only ``unavailable``
/// (the challenge never ran) is treated as an error.
public protocol FrameThreeDSecureChallengePresenting: Sendable {
    /// Presents the challenge for a charge intent and returns once the cardholder is done with it.
    ///
    /// - Parameters:
    ///   - challenge: The challenge session to present.
    ///   - intent: The charge intent the challenge belongs to.
    /// - Returns: How the challenge ended.
    func presentChallenge(_ challenge: FrameObjects.UseFrameSDK,
                          for intent: FrameObjects.ChargeIntent) async -> FrameThreeDSecureChallengeResult
}

/// How a presented 3D Secure challenge ended.
public enum FrameThreeDSecureChallengeResult: Sendable, Equatable {
    /// The cardholder finished the challenge. Says nothing about whether the charge succeeded.
    case completed
    /// The cardholder failed or abandoned the challenge. The charge may still have settled.
    case failed
    /// The challenge could not be loaded or presented, so it never ran.
    case unavailable
}

/// Confirms a charge intent from the app, driving a 3D Secure challenge when the API asks for one.
///
/// Mirrors the browser SDK's `confirmCardPayment`. The sequence is:
///
/// 1. Parse the `client_secret` and derive the bare intent id.
/// 2. `POST /charge_intents/{id}/confirm`.
/// 3. If the response is terminal, return immediately — no polling.
/// 4. If it needs 3D Secure, present the challenge, then poll regardless of how it ended.
/// 5. Otherwise poll until terminal.
///
/// Polling timings are part of the contract, not tuning knobs: see ``PollingConfiguration``.
public struct ChargeIntentConfirmation: Sendable {

    /// How the confirmation polls for a terminal status.
    ///
    /// The defaults match the browser SDK exactly. The initial delay is deliberate — the charge
    /// needs a beat to settle server-side, and polling immediately just burns an attempt.
    public struct PollingConfiguration: Sendable {
        /// How many times to read the intent's status before giving up.
        public let maxAttempts: Int
        /// How long to wait between reads, and before the first one.
        public let interval: Duration

        /// Creates a polling configuration.
        /// - Parameters:
        ///   - maxAttempts: Number of status reads before returning ``FrameChargeIntentOutcome/timedOut``.
        ///   - interval: Delay before the first read and between subsequent reads.
        public init(maxAttempts: Int = 10, interval: Duration = .seconds(1)) {
            // At least one read, so a caller passing 0 gets a status check rather than a trap.
            self.maxAttempts = max(1, maxAttempts)
            self.interval = interval
        }

        /// The browser SDK's timings: a 1s lead-in then up to 10 reads a second apart.
        public static let `default` = PollingConfiguration()
    }

    /// Reads a charge intent's current state. Injected so tests need no network.
    public typealias IntentLoader = @Sendable (_ intentID: String, _ clientSecret: String) async throws -> FrameObjects.ChargeIntent?
    /// Suspends for a duration. Injected so tests need no real time.
    public typealias Sleeper = @Sendable (Duration) async throws -> Void

    private let polling: PollingConfiguration
    private let challengePresenter: FrameThreeDSecureChallengePresenting?
    private let confirmIntent: IntentLoader
    private let loadIntent: IntentLoader
    private let sleep: Sleeper

    /// Creates a confirmation driver.
    ///
    /// - Parameters:
    ///   - challengePresenter: Presents a 3D Secure challenge when one is required. Passing
    ///     `nil` makes a required challenge fail with
    ///     ``FrameChargeIntentError/threeDSecureUnavailable(underlying:)`` instead of hanging.
    ///   - polling: How to poll for a terminal status.
    ///   - confirmIntent: Confirms the intent. Defaults to the live API.
    ///   - loadIntent: Re-reads the intent while polling. Defaults to the live API.
    ///   - sleep: Suspends between polls. Defaults to real time.
    public init(challengePresenter: FrameThreeDSecureChallengePresenting?,
                polling: PollingConfiguration = .default,
                confirmIntent: IntentLoader? = nil,
                loadIntent: IntentLoader? = nil,
                sleep: Sleeper? = nil) {
        self.challengePresenter = challengePresenter
        self.polling = polling
        self.confirmIntent = confirmIntent ?? { intentID, secret in
            try await ChargeIntentsAPI.confirmChargeIntent(intentId: intentID, clientSecret: secret).0
        }
        self.loadIntent = loadIntent ?? { intentID, secret in
            try await ChargeIntentsAPI.getChargeIntent(intentId: intentID, clientSecret: secret).0
        }
        self.sleep = sleep ?? { try await Task.sleep(for: $0) }
    }

    /// Confirms a charge intent, completing a 3D Secure challenge if the API requires one.
    ///
    /// - Parameter clientSecret: The intent's `client_secret` (`ci_<id>_secret_…`), as returned
    ///   on a transfer by your backend.
    /// - Returns: The terminal outcome, or ``FrameChargeIntentOutcome/timedOut`` if the charge
    ///   never settled within the polling budget.
    /// - Throws: ``FrameChargeIntentError/invalidClientSecret`` for a malformed secret,
    ///   ``FrameChargeIntentError/threeDSecureUnavailable(underlying:)`` if a required challenge
    ///   could not run, or ``FrameChargeIntentError/statusUnavailable(attempts:underlying:)``
    ///   if the final status read itself failed.
    public func confirm(clientSecret: String) async throws -> FrameChargeIntentOutcome {
        let secret = try ChargeIntentClientSecret(clientSecret)

        guard let intent = try await confirmIntent(secret.chargeIntentID, secret.value) else {
            // Confirm returned nothing decodable, so the charge's state is unknown. Poll rather
            // than guess — the intent may well have moved on server-side.
            return try await pollForTerminalOutcome(secret)
        }

        if let outcome = FrameChargeIntentOutcome.terminalOutcome(for: intent) {
            return outcome
        }

        if intent.status == .requiresThreeDSecure {
            guard let challenge = intent.nextAction?.useFrameSDK else {
                throw FrameChargeIntentError.missingThreeDSecureChallenge
            }
            guard let challengePresenter else {
                throw FrameChargeIntentError.threeDSecureUnavailable(underlying: nil)
            }

            // `completed` and `failed` are both just "the sheet is closed"; the API decides the
            // verdict. Only a challenge that never ran is an error.
            let result = await challengePresenter.presentChallenge(challenge, for: intent)
            if result == .unavailable {
                throw FrameChargeIntentError.threeDSecureUnavailable(underlying: nil)
            }
        }

        return try await pollForTerminalOutcome(secret)
    }

    /// Reads the intent until it reaches a terminal status or the attempt budget runs out.
    ///
    /// A failed read consumes an attempt and still waits out the interval: fast-retrying a
    /// transient 5xx would burn the whole budget in milliseconds.
    private func pollForTerminalOutcome(_ secret: ChargeIntentClientSecret) async throws -> FrameChargeIntentOutcome {
        // The lead-in comes before the first read, not after it.
        try await sleep(polling.interval)

        for attempt in 1...polling.maxAttempts {
            do {
                if let intent = try await loadIntent(secret.chargeIntentID, secret.value),
                   let outcome = FrameChargeIntentOutcome.terminalOutcome(for: intent) {
                    return outcome
                }
            } catch {
                // Only the last failure is fatal: earlier ones fall through to the delay and
                // are retried, which is what makes a blip survivable.
                if attempt == polling.maxAttempts {
                    throw FrameChargeIntentError.statusUnavailable(attempts: polling.maxAttempts,
                                                                  underlying: error)
                }
            }

            try await sleep(polling.interval)
        }

        // Every read succeeded but none was terminal. Returned, not thrown: the charge may still
        // settle, so the caller should re-check rather than treat this as a failure.
        return .timedOut
    }
}
