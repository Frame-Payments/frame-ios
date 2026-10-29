//
//  FrameAmountKeypad.swift
//  Frame-iOS
//

import SwiftUI

/// Numeric keypad that edits an amount in the currency's smallest unit (cents).
///
/// Digits append from the right (`1`, `2`, `3` → `123` cents / $1.23). Extra digits that would
/// exceed `maxAmount` are ignored. Deposit and payout both use this control.
package struct FrameAmountKeypad: View {
    @Environment(\.frameTheme) private var theme

    @Binding package var cents: Int
    package var maxAmount: Int? = nil

    package init(cents: Binding<Int>, maxAmount: Int? = nil) {
        self._cents = cents
        self.maxAmount = maxAmount
    }

    /// Preset chips shared by deposit and payout. Amounts the keypad would reject stay disabled.
    package static let quickAmounts = [1_000, 2_500, 5_000, 10_000]

    package static func append(digit: Int, to cents: Int, maxAmount: Int?) -> Int {
        guard (0...9).contains(digit) else { return cents }
        if cents > (Int.max - digit) / 10 { return cents }
        let next = cents * 10 + digit
        if let maxAmount, next > maxAmount { return cents }
        return next
    }

    package static func delete(from cents: Int) -> Int {
        cents / 10
    }

    package var body: some View {
        let keys: [Key] = [
            .digit(1), .digit(2), .digit(3),
            .digit(4), .digit(5), .digit(6),
            .digit(7), .digit(8), .digit(9),
            .blank, .digit(0), .backspace
        ]
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3), spacing: 0) {
            ForEach(keys) { key in
                keyButton(key)
            }
        }
    }

    @ViewBuilder
    private func keyButton(_ key: Key) -> some View {
        switch key {
        case .blank:
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 56)
        case .digit(let value):
            Button {
                cents = Self.append(digit: value, to: cents, maxAmount: maxAmount)
            } label: {
                Text("\(value)")
                    .font(theme.fonts.heading)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        case .backspace:
            Button {
                cents = Self.delete(from: cents)
            } label: {
                Image(systemName: "delete.backward")
                    .font(theme.fonts.heading)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private enum Key: Hashable, Identifiable {
        case digit(Int)
        case backspace
        case blank

        var id: String {
            switch self {
            case .digit(let value): return "digit-\(value)"
            case .backspace: return "backspace"
            case .blank: return "blank"
            }
        }
    }
}
