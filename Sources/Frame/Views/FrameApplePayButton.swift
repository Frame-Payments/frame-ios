//
//  FrameApplePayButton.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/2/25.

import SwiftUI
import PassKit

public struct FrameApplePayButton: View {

    // MARK: - Configuration

    let addCheckoutDivider: Bool
    let buttonType: PKPaymentButtonType
    let buttonStyle: PKPaymentButtonStyle
    let completion: (Result<FrameApplePayViewModel.FrameApplePayResult, Error>) -> Void

    @Environment(\.frameTheme) private var theme
    @StateObject private var viewModel: FrameApplePayViewModel
    @ObservedObject private var attestationManager = DeviceAttestationManager.shared

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

    public var body: some View {
        let merchantConfigured = !(FrameNetworking.shared.applePayMerchantId ?? "").isEmpty
        if merchantConfigured && FrameApplePayViewModel.canMakePayments() && attestationManager.isDeviceAttested {
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
