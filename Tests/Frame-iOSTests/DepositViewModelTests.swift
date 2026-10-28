//
//  DepositViewModelTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame

final class DepositViewModelTests: XCTestCase {
    @MainActor
    func testZeroAndBelowMinAreOutOfRange() {
        let vm = FrameDepositViewModel(minAmount: 500)
        XCTAssertEqual(vm.typedCents, 0)
        XCTAssertFalse(vm.isAmountInRange)

        vm.appendDigit(0)
        XCTAssertEqual(vm.typedCents, 0)
        XCTAssertFalse(vm.isAmountInRange)

        vm.appendDigit(4)
        vm.appendDigit(9)
        vm.appendDigit(9)
        XCTAssertEqual(vm.typedCents, 499)
        XCTAssertFalse(vm.isAmountInRange)

        vm.appendDigit(0)
        XCTAssertEqual(vm.typedCents, 4990)
        XCTAssertTrue(vm.isAmountInRange)
    }

    @MainActor
    func testMinAmountEnablesAtTheBound() {
        let vm = FrameDepositViewModel(minAmount: 500)
        vm.appendDigit(5)
        vm.appendDigit(0)
        vm.appendDigit(0)
        XCTAssertEqual(vm.typedCents, 500)
        XCTAssertTrue(vm.isAmountInRange)
    }

    @MainActor
    func testNilBoundsAcceptAnyPositiveAmount() {
        let vm = FrameDepositViewModel()
        XCTAssertFalse(vm.isAmountInRange)
        vm.appendDigit(1)
        XCTAssertTrue(vm.isAmountInRange)
        vm.typedCents = 50_000
        XCTAssertTrue(vm.isAmountInRange)
    }

    @MainActor
    func testKeypadIgnoresDigitsAboveMax() {
        let vm = FrameDepositViewModel(maxAmount: 100)
        vm.appendDigit(1)
        vm.appendDigit(0)
        vm.appendDigit(0)
        XCTAssertEqual(vm.typedCents, 100)
        XCTAssertTrue(vm.isAmountInRange)

        vm.appendDigit(0)
        XCTAssertEqual(vm.typedCents, 100)
        XCTAssertTrue(vm.isAmountInRange)

        vm.typedCents = 101
        XCTAssertFalse(vm.isAmountInRange)
    }

    @MainActor
    func testAmountAboveMaxAndBelowMinWhenBothBoundsSet() {
        let vm = FrameDepositViewModel(minAmount: 500, maxAmount: 1_000)
        vm.typedCents = 499
        XCTAssertFalse(vm.isAmountInRange)
        vm.typedCents = 500
        XCTAssertTrue(vm.isAmountInRange)
        vm.typedCents = 1_000
        XCTAssertTrue(vm.isAmountInRange)
        vm.typedCents = 1_001
        XCTAssertFalse(vm.isAmountInRange)

        vm.typedCents = 100
        vm.appendDigit(1)
        XCTAssertEqual(vm.typedCents, 100)
    }

    @MainActor
    func testDeleteDigitAndBackspaceToZero() {
        let vm = FrameDepositViewModel(maxAmount: 100)
        vm.appendDigit(1)
        vm.appendDigit(0)
        vm.appendDigit(0)
        XCTAssertEqual(vm.typedCents, 100)
        vm.deleteDigit()
        XCTAssertEqual(vm.typedCents, 10)
        vm.deleteDigit()
        vm.deleteDigit()
        XCTAssertEqual(vm.typedCents, 0)
        XCTAssertFalse(vm.isAmountInRange)
    }

    @MainActor
    func testAppendIgnoresDigitThatWouldOverflow() {
        let vm = FrameDepositViewModel()
        let saturated = (Int.max - 9) / 10 + 1
        vm.typedCents = saturated
        vm.appendDigit(9)
        XCTAssertEqual(vm.typedCents, saturated)
        XCTAssertEqual(FrameAmountKeypad.append(digit: 9, to: saturated, maxAmount: nil), saturated)
        XCTAssertEqual(FrameAmountKeypad.append(digit: 3, to: 12, maxAmount: 100), 12)
        XCTAssertEqual(FrameAmountKeypad.delete(from: 0), 0)
    }
}
