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
    let completion: (Result<FrameObjects.ChargeIntent, Error>) -> Void

    @StateObject private var viewModel: FrameApplePayViewModel
    @ObservedObject private var attestationManager = DeviceAttestationManager.shared

    public init(amount: Int,
                currency: String = "usd",
                owner: FrameApplePayViewModel.PaymentMethodOwner,
                merchantId: String,
                addCheckoutDivider: Bool = false,
                buttonType: PKPaymentButtonType = .buy,
                buttonStyle: PKPaymentButtonStyle = .black,
                completion: @escaping (Result<FrameObjects.ChargeIntent, Error>) -> Void) {

        self.addCheckoutDivider = addCheckoutDivider
        self.buttonType = buttonType
        self.buttonStyle = buttonStyle
        self.completion = completion

        _viewModel = StateObject(wrappedValue: FrameApplePayViewModel(
            amount: amount,
            currency: currency,
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
        amount: 15000,
        owner: .customer("cus_preview"),
        merchantId: "merchant.com.yourapp"
    ) { result in
        print(result)
    }
    .padding()
}
