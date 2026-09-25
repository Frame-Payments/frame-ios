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

    /// Buffers events emitted before an account ID is known. Overridable so tests can reset state
    /// between runs without depending on ``FrameNetworking/shared``'s own reset path.
    nonisolated(unsafe) static var pendingBuffer = PendingEventBuffer()

    /// Queues an event for the account this app run belongs to.
    ///
    /// A flow launched without an account ID (the common case — onboarding creates the account
    /// mid-flow) buffers the event instead of dropping it; ``onAccountIdResolved(_:)`` flushes the
    /// buffer once an account ID is known.
    ///
    /// - Parameters:
    ///   - name: The event's identity — see ``AccountEventName``.
    ///   - screen: The screen/flow the event happened on — see ``AccountEventScreen``.
    ///   - detail: Optional developer-facing detail, either a fixed ``AccountEventDetail``
    ///     constant or a dynamic debug description (e.g. `"\(error)"`). Must never contain PII,
    ///     a PAN, a CVV, or a raw customer identifier — use a debug description, never
    ///     user-facing copy.
    public static func emit(name: AccountEventName, screen: AccountEventScreen, detail: String? = nil) {
        let occurredAt = ISO8601DateFormatter().string(from: Date())
        let pending = PendingEvent(name: name.rawValue, screen: screen.rawValue, occurredAt: occurredAt, detail: detail)

        // Must decide buffer-vs-send inside the actor, atomically with onAccountIdResolved's
        // drain, or a resolve landing in between can drop this event permanently.
        Task {
            guard let accountId = await pendingBuffer.addIfNoAccountId(pending) else {
                return
            }

            let event = AccountEventsRequests.Event(
                accountId: accountId,
                name: name.rawValue,
                screen: screen.rawValue,
                platform: FrameSDK.eventPlatform,
                sdkVersion: FrameSDK.version,
                hostSDKVersion: FrameSDK.hostSDKVersion,
                occurredAt: occurredAt,
                detail: detail
            )

            await queue.enqueue(event)
        }
    }

    /// Flushes events buffered before `accountId` resolved, preserving each one's original `occurredAt`.
    static func onAccountIdResolved(_ accountId: String) {
        Task {
            let flushed = await pendingBuffer.drain()
            guard !flushed.isEmpty else { return }
            for pending in flushed {
                await queue.enqueue(
                    AccountEventsRequests.Event(
                        accountId: accountId,
                        name: pending.name,
                        screen: pending.screen,
                        platform: FrameSDK.eventPlatform,
                        sdkVersion: FrameSDK.version,
                        hostSDKVersion: FrameSDK.hostSDKVersion,
                        occurredAt: pending.occurredAt,
                        detail: pending.detail
                    )
                )
            }
            await queue.flush()
        }
    }
}

/// An event emitted before an account ID was known, held until ``AccountEventEmitter/onAccountIdResolved(_:)``
/// can attribute it. Mirrors ``AccountEventsRequests/Event`` minus `accountId`, which doesn't exist yet.
struct PendingEvent {
    let name: String
    let screen: String
    let occurredAt: String
    let detail: String?
}

/// Bounded, actor-isolated buffer of events emitted before an account ID resolved. A separate type
/// from ``AccountEventQueue`` because it holds ``PendingEvent`` (no `accountId` yet), not
/// ``AccountEventsRequests/Event``.
actor PendingEventBuffer {
    private static let maxSize = 200

    private var pending: [PendingEvent] = []

    /// Appends `event` and returns `nil` if `FrameNetworking.shared.accountId` is still unset;
    /// otherwise appends nothing and returns the resolved account ID to send directly instead.
    func addIfNoAccountId(_ event: PendingEvent) -> String? {
        guard let accountId = FrameNetworking.shared.accountId else {
            if pending.count >= Self.maxSize {
                pending.removeFirst()
            }
            pending.append(event)
            return nil
        }
        return accountId
    }

    func drain() -> [PendingEvent] {
        defer { pending.removeAll() }
        return pending
    }

    /// Test-only inspection of what is currently buffered, without draining it.
    func pendingEventNamesForTesting() -> [String] {
        pending.map(\.name)
    }

    /// Test-only reset so buffer state doesn't leak between tests sharing this singleton.
    func clearForTesting() {
        pending.removeAll()
    }
}
