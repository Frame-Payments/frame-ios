//
//  FrameApplePayButton.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/2/25.

import SwiftUI
import PassKit

public struct FrameApplePayButton: View {

    // MARK: - Configuration

    let amount: Int
    let currency: String
    let owner: FrameApplePayViewModel.PaymentMethodOwner
    let merchantId: String
    let buttonType: PKPaymentButtonType
    let buttonStyle: PKPaymentButtonStyle
    let completion: (Result<FrameObjects.ChargeIntent, Error>) -> Void

    @StateObject private var viewModel: FrameApplePayViewModel

    public init(amount: Int,
                currency: String = "usd",
                owner: FrameApplePayViewModel.PaymentMethodOwner,
                merchantId: String,
                buttonType: PKPaymentButtonType = .buy,
                buttonStyle: PKPaymentButtonStyle = .black,
                completion: @escaping (Result<FrameObjects.ChargeIntent, Error>) -> Void) {
        self.amount = amount
        self.currency = currency
        self.owner = owner
        self.merchantId = merchantId
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
        if FrameApplePayViewModel.canMakePayments() {
            PKPaymentButtonWrapper(
                buttonType: buttonType,
                buttonStyle: buttonStyle
            ) {
                viewModel.presentApplePay()
            }
            .frame(height: 50)
            .disabled(viewModel.isProcessing)
        }
        // Renders nothing if Apple Pay is unavailable on this device
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
