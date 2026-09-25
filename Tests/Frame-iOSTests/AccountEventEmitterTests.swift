//
//  AccountEventEmitterTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame

final class AccountEventEmitterTests: XCTestCase {

    private let realQueue = AccountEventEmitter.queue

    override func setUp() async throws {
        try await super.setUp()
        await AccountEventEmitter.pendingBuffer.clearForTesting()
    }

    override func tearDown() {
        AccountEventEmitter.queue = realQueue
        FrameSDK.eventPlatform = "ios"
        FrameSDK.hostSDKVersion = nil
        super.tearDown()
    }

    func testEmitEnqueuesOntoTheConfiguredQueueWithTheConfiguredAccountId() async {
        FrameNetworking.shared.initialize(publishableKey: "pk_test", accountId: "3fa85f64-5717-4562-b3fc-2c963f66afa6")

        let recorder = FlushRecorderForEmitterTests()
        AccountEventEmitter.queue = AccountEventQueue(flushHandler: { await recorder.record($0) })

        AccountEventEmitter.emit(name: .attestationFailed, screen: .applePay, detail: "debug detail")
        // emit() enqueues via an unstructured Task so it never blocks the caller (a hard
        // requirement — telemetry must not add latency to a payment flow); give it a beat to
        // land before flushing.
        try? await Task.sleep(nanoseconds: 50_000_000)
        await AccountEventEmitter.queue.handleAppDidEnterBackground()

        let batches = await recorder.batches
        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches.first?.first?.accountId, "3fa85f64-5717-4562-b3fc-2c963f66afa6")
        XCTAssertEqual(batches.first?.first?.name, "attestation_failed")
        XCTAssertEqual(batches.first?.first?.screen, "ApplePay")
        XCTAssertEqual(batches.first?.first?.platform, "ios")
    }

    func testEmitWithoutAccountIdBuffersInsteadOfDropping() async {
        await AccountEventEmitter.pendingBuffer.clearForTesting()
        FrameNetworking.shared.initialize(publishableKey: "pk_test", accountId: "")
        XCTAssertNil(FrameNetworking.shared.accountId)

        let recorder = FlushRecorderForEmitterTests()
        AccountEventEmitter.queue = AccountEventQueue(flushHandler: { await recorder.record($0) })

        AccountEventEmitter.emit(name: .attestationFailed, screen: .applePay)
        try? await Task.sleep(nanoseconds: 50_000_000)

        let callCount = await recorder.callCount
        XCTAssertEqual(callCount, 0)
        let buffered = await AccountEventEmitter.pendingBuffer.pendingEventNamesForTesting()
        XCTAssertTrue(buffered.contains("attestation_failed"))
    }

    func testResolvingAccountIdFlushesBufferedEventsWithOriginalTimestamp() async {
        await AccountEventEmitter.pendingBuffer.clearForTesting()
        FrameNetworking.shared.initialize(publishableKey: "pk_test", accountId: "")

        let recorder = FlushRecorderForEmitterTests()
        AccountEventEmitter.queue = AccountEventQueue(flushSizeThreshold: 1, flushHandler: { await recorder.record($0) })

        AccountEventEmitter.emit(name: .attestationFailed, screen: .applePay)
        try? await Task.sleep(nanoseconds: 50_000_000)
        let bufferedBeforeResolve = await AccountEventEmitter.pendingBuffer.pendingEventNamesForTesting()
        XCTAssertTrue(bufferedBeforeResolve.contains("attestation_failed"))

        FrameNetworking.shared.setAccountIdIfUnset("3fa85f64-5717-4562-b3fc-2c963f66afa6")
        try? await Task.sleep(nanoseconds: 100_000_000)

        let batches = await recorder.batches
        let flushedEvent = batches.flatMap { $0 }.first { $0.name == "attestation_failed" }
        XCTAssertEqual(flushedEvent?.accountId, "3fa85f64-5717-4562-b3fc-2c963f66afa6")
        let bufferedAfterResolve = await AccountEventEmitter.pendingBuffer.pendingEventNamesForTesting()
        XCTAssertFalse(bufferedAfterResolve.contains("attestation_failed"))
    }

    func testPendingBufferDropsOldestOnOverflow() async {
        FrameNetworking.shared.initialize(publishableKey: "pk_test", accountId: "")
        for _ in 0..<201 {
            AccountEventEmitter.emit(name: .attestationFailed, screen: .applePay)
        }
        try? await Task.sleep(nanoseconds: 100_000_000)

        let buffered = await AccountEventEmitter.pendingBuffer.pendingEventNamesForTesting()
        XCTAssertEqual(buffered.count, 200)
    }

    func testEmitRacingWithAccountIdResolutionNeverLosesTheEvent() async {
        for i in 0..<100 {
            await AccountEventEmitter.pendingBuffer.clearForTesting()
            FrameNetworking.shared.initialize(publishableKey: "pk_test", accountId: "")

            let recorder = FlushRecorderForEmitterTests()
            AccountEventEmitter.queue = AccountEventQueue(flushSizeThreshold: 1, flushHandler: { await recorder.record($0) })

            let emitTask = Task.detached { AccountEventEmitter.emit(name: .attestationFailed, screen: .applePay, detail: "iter-\(i)") }
            let resolveTask = Task.detached { FrameNetworking.shared.setAccountIdIfUnset("acc_race_\(i)") }
            _ = await (emitTask.value, resolveTask.value)

            var landedInQueue = false
            for _ in 0..<50 {
                let batches = await recorder.batches
                if batches.contains(where: { $0.contains(where: { $0.detail == "iter-\(i)" }) }) {
                    landedInQueue = true
                    break
                }
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
            XCTAssertTrue(landedInQueue, "iteration \(i): event never flushed — permanently stuck in buffer or lost")

            let stillBuffered = await AccountEventEmitter.pendingBuffer.pendingEventNamesForTesting()
            XCTAssertTrue(stillBuffered.isEmpty, "iteration \(i): event still sitting in the pre-account buffer after resolution")
        }
    }

    func testResolvingTwiceNeverOverwritesTheFirstAccountIdOrReFlushes() async {
        await AccountEventEmitter.pendingBuffer.clearForTesting()
        FrameNetworking.shared.initialize(publishableKey: "pk_test", accountId: "")

        let recorder = FlushRecorderForEmitterTests()
        AccountEventEmitter.queue = AccountEventQueue(flushSizeThreshold: 1, flushHandler: { await recorder.record($0) })

        AccountEventEmitter.emit(name: .attestationFailed, screen: .applePay, detail: "resolve-twice-test")
        try? await Task.sleep(nanoseconds: 50_000_000)

        FrameNetworking.shared.setAccountIdIfUnset("acc_first")
        try? await Task.sleep(nanoseconds: 100_000_000)
        FrameNetworking.shared.setAccountIdIfUnset("acc_second")
        try? await Task.sleep(nanoseconds: 100_000_000)

        let batches = await recorder.batches
        let ownEvents = batches.flatMap { $0 }.filter { $0.detail == "resolve-twice-test" }
        XCTAssertEqual(ownEvents.count, 1)
        XCTAssertEqual(ownEvents.first?.accountId, "acc_first")
        XCTAssertEqual(FrameNetworking.shared.accountId, "acc_first")
    }

    func testSetHostSDKInfoOverridesPlatformAndAddsHostVersion() {
        FrameSDK.setHostSDKInfo(platform: "react_native", version: "3.4.0")

        XCTAssertEqual(FrameSDK.eventPlatform, "react_native")
        XCTAssertEqual(FrameSDK.hostSDKVersion, "3.4.0")
    }
}

private actor FlushRecorderForEmitterTests {
    private(set) var batches: [[AccountEventsRequests.Event]] = []
    var callCount: Int { batches.count }

    func record(_ batch: [AccountEventsRequests.Event]) -> (AccountEventsRequests.RecordResponse?, NetworkingError?) {
        batches.append(batch)
        return (AccountEventsRequests.RecordResponse(recorded: batch.count, rejected: []), nil)
    }
}
