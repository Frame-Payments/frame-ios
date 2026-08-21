//
//  ChargeIntentConfirmation.swift
//  Frame-iOS
//

import Foundation

/// Presents a 3D Secure challenge and reports how it ended.
///
/// The result is a UI lifecycle signal, not a payment verdict — only the Frame API decides
/// whether the cardholder was charged.
public protocol FrameThreeDSecureChallengePresenting: Sendable {
    /// Presents the challenge and returns once the cardholder is done with it.
    func presentChallenge(_ challenge: FrameObjects.UseFrameSDK,
                          for intent: FrameObjects.ChargeIntent) async -> FrameThreeDSecureChallengeResult
}

/// How a presented 3D Secure challenge ended.
public enum FrameThreeDSecureChallengeResult: Sendable, Equatable {
    /// The cardholder finished the challenge. Says nothing about whether the charge succeeded.
    case completed
    /// The cardholder failed or abandoned it. The charge may still have settled.
    case failed
    /// The challenge could not be loaded, so it never ran.
    case unavailable
}

/// Confirms a charge intent from the app, driving a 3D Secure challenge when the API asks for one.
///
/// Mirrors the browser SDK's `confirmCardPayment`: confirm, present a challenge if required,
/// then poll for the verdict. Polling timings are part of the contract — see
/// ``PollingConfiguration``.
public struct ChargeIntentConfirmation: Sendable {

    /// How the confirmation polls for a terminal status. Defaults match the browser SDK.
    public struct PollingConfiguration: Sendable {
        /// How many times to read the status before giving up.
        public let maxAttempts: Int
        /// How long to wait between reads, and before the first one.
        public let interval: Duration

        /// Creates a polling configuration. `maxAttempts` is clamped to at least one read.
        public init(maxAttempts: Int = 10, interval: Duration = .seconds(1)) {
            self.maxAttempts = max(1, maxAttempts)
            self.interval = interval
        }

        /// A 1s lead-in then up to 10 reads a second apart.
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
    ///   - challengePresenter: Presents a required challenge. Passing `nil` makes a required
    ///     challenge throw rather than hang.
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
    /// - Parameter clientSecret: The intent's `client_secret` (`ci_<id>_secret_…`).
    /// - Returns: The terminal outcome, or ``FrameChargeIntentOutcome/timedOut``.
    /// - Throws: ``FrameChargeIntentError``.
    public func confirm(clientSecret: String) async throws -> FrameChargeIntentOutcome {
        let secret = try ChargeIntentClientSecret(clientSecret)

        guard let intent = try await confirmIntent(secret.chargeIntentID, secret.value) else {
            // Nothing decodable came back, so the state is unknown; poll rather than guess.
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

            // `completed` and `failed` both just mean the sheet closed; only a challenge that
            // never ran is an error.
            if await challengePresenter.presentChallenge(challenge, for: intent) == .unavailable {
                throw FrameChargeIntentError.threeDSecureUnavailable(underlying: nil)
            }
        }

        return try await pollForTerminalOutcome(secret)
    }

    private func pollForTerminalOutcome(_ secret: ChargeIntentClientSecret) async throws -> FrameChargeIntentOutcome {
        // The lead-in comes before the first read: the charge needs a beat to settle.
        try await sleep(polling.interval)

        for attempt in 1...polling.maxAttempts {
            do {
                if let intent = try await loadIntent(secret.chargeIntentID, secret.value),
                   let outcome = FrameChargeIntentOutcome.terminalOutcome(for: intent) {
                    return outcome
                }
            } catch {
                if attempt == polling.maxAttempts {
                    throw FrameChargeIntentError.statusUnavailable(attempts: polling.maxAttempts,
                                                                  underlying: error)
                }
            }

            // A failed read consumes an attempt and still waits: fast-retrying a transient 5xx
            // would burn the whole budget in milliseconds.
            try await sleep(polling.interval)
        }

        // Returned rather than thrown — the charge may still settle, so the caller re-checks.
        return .timedOut
    }
}
