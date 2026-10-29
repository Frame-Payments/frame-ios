//
//  PayoutViewModelTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame
@testable import FrameOnboarding

final class PayoutViewModelTests: XCTestCase {
    private func bank(_ id: String) -> FrameObjects.PaymentMethod {
        FrameObjects.PaymentMethod(
            id: id,
            type: .ach,
            object: "payment_method",
            created: 0,
            updated: 0,
            livemode: false,
            ach: .init(accountType: .checking, lastFour: "6789"),
            status: .active
        )
    }

    private func card(_ id: String) -> FrameObjects.PaymentMethod {
        FrameObjects.PaymentMethod(
            id: id,
            type: .card,
            object: "payment_method",
            created: 0,
            updated: 0,
            livemode: false,
            status: .active
        )
    }

    @MainActor
    func testZeroAndAboveAvailableCannotConfirm() {
        let vm = FramePayoutViewModel(availableAmount: 5_000)
        XCTAssertEqual(vm.typedCents, 0)
        XCTAssertFalse(vm.isAmountInRange)
        XCTAssertFalse(vm.canConfirm)

        vm.applyLoadedMethods([bank("pm_1")], primaryId: "pm_1")
        XCTAssertEqual(vm.selectedPaymentMethodId, "pm_1")
        XCTAssertFalse(vm.canConfirm)

        vm.appendDigit(5)
        vm.appendDigit(0)
        vm.appendDigit(0)
        vm.appendDigit(0)
        XCTAssertEqual(vm.typedCents, 5_000)
        XCTAssertTrue(vm.canConfirm)

        vm.appendDigit(1)
        XCTAssertEqual(vm.typedCents, 5_000)
        XCTAssertTrue(vm.canConfirm)

        vm.isLoadingMethods = true
        XCTAssertFalse(vm.canConfirm)
        vm.isLoadingMethods = false
        XCTAssertTrue(vm.canConfirm)

        vm.typedCents = 5_001
        XCTAssertFalse(vm.isAmountInRange)
        XCTAssertFalse(vm.canConfirm)
    }

    @MainActor
    func testNegativeAvailableClampsToZero() {
        let vm = FramePayoutViewModel(availableAmount: -100)
        XCTAssertEqual(vm.availableAmount, 0)
        vm.appendDigit(1)
        XCTAssertEqual(vm.typedCents, 0)
        XCTAssertFalse(vm.isAmountInRange)
    }

    @MainActor
    func testQuickAmountsHonorTheCap() {
        XCTAssertEqual(FramePayoutViewModel.quickAmounts, FrameAmountKeypad.quickAmounts)

        let vm = FramePayoutViewModel(availableAmount: 5_000)
        XCTAssertTrue(vm.isQuickAmountAvailable(1_000))
        XCTAssertTrue(vm.isQuickAmountAvailable(5_000))
        XCTAssertFalse(vm.isQuickAmountAvailable(10_000))

        vm.applyQuickAmount(10_000)
        XCTAssertEqual(vm.typedCents, 0)

        vm.applyQuickAmount(2_500)
        XCTAssertEqual(vm.typedCents, 2_500)
        XCTAssertTrue(vm.isAmountInRange)
    }

    @MainActor
    func testDeleteDigitReturnsToZero() {
        let vm = FramePayoutViewModel(availableAmount: 5_000)
        vm.appendDigit(1)
        vm.appendDigit(2)
        vm.deleteDigit()
        XCTAssertEqual(vm.typedCents, 1)
        vm.deleteDigit()
        vm.deleteDigit()
        XCTAssertEqual(vm.typedCents, 0)
        XCTAssertFalse(vm.isAmountInRange)
    }

    @MainActor
    func testLoadedMethodsDropCardsAndPrefillPrimary() {
        let vm = FramePayoutViewModel(availableAmount: 5_000)
        XCTAssertFalse(vm.didLoadMethods)

        vm.applyLoadedMethods([card("card_1"), bank("pm_a"), bank("pm_b")], primaryId: "pm_b")
        XCTAssertTrue(vm.didLoadMethods)
        XCTAssertEqual(vm.payoutMethods.map(\.id), ["pm_a", "pm_b"])
        XCTAssertEqual(vm.selectedPaymentMethodId, "pm_b")
        XCTAssertEqual(vm.selectedPaymentMethod?.id, "pm_b")
    }

    @MainActor
    func testSoleBankIsSelectedWhenNoPrimaryIsSet() {
        let vm = FramePayoutViewModel(availableAmount: 5_000)
        vm.applyLoadedMethods([bank("pm_only"), card("card_1")], primaryId: nil)
        XCTAssertEqual(vm.selectedPaymentMethodId, "pm_only")
        XCTAssertFalse(vm.canConfirm)
    }

    @MainActor
    func testSeveralBanksStayUnselectedWithoutAPrimary() {
        let vm = FramePayoutViewModel(availableAmount: 5_000)
        vm.applyLoadedMethods([bank("pm_a"), bank("pm_b")], primaryId: "missing")
        XCTAssertNil(vm.selectedPaymentMethodId)
        vm.typedCents = 100
        XCTAssertFalse(vm.canConfirm)
    }

    @MainActor
    func testReloadKeepsAnElectedBankOverThePrimary() {
        let vm = FramePayoutViewModel(availableAmount: 5_000)
        vm.applyLoadedMethods([bank("pm_a"), bank("pm_b")], primaryId: "pm_a")
        XCTAssertEqual(vm.selectedPaymentMethodId, "pm_a")

        vm.selectElected("pm_b")
        vm.applyLoadedMethods([bank("pm_a"), bank("pm_b")], primaryId: "pm_a")
        XCTAssertEqual(vm.selectedPaymentMethodId, "pm_b")
    }

    @MainActor
    func testEmptyElectionIdIsIgnored() {
        let vm = FramePayoutViewModel(availableAmount: 5_000)
        vm.selectElected("")
        XCTAssertNil(vm.selectedPaymentMethodId)
    }

    @MainActor
    func testStaleSelectionClearsWhenTheBankIsGone() {
        let vm = FramePayoutViewModel(availableAmount: 5_000)
        vm.selectElected("pm_gone")
        vm.applyLoadedMethods([bank("pm_a"), bank("pm_b")], primaryId: nil)
        XCTAssertNil(vm.selectedPaymentMethodId)
    }
}
