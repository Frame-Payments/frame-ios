//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/11/24.
//

import SwiftUI

public enum PaymentButtonOption {
    case apple
    case google
}

public struct FramePaymentButton: View {
    var blackButton: Bool
    var paymentOption: PaymentButtonOption
    var paymentButtonAction: () -> Void
    
    public var body: some View {
        Button {
            paymentButtonAction()
        } label: {
            RoundedRectangle(cornerRadius: 10.0)
                .fill(blackButton ? .black : .white)
                .overlay {
                    switch paymentOption {
                    case .apple:
                        if let image = UIImage(named: blackButton ? "ApplePayWhite" : "ApplePayBlack",
                                               in: Bundle.module, with: nil) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 30)
                        }
                    case .google:
                        if let image = UIImage(named: blackButton ? "GooglePayWhite" : "GooglePayBlack",
                                               in: Bundle.module, with: nil) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 30)
                        }
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
