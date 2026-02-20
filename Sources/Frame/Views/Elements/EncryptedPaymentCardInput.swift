//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/11/24.
//

import SwiftUI
import EvervaultInputs

public struct EncryptedPaymentCardInput: PaymentCardInputStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: 10.0)
            .fill(.white)
            .stroke(.gray.opacity(0.3))
            .frame(height: 100.0)
            .overlay {
                VStack(spacing: 0) {
                    configuration.cardNumberField
                        .frame(height: 45.0)
                        .padding(.horizontal)
                    Divider()
                    HStack {
                        configuration.expiryField
                        Divider()
                        configuration.cvcField
                    }
                    .frame(height: 45.0)
                    .padding(.horizontal)
                }
                .frame(height: 91.0)
            }
            .padding(.horizontal)
    }
}

#Preview {
    // Evervault Card Input
    PaymentCardInput(cardData: .constant(PaymentCardData()))
        .paymentCardInputStyle(EncryptedPaymentCardInput())
}
