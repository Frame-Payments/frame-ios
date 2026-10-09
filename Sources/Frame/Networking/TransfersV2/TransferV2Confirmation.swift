//
//  TransferV2Confirmation.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/29/26.
//

import Foundation

/// Presents a 3D Secure challenge and reports how it ended.
///
/// The result is a UI lifecycle signal, not a payment verdict — only the Frame API decides
/// whether the cardholder was charged.
public protocol FrameThreeDSecureChallengePresenting: Sendable {
    /// Presents the challenge and returns once the cardholder is done with it.
    func presentChallenge(_ challenge: FrameObjects.UseFrameSDK) async -> FrameThreeDSecureChallengeResult
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

/// Confirms a V2 transfer from the app, driving a 3D Secure challenge when the API asks for one.
public struct TransferV2Confirmation: Sendable {

    /// How the confirmation polls for a terminal payment status.
    public struct PollingConfiguration: Sendable {
        public let maxAttempts: Int
        public let interval: Duration

        public init(maxAttempts: Int = 10, interval: Duration = .seconds(1)) {
            self.maxAttempts = max(1, maxAttempts)
            self.interval = interval
        }

        public static let `default` = PollingConfiguration()
    }

    public typealias TransferLoader = @Sendable (_ transferID: String) async throws -> FrameObjects.TransferV2?
    public typealias Sleeper = @Sendable (Duration) async throws -> Void

    private let polling: PollingConfiguration
    private let challengePresenter: FrameThreeDSecureChallengePresenting?
    private let confirmTransfer: TransferLoader
    private let loadTransfer: TransferLoader
    private let sleep: Sleeper

    /// Creates a confirmation helper.
    ///
    /// - Parameter checkoutClientSecret: `chk_sess_…` minted with a locked amount. When `nil`,
    ///   confirm and poll use the secret key.
    public init(checkoutClientSecret: String? = nil,
                challengePresenter: FrameThreeDSecureChallengePresenting?,
                polling: PollingConfiguration = .default,
                confirmTransfer: TransferLoader? = nil,
                loadTransfer: TransferLoader? = nil,
                sleep: Sleeper? = nil) {
        self.challengePresenter = challengePresenter
        self.polling = polling
        let sessionToken = checkoutClientSecret
        self.confirmTransfer = confirmTransfer ?? { transferID in
            if let sessionToken, !sessionToken.isEmpty {
                return try await TransfersV2API.confirmTransfer(
                    transferId: transferID,
                    checkoutClientSecret: sessionToken
                ).0
            }
            return try await TransfersV2API.confirmTransfer(transferId: transferID).0
        }
        self.loadTransfer = loadTransfer ?? { transferID in
            if let sessionToken, !sessionToken.isEmpty {
                return try await TransfersV2API.getTransferWith(
                    transferId: transferID,
                    checkoutClientSecret: sessionToken
                ).0
            }
            return try await TransfersV2API.getTransferWith(transferId: transferID).0
        }
        self.sleep = sleep ?? { try await Task.sleep(for: $0) }
    }

    /// Confirms a V2 transfer, completing a 3D Secure challenge if required.
    public func confirm(transferId: String) async throws -> FrameTransferV2Outcome {
        guard !transferId.isEmpty else { throw FrameTransferV2Error.missingTransfer }

        guard let transfer = try await confirmTransfer(transferId) else {
            return try await pollForTerminalOutcome(transferId)
        }

        if let outcome = FrameTransferV2Outcome.terminalOutcome(for: transfer) {
            return outcome
        }

        let paymentNeeds3DS = transfer.payment?.status == "requires_3d_secure"
            || transfer.payment?.status == "requires_action"
        if paymentNeeds3DS {
            try await presentChallengeIfNeeded(for: transfer)
        }

        return try await pollForTerminalOutcome(transferId)
    }

    private func presentChallengeIfNeeded(for transfer: FrameObjects.TransferV2) async throws {
        guard let challengePresenter else {
            throw FrameTransferV2Error.threeDSecureUnavailable(underlying: nil)
        }

        if let useFrameSDK = transfer.nextAction?.useFrameSDK {
            if await challengePresenter.presentChallenge(useFrameSDK) == .unavailable {
                throw FrameTransferV2Error.threeDSecureUnavailable(underlying: nil)
            }
            return
        }

        if let redirect = transfer.nextAction?.redirectUrl, let url = URL(string: redirect) {
            let synthetic = FrameObjects.UseFrameSDK(source: "redirect", challengeURL: url)
            if await challengePresenter.presentChallenge(synthetic) == .unavailable {
                throw FrameTransferV2Error.threeDSecureUnavailable(underlying: nil)
            }
            return
        }

        throw FrameTransferV2Error.missingThreeDSecureChallenge
    }

    private func pollForTerminalOutcome(_ transferId: String) async throws -> FrameTransferV2Outcome {
        var lastError: Error?
        for attempt in 1...polling.maxAttempts {
            try await sleep(polling.interval)
            do {
                if let transfer = try await loadTransfer(transferId),
                   let outcome = FrameTransferV2Outcome.terminalOutcome(for: transfer) {
                    return outcome
                }
            } catch {
                lastError = error
            }
            _ = attempt
        }
        if lastError != nil {
            throw FrameTransferV2Error.statusUnavailable(
                attempts: polling.maxAttempts,
                underlying: lastError
            )
        }
        return .timedOut
    }
}
