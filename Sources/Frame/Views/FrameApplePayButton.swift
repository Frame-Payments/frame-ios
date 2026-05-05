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

    @StateObject private var viewModel: FrameApplePayViewModel
    @ObservedObject private var attestationManager = DeviceAttestationManager.shared

    /// Mode-aware initializer. Use `.charge(amount:currency:)` to run the existing checkout flow,
    /// or `.addToOwner` to surface the wallet sheet for one-tap PaymentMethod creation
    /// (no charge intent created).
    public init(mode: FrameApplePayViewModel.FrameApplePayMode,
                owner: FrameApplePayViewModel.PaymentMethodOwner,
                merchantId: String,
                addCheckoutDivider: Bool = false,
                buttonType: PKPaymentButtonType = .buy,
                buttonStyle: PKPaymentButtonStyle = .black,
                completion: @escaping (Result<FrameApplePayViewModel.FrameApplePayResult, Error>) -> Void) {

        self.addCheckoutDivider = addCheckoutDivider
        self.buttonType = buttonType
        self.buttonStyle = buttonStyle
        self.completion = completion

        _viewModel = StateObject(wrappedValue: FrameApplePayViewModel(
            mode: mode,
            owner: owner,
            merchantId: merchantId,
            completion: completion
        ))
    }

    // MARK: - Body

    public var body: some View {
        if FrameApplePayViewModel.canMakePayments() && attestationManager.isDeviceAttested {
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
        // Renders nothing if Apple Pay is unavailable on this device
    }

    var paymentDivider: some View {
        HStack(spacing: 10.0) {
            Rectangle().fill(.gray.opacity(0.3))
                .frame(height: 1)
            Text("Or")
            Rectangle().fill(.gray.opacity(0.3))
                .frame(height: 1)
        }
        .padding()
    }
}

#Preview {
    FrameApplePayButton(
        mode: .charge(amount: 15000, currency: "usd"),
        owner: .customer("cus_preview"),
        merchantId: "merchant.com.yourapp"
    ) { result in
        print(result)
    }
    .padding()
}
