//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/11/24.
//

import SwiftUI

/// The payment method displayed by a ``FramePaymentButton``.
public enum PaymentButtonOption {
    /// Renders an Apple Pay logo on the button.
    case apple
    /// Renders a Google Pay logo on the button.
    case google

    func imageName(blackButton: Bool) -> String {
        switch self {
        case .apple:
            blackButton ? "ApplePayWhite": "ApplePayBlack"
        case .google:
            blackButton ? "GooglePayWhite" : "GooglePayBlack"
        }
    }
}

/// A branded payment button that renders an Apple Pay or Google Pay logo inside a rounded rectangle.
///
/// Use `FramePaymentButton` wherever you need a consistently styled payment call-to-action in your
/// checkout flow. Supply the desired ``PaymentButtonOption`` and a closure that fires when the
/// user taps the button.
///
/// ```swift
/// FramePaymentButton(blackButton: true, paymentOption: .apple) {
///     startApplePaySession()
/// }
/// ```
public struct FramePaymentButton: View {
    /// Whether the button uses a black background (`true`) or a white background (`false`).
    var blackButton: Bool
    /// The payment method whose logo is displayed on the button.
    var paymentOption: PaymentButtonOption
    /// The closure invoked when the user taps the button.
    var paymentButtonAction: () -> Void

    /// Creates a `FramePaymentButton`.
    /// - Parameters:
    ///   - blackButton: Pass `true` for a black button with a white logo; pass `false` for a white button with a dark logo.
    ///   - paymentOption: The payment provider whose branding is shown on the button.
    ///   - paymentButtonAction: The closure called when the user taps the button.
    public init(blackButton: Bool, paymentOption: PaymentButtonOption, paymentButtonAction: @escaping () -> Void) {
        self.blackButton = blackButton
        self.paymentOption = paymentOption
        self.paymentButtonAction = paymentButtonAction
    }

    /// The view hierarchy that renders the branded payment button.
    public var body: some View {
        Button {
            paymentButtonAction()
        } label: {
            RoundedRectangle(cornerRadius: 10.0)
                .fill(blackButton ? .black : .white)
                .overlay {
                    if let image = UIImage(named: paymentOption.imageName(blackButton: blackButton),
                                           in: FrameResources.module, with: nil) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 30)
                    }
                }
        }
        .frame(height: 50.0)
        .padding(.horizontal)
    }
}

#Preview {
    FramePaymentButton(blackButton: true, paymentOption: .apple) { print("Payment Button Pressed") }
}
