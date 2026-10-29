//
//  FramePayoutViewModel.swift
//  Frame-iOS
//

import Frame
import Foundation

/// Amount and destination state for ``FramePayoutView``.
///
/// Decides whether the typed cents and the selected bank are enough to create the transfer.
@MainActor
class FramePayoutViewModel: ObservableObject {
    @Published var typedCents: Int = 0
    @Published var payoutMethods: [FrameObjects.PaymentMethod] = []
    @Published var selectedPaymentMethodId: String?
    @Published var isCreating = false
    @Published var isLoadingMethods = false
    @Published var didLoadMethods = false

    static let quickAmounts = FrameAmountKeypad.quickAmounts

    /// Withdrawable balance in cents. Digits past this cap are ignored.
    let availableAmount: Int

    init(availableAmount: Int) {
        self.availableAmount = max(0, availableAmount)
    }

    var isAmountInRange: Bool {
        typedCents > 0 && typedCents <= availableAmount
    }

    var selectedPaymentMethod: FrameObjects.PaymentMethod? {
        guard let selectedPaymentMethodId else { return nil }
        return payoutMethods.first { $0.id == selectedPaymentMethodId }
    }

    /// Confirm needs a positive amount within the cap and a bank that is still in the list.
    var canConfirm: Bool {
        isAmountInRange && selectedPaymentMethod != nil && !isLoadingMethods
    }

    var amountText: String {
        CurrencyFormatter.shared.convertCentsToCurrencyString(typedCents)
    }

    var availableText: String {
        CurrencyFormatter.shared.convertCentsToCurrencyString(availableAmount)
    }

    func isQuickAmountAvailable(_ cents: Int) -> Bool {
        cents > 0 && cents <= availableAmount
    }

    func applyQuickAmount(_ cents: Int) {
        guard isQuickAmountAvailable(cents) else { return }
        typedCents = cents
    }

    func appendDigit(_ digit: Int) {
        typedCents = FrameAmountKeypad.append(digit: digit, to: typedCents, maxAmount: availableAmount)
    }

    func deleteDigit() {
        typedCents = FrameAmountKeypad.delete(from: typedCents)
    }

    /// Keeps a bank the user already picked. Otherwise prefills the elected primary, or the only bank.
    func applyLoadedMethods(_ methods: [FrameObjects.PaymentMethod], primaryId: String?) {
        let banks = methods.filter { $0.ach != nil }
        payoutMethods = banks
        didLoadMethods = true
        if let selectedPaymentMethodId, banks.contains(where: { $0.id == selectedPaymentMethodId }) {
            return
        }
        if let primaryId, banks.contains(where: { $0.id == primaryId }) {
            selectedPaymentMethodId = primaryId
            return
        }
        selectedPaymentMethodId = banks.count == 1 ? banks[0].id : nil
    }

    func selectElected(_ id: String) {
        guard !id.isEmpty else { return }
        selectedPaymentMethodId = id
    }
}
