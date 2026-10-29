//
//  FrameDepositViewModel.swift
//  Frame-iOS
//

import Foundation

/// Amount state for ``FrameDepositView``. Payment runs in ``FrameCheckoutView`` after the host mints a session.
@MainActor
class FrameDepositViewModel: ObservableObject {
    @Published var typedCents: Int = 0
    @Published var isMinting = false

    static let quickAmounts = FrameAmountKeypad.quickAmounts

    let minAmount: Int?
    let maxAmount: Int?

    init(minAmount: Int? = nil, maxAmount: Int? = nil) {
        self.minAmount = minAmount
        self.maxAmount = maxAmount
    }

    var isAmountInRange: Bool {
        guard typedCents > 0 else { return false }
        if let minAmount, typedCents < minAmount { return false }
        if let maxAmount, typedCents > maxAmount { return false }
        return true
    }

    func isQuickAmountAvailable(_ cents: Int) -> Bool {
        guard cents > 0 else { return false }
        if let minAmount, cents < minAmount { return false }
        if let maxAmount, cents > maxAmount { return false }
        return true
    }

    func applyQuickAmount(_ cents: Int) {
        guard isQuickAmountAvailable(cents) else { return }
        typedCents = cents
    }

    func appendDigit(_ digit: Int) {
        typedCents = FrameAmountKeypad.append(digit: digit, to: typedCents, maxAmount: maxAmount)
    }

    func deleteDigit() {
        typedCents = FrameAmountKeypad.delete(from: typedCents)
    }
}
