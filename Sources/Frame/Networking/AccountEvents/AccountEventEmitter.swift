//
//  AccountEventEmitter.swift
//  Frame-iOS
//

import Foundation

/// Builds and queues account/diagnostic events for the backend's merchant dashboard.
///
/// There is no public *integrator-facing* emit API — every call site is SDK-owned instrumentation
/// of a moment the SDK already knows about. ``emit(name:screen:detail:)`` is `public` only because
/// `FrameOnboarding` is a separate SPM target from `Frame` and needs to call it too; it is not
/// documented for or intended to be called by host apps.
public enum AccountEventEmitter {

    /// The queue events are enqueued onto. Overridable so tests can inject a queue with a
    /// recording flush handler instead of exercising the real network path.
    nonisolated(unsafe) static var queue = AccountEventQueue.shared

    /// Queues an event for the account this app run belongs to.
    ///
    /// Silently does nothing if no `accountId` was supplied to `initialize(...)` — there is no
    /// account to attribute the event to, and, per the queue's contract, this must never surface
    /// an error or block the caller.
    ///
    /// - Parameters:
    ///   - name: SDK-defined free text identifying the event (e.g. `"attestation_failed"`).
    ///   - screen: The screen/flow the event happened on (e.g. `"ApplePay"`, `"Checkout"`).
    ///   - detail: Optional developer-facing detail. Must never contain PII, a PAN, a CVV, or a
    ///     raw customer identifier — use a debug description, never user-facing copy.
    public static func emit(name: String, screen: String, detail: String? = nil) {
        guard let accountId = FrameNetworking.shared.accountId else { return }

        let event = AccountEventsRequests.Event(
            accountId: accountId,
            name: name,
            screen: screen,
            platform: FrameSDK.eventPlatform,
            sdkVersion: FrameSDK.version,
            hostSDKVersion: FrameSDK.hostSDKVersion,
            occurredAt: ISO8601DateFormatter().string(from: Date()),
            detail: detail
        )

        Task { await queue.enqueue(event) }
    }
}
