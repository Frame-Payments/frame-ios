//
//  TransferV2Confirmation.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/29/26.
//

import Foundation

/// Confirms a V2 transfer from the app, driving a 3D Secure challenge when the API asks for one.
///
/// Mirrors ``ChargeIntentConfirmation`` / Frame.js `confirmTransfer`.
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

    public typealias TransferLoader = @Sendable (_ transferID: String, _ clientSecret: String) async throws -> FrameObjects.TransferV2?
    public typealias Sleeper = @Sendable (Duration) async throws -> Void

    private let polling: PollingConfiguration
    private let challengePresenter: FrameThreeDSecureChallengePresenting?
    private let confirmTransfer: TransferLoader
    private let loadTransfer: TransferLoader
    private let sleep: Sleeper

    public init(challengePresenter: FrameThreeDSecureChallengePresenting?,
                polling: PollingConfiguration = .default,
                confirmTransfer: TransferLoader? = nil,
                loadTransfer: TransferLoader? = nil,
                sleep: Sleeper? = nil) {
        self.challengePresenter = challengePresenter
        self.polling = polling
        self.confirmTransfer = confirmTransfer ?? { transferID, secret in
            try await TransfersV2API.confirmTransfer(transferId: transferID, clientSecret: secret).0
        }
        self.loadTransfer = loadTransfer ?? { transferID, secret in
            try await TransfersV2API.getTransferWith(transferId: transferID, clientSecret: secret).0
        }
        self.sleep = sleep ?? { try await Task.sleep(for: $0) }
    }

    /// Confirms a V2 transfer, completing a 3D Secure challenge if required.
    public func confirm(clientSecret: String) async throws -> FrameTransferV2Outcome {
        let secret = try TransferV2ClientSecret(clientSecret)

        guard let transfer = try await confirmTransfer(secret.transferID, secret.value) else {
            return try await pollForTerminalOutcome(secret)
        }

        if let outcome = FrameTransferV2Outcome.terminalOutcome(for: transfer) {
            return outcome
        }

        let paymentNeeds3DS = transfer.payment?.status == "requires_3d_secure"
            || transfer.payment?.status == "requires_action"
        if paymentNeeds3DS {
            try await presentChallengeIfNeeded(for: transfer)
        }

        return try await pollForTerminalOutcome(secret)
    }

    private func presentChallengeIfNeeded(for transfer: FrameObjects.TransferV2) async throws {
        guard let challengePresenter else {
            throw FrameTransferV2Error.threeDSecureUnavailable(underlying: nil)
        }

        if let useFrameSDK = transfer.nextAction?.useFrameSDK {
            let shell = FrameObjects.ChargeIntent(
                id: transfer.id,
                currency: transfer.amount?.currency ?? "usd",
                shipping: FrameObjects.BillingAddress(postalCode: ""),
                status: .requiresThreeDSecure,
                authorizationMode: .automatic,
                object: "transfer",
                amount: transfer.amount?.value ?? 0,
                created: transfer.created ?? 0,
                livemode: transfer.livemode ?? false,
                nextAction: .init(type: "use_frame_sdk", useFrameSDK: useFrameSDK)
            )
            if await challengePresenter.presentChallenge(useFrameSDK, for: shell) == .unavailable {
                throw FrameTransferV2Error.threeDSecureUnavailable(underlying: nil)
            }
            return
        }

        if let redirect = transfer.nextAction?.redirectUrl, let url = URL(string: redirect) {
            let synthetic = FrameObjects.UseFrameSDK(source: "redirect", challengeURL: url)
            let shell = FrameObjects.ChargeIntent(
                id: transfer.id,
                currency: transfer.amount?.currency ?? "usd",
                shipping: FrameObjects.BillingAddress(postalCode: ""),
                status: .requiresThreeDSecure,
                authorizationMode: .automatic,
                object: "transfer",
                amount: transfer.amount?.value ?? 0,
                created: transfer.created ?? 0,
                livemode: transfer.livemode ?? false,
                nextAction: .init(type: "redirect", useFrameSDK: synthetic)
            )
            if await challengePresenter.presentChallenge(synthetic, for: shell) == .unavailable {
                throw FrameTransferV2Error.threeDSecureUnavailable(underlying: nil)
            }
            return
        }

        throw FrameTransferV2Error.missingThreeDSecureChallenge
    }

    private func pollForTerminalOutcome(_ secret: TransferV2ClientSecret) async throws -> FrameTransferV2Outcome {
        var lastError: Error?
        for attempt in 1...polling.maxAttempts {
            try await sleep(polling.interval)
            do {
                if let transfer = try await loadTransfer(secret.transferID, secret.value),
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
