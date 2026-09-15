//
//  AccountEventQueue.swift
//  Frame-iOS
//

import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

/// Buffers account/diagnostic events and flushes them to the backend in batches.
///
/// Telemetry must never affect a payment flow: every public method here is fire-and-forget and
/// every failure — a full queue, a transport error, a per-event rejection — is swallowed. Nothing
/// this type does can throw to, or block, a caller.
///
/// In-memory only, by design: there is no disk persistence, so events still queued when the app is
/// killed are lost. A flush started from ``handleAppDidEnterBackground()`` is best-effort — a POST
/// begun at that point races process suspension and may never complete.
///
/// `flushHandler` is the seam for testing against a non-prod backend: the queue itself never reads
/// ``NetworkingConstants``, so a test (or, if one is ever needed, a QA build) supplies its own
/// handler instead of the production ``AccountEventsAPI.record(_:)`` default. Chosen over adding a
/// mutable base-URL override, which would touch every other endpoint's code path for this queue's
/// benefit alone.
actor AccountEventQueue {
    static let shared = AccountEventQueue(flushHandler: { events in
        await AccountEventsAPI.record(events)
    })

    /// Matches the backend's per-request cap (`POST /v1/client/account_events`).
    private static let maxBatchSize = 100
    /// Bounds the transport-failure retry so a persistently unreachable backend cannot loop forever.
    private static let maxTransportRetries = 3

    private typealias FlushHandler = ([AccountEventsRequests.Event]) async -> (AccountEventsRequests.RecordResponse?, NetworkingError?)

    /// Oldest events are dropped first once the queue is full, so a burst of failures loses detail
    /// on the events least likely to still be relevant rather than blocking new ones from queuing.
    private let maxQueueSize: Int
    private let flushSizeThreshold: Int
    private let flushInterval: TimeInterval

    private var pending: [AccountEventsRequests.Event] = []
    private let flush: FlushHandler
    private var timerTask: Task<Void, Never>?
    private var isObservingLifecycle = false

    init(maxQueueSize: Int = 200,
        flushSizeThreshold: Int = 20,
        flushInterval: TimeInterval = 30,
        flushHandler: @escaping ([AccountEventsRequests.Event]) async -> (AccountEventsRequests.RecordResponse?, NetworkingError?)) {
        self.maxQueueSize = maxQueueSize
        self.flushSizeThreshold = flushSizeThreshold
        self.flushInterval = flushInterval
        self.flush = flushHandler
    }

    /// Queues an event, flushing immediately once the size threshold is reached.
    func enqueue(_ event: AccountEventsRequests.Event) {
        if pending.count >= maxQueueSize {
            pending.removeFirst()
        }
        pending.append(event)
        startTimerIfNeeded()

        if pending.count >= flushSizeThreshold {
            Task { await flushPending() }
        }
    }

    /// Test-only inspection of what is currently queued, without triggering a flush.
    func pendingEventNamesForTesting() -> [String] {
        pending.map(\.name)
    }

    /// Starts the size/time-based observers. Safe to call more than once.
    func startObservingLifecycleIfNeeded() {
        startTimerIfNeeded()
        #if canImport(UIKit) && !os(watchOS)
        guard !isObservingLifecycle else { return }
        isObservingLifecycle = true
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { await self?.handleAppDidEnterBackground() }
        }
        #endif
    }

    /// Best-effort flush on backgrounding. Not guaranteed delivery — see the type documentation.
    func handleAppDidEnterBackground() async {
        await flushPending()
    }

    private func startTimerIfNeeded() {
        guard timerTask == nil else { return }
        let interval = flushInterval
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if Task.isCancelled { return }
                await self?.flushPending()
            }
        }
    }

    private func flushPending() async {
        guard !pending.isEmpty else { return }

        let batch = Array(pending.prefix(Self.maxBatchSize))
        pending.removeFirst(batch.count)

        await send(batch, attempt: 1)
    }

    /// Sends one batch, retrying only transport failures and only up to ``maxTransportRetries``.
    /// A rejected batch (malformed request, or a per-event rejection in a 202) is never retried —
    /// that is a contract violation, not a connectivity blip.
    private func send(_ batch: [AccountEventsRequests.Event], attempt: Int) async {
        let (_, error) = await flush(batch)

        guard let error, error.isTransport, attempt < Self.maxTransportRetries else {
            return
        }
        await send(batch, attempt: attempt + 1)
    }
}
