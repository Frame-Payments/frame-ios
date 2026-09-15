//
//  FrameApplePayButton.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/2/25.

import SwiftUI
import PassKit

/// A SwiftUI view that renders a PassKit Apple Pay button and drives the Frame Apple Pay checkout flow.
///
/// The button is only visible when Apple Pay is available on the device, the merchant identifier
/// has been configured, and device attestation has succeeded. It renders nothing otherwise,
/// making it safe to include unconditionally in any layout.
///
/// Use ``FrameApplePayViewModel/FrameApplePayMode`` to choose between charging a customer
/// (``.charge(amount:currency:)``) or silently adding a payment method to an owner
/// (``.addToOwner``). Pass a ``FrameApplePayViewModel/PaymentMethodOwner`` to associate the
/// resulting payment method with the correct Frame resource.
public struct FrameApplePayButton: View {

    // MARK: - Configuration

    /// Whether to render an "Or" divider below the Apple Pay button.
    let addCheckoutDivider: Bool
    /// The PassKit button type (e.g. `.buy`, `.checkout`, `.donate`) displayed to the user.
    let buttonType: PKPaymentButtonType
    /// The visual style (`.automatic`, `.white`, `.black`) applied to the PassKit button.
    let buttonStyle: PKPaymentButtonStyle
    /// Callback invoked with the result of the Apple Pay flow once the sheet is dismissed.
    let completion: (Result<FrameApplePayViewModel.FrameApplePayResult, Error>) -> Void

    @Environment(\.frameTheme) private var theme
    @StateObject private var viewModel: FrameApplePayViewModel
    @ObservedObject private var attestationManager = DeviceAttestationManager.shared
    /// Guards the unavailability event so a re-render while still unavailable (e.g. waiting on
    /// attestation) reports the gate once per view instance instead of on every body evaluation.
    @State private var didEmitUnavailable = false

    /// Mode-aware initializer. Use `.charge(amount:currency:)` to run the existing checkout flow,
    /// or `.addToOwner` to surface the wallet sheet for one-tap PaymentMethod creation
    /// (no charge intent created). The Apple Pay merchant identifier is read from
    /// `FrameNetworking.shared.applePayMerchantId` — pass it once at SDK init.
    public init(mode: FrameApplePayViewModel.FrameApplePayMode,
                owner: FrameApplePayViewModel.PaymentMethodOwner,
                addCheckoutDivider: Bool = false,
                buttonType: PKPaymentButtonType = .buy,
                buttonStyle: PKPaymentButtonStyle = .automatic,
                completion: @escaping (Result<FrameApplePayViewModel.FrameApplePayResult, Error>) -> Void) {

        self.addCheckoutDivider = addCheckoutDivider
        self.buttonType = buttonType
        self.buttonStyle = buttonStyle
        self.completion = completion

        _viewModel = StateObject(wrappedValue: FrameApplePayViewModel(
            mode: mode,
            owner: owner,
            completion: completion
        ))
    }

    // MARK: - Body

    /// The view hierarchy: a ``PKPaymentButtonWrapper`` (and optional divider) when all
    /// preconditions are met, or an empty view when Apple Pay is unavailable or unconfigured.
    public var body: some View {
        let merchantConfigured = !(FrameNetworking.shared.applePayMerchantId ?? "").isEmpty
        let canMakePayments = FrameApplePayViewModel.canMakePayments()
        let available = merchantConfigured && canMakePayments && attestationManager.isDeviceAttested
        Group {
            if available {
                PKPaymentButtonWrapper(
                    buttonType: buttonType,
                    buttonStyle: buttonStyle
                ) {
                    viewModel.presentApplePay()
                }
                .frame(height: 50)
                .disabled(viewModel.isProcessing)

                if addCheckoutDivider {
                    paymentDivider
                }
            }
            // Renders nothing if Apple Pay is unavailable on this device or the merchant ID
            // wasn't configured at init.
        }
        .onAppear { emitUnavailableIfNeeded(available: available, merchantConfigured: merchantConfigured, canMakePayments: canMakePayments) }
        .onChange(of: attestationManager.isDeviceAttested) { _, _ in
            emitUnavailableIfNeeded(available: available, merchantConfigured: merchantConfigured, canMakePayments: canMakePayments)
        }
    }

    /// Reports which gate blocked the button, once per view instance (unless the gate outcome
    /// changes, e.g. attestation finishing after the button first appeared unavailable).
    private func emitUnavailableIfNeeded(available: Bool, merchantConfigured: Bool, canMakePayments: Bool) {
        guard !available, !didEmitUnavailable else { return }
        didEmitUnavailable = true
        let reason: String
        if !merchantConfigured {
            reason = "merchant id"
        } else if !canMakePayments {
            reason = "canMakePayments"
        } else {
            reason = "attestation"
        }
        AccountEventEmitter.emit(name: "apple_pay_unavailable", screen: "ApplePay", detail: reason)
    }

    /// A horizontal "Or" divider rendered between the Apple Pay button and other payment options.
    var paymentDivider: some View {
        HStack(spacing: 10.0) {
            Rectangle().fill(theme.colors.surfaceStroke)
                .frame(height: 1)
            Text("Or")
            Rectangle().fill(theme.colors.surfaceStroke)
                .frame(height: 1)
        }
        .padding()
    }
}

#Preview {
    FrameApplePayButton(
        mode: .charge(amount: 15000, currency: "usd"),
        owner: .account("acc_preview")
    ) { result in
        print(result)
    }
    .padding()
}

#Preview("Dark") {
    FrameApplePayButton(
        mode: .charge(amount: 15000, currency: "usd"),
        owner: .account("acc_preview")
    ) { result in
        print(result)
    }
    .padding()
    .preferredColorScheme(.dark)
}
