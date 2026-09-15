//
//  AccountEventQueueTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame

/// Records every batch a queue under test hands to its flush handler, and can script the outcome
/// of each call so transport-failure and rejection paths are testable without real network access.
private actor FlushRecorder {
    private(set) var batches: [[AccountEventsRequests.Event]] = []
    private var results: [(AccountEventsRequests.RecordResponse?, NetworkingError?)]
    private let defaultResult: (AccountEventsRequests.RecordResponse?, NetworkingError?)

    init(results: [(AccountEventsRequests.RecordResponse?, NetworkingError?)] = [],
        defaultResult: (AccountEventsRequests.RecordResponse?, NetworkingError?) = (AccountEventsRequests.RecordResponse(recorded: 0, rejected: []), nil)) {
        self.results = results
        self.defaultResult = defaultResult
    }

    var callCount: Int { batches.count }

    func record(_ batch: [AccountEventsRequests.Event]) -> (AccountEventsRequests.RecordResponse?, NetworkingError?) {
        batches.append(batch)
        if !results.isEmpty {
            return results.removeFirst()
        }
        return defaultResult
    }
}

private func makeEvent(name: String = "attestation_failed", accountId: String = UUID().uuidString) -> AccountEventsRequests.Event {
    AccountEventsRequests.Event(
        accountId: accountId,
        name: name,
        screen: "ApplePay",
        platform: "ios",
        sdkVersion: FrameSDK.version,
        hostSDKVersion: nil,
        occurredAt: ISO8601DateFormatter().string(from: Date()),
        detail: nil
    )
}

final class AccountEventQueueTests: XCTestCase {

    // MARK: - Bound / drop-oldest

    func testQueueDropsOldestEventWhenFullRatherThanRejectingNewOnes() async {
        let recorder = FlushRecorder()
        // A flush threshold above the enqueue count below isolates bound/drop-oldest from the
        // size-triggered auto-flush, which otherwise drains `pending` concurrently with the loop.
        let queue = AccountEventQueue(maxQueueSize: 200, flushSizeThreshold: 1_000, flushInterval: 3_600,
                                      flushHandler: { await recorder.record($0) })

        // One over the bound (200): the oldest (name "0") should be the one dropped.
        for i in 0...200 {
            await queue.enqueue(makeEvent(name: "\(i)"))
        }

        let queuedNames = await queue.pendingEventNamesForTesting()

        XCTAssertFalse(queuedNames.contains("0"), "Oldest event should have been dropped")
        XCTAssertTrue(queuedNames.contains("200"), "Newest event should still be queued")
        XCTAssertEqual(queuedNames.count, 200, "Queue should hold at most 200 events")
    }

    // MARK: - Flush triggers

    func testFlushesAutomaticallyOnceSizeThresholdIsReached() async {
        let recorder = FlushRecorder()
        let queue = AccountEventQueue(flushHandler: { await recorder.record($0) })

        for i in 0..<20 {
            await queue.enqueue(makeEvent(name: "\(i)"))
        }

        // The size-triggered flush is fired via an unstructured Task; give it a beat to run.
        try? await Task.sleep(nanoseconds: 200_000_000)

        let callCount = await recorder.callCount
        XCTAssertGreaterThanOrEqual(callCount, 1, "Reaching the size threshold should trigger a flush")
    }

    func testAppBackgroundingFlushesQueuedEvents() async {
        let recorder = FlushRecorder()
        let queue = AccountEventQueue(flushHandler: { await recorder.record($0) })

        await queue.enqueue(makeEvent())
        await queue.handleAppDidEnterBackground()

        let batches = await recorder.batches
        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches.first?.count, 1)
    }

    func testBackgroundFlushWithNothingQueuedSendsNoRequest() async {
        let recorder = FlushRecorder()
        let queue = AccountEventQueue(flushHandler: { await recorder.record($0) })

        await queue.handleAppDidEnterBackground()

        let callCount = await recorder.callCount
        XCTAssertEqual(callCount, 0)
    }

    // MARK: - Transport failure

    func testTransportFailureIsRetriedButBounded() async {
        let recorder = FlushRecorder(results: [
            (nil, .invalidURL),
            (nil, .invalidURL),
            (nil, .invalidURL),
            (nil, .invalidURL), // Should never be reached — retries are bounded.
        ])
        let queue = AccountEventQueue(flushHandler: { await recorder.record($0) })

        await queue.enqueue(makeEvent())
        await queue.handleAppDidEnterBackground()

        let callCount = await recorder.callCount
        XCTAssertEqual(callCount, 3, "A transport failure should retry, but only up to the bound")
    }

    func testTransportFailureSwallowedAfterExhaustingRetries() async {
        let recorder = FlushRecorder(defaultResult: (nil, .unknownError))
        let queue = AccountEventQueue(flushHandler: { await recorder.record($0) })

        await queue.enqueue(makeEvent())
        // Must not throw, hang, or otherwise surface to the caller.
        await queue.handleAppDidEnterBackground()

        let callCount = await recorder.callCount
        XCTAssertGreaterThan(callCount, 0)
    }

    // MARK: - Rejected batch

    func testRejectedBatchIsNeverRetried() async {
        let rejectedResponse = AccountEventsRequests.RecordResponse(
            recorded: 0,
            rejected: [AccountEventsRequests.Rejection(index: 0, name: "attestation_failed", error: "account not found")]
        )
        let recorder = FlushRecorder(defaultResult: (rejectedResponse, nil))
        let queue = AccountEventQueue(flushHandler: { await recorder.record($0) })

        await queue.enqueue(makeEvent())
        await queue.handleAppDidEnterBackground()

        let callCount = await recorder.callCount
        XCTAssertEqual(callCount, 1, "A 202 with per-event rejections is not a transport failure and must not be retried")
    }

    func testServerErrorIsNotRetried() async {
        // A non-transport NetworkingError (e.g. a validation-class .serverError) must not be retried.
        let recorder = FlushRecorder(defaultResult: (nil, .serverError(statusCode: 422, errorDescription: "bad request")))
        let queue = AccountEventQueue(flushHandler: { await recorder.record($0) })

        await queue.enqueue(makeEvent())
        await queue.handleAppDidEnterBackground()

        let callCount = await recorder.callCount
        XCTAssertEqual(callCount, 1)
    }

    // MARK: - Concurrency

    func testConcurrentEnqueueDoesNotLoseOrCorruptEvents() async {
        let recorder = FlushRecorder()
        let queue = AccountEventQueue(flushHandler: { await recorder.record($0) })

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask { await queue.enqueue(makeEvent(name: "\(i)")) }
            }
        }

        await queue.handleAppDidEnterBackground()

        let names = await recorder.batches.flatMap { $0.map(\.name) }
        XCTAssertEqual(Set(names).count, 50, "All 50 concurrently-enqueued events should be present exactly once")
    }
}

// MARK: - occurred_at formatting

final class AccountEventOccurredAtTests: XCTestCase {

    func testOccurredAtIsOffsetQualified() {
        let formatted = ISO8601DateFormatter().string(from: Date())
        XCTAssertTrue(formatted.hasSuffix("Z"), "occurred_at must be offset-qualified, not a naive local timestamp")
    }

    func testEmittedEventEncodesOffsetQualifiedOccurredAt() throws {
        let event = makeEvent()
        let data = try FrameNetworking.shared.jsonEncoder.encode(event)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let occurredAt = try XCTUnwrap(json["occurred_at"] as? String)
        XCTAssertTrue(occurredAt.hasSuffix("Z"))
    }
}
