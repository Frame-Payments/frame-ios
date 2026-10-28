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

    func appendDigit(_ digit: Int) {
        typedCents = FrameAmountKeypad.append(digit: digit, to: typedCents, maxAmount: maxAmount)
    }

    func deleteDigit() {
        typedCents = FrameAmountKeypad.delete(from: typedCents)
    }
}
