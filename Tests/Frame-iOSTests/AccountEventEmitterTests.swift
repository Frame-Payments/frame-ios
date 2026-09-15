//
//  AccountEventEmitterTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame

final class AccountEventEmitterTests: XCTestCase {

    private let realQueue = AccountEventEmitter.queue

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

        AccountEventEmitter.emit(name: "attestation_failed", screen: "ApplePay", detail: "debug detail")
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
    }

    /// Blank accountId collapses to nil in `initialize(accountId:)`, so there is no account to
    /// attribute the event to and it must be dropped rather than sent with an empty account_id.
    func testEmitWithoutAccountIdEnqueuesNothing() async {
        FrameNetworking.shared.initialize(publishableKey: "pk_test", accountId: "")
        XCTAssertNil(FrameNetworking.shared.accountId)

        let recorder = FlushRecorderForEmitterTests()
        AccountEventEmitter.queue = AccountEventQueue(flushHandler: { await recorder.record($0) })

        AccountEventEmitter.emit(name: "attestation_failed", screen: "ApplePay")
        await AccountEventEmitter.queue.handleAppDidEnterBackground()

        let callCount = await recorder.callCount
        XCTAssertEqual(callCount, 0)
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
