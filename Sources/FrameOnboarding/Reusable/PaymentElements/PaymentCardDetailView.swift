//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import EvervaultInputs
import Frame

public struct PaymentCardDetailView: View {
    @Binding public var cardData: PaymentCardData
    
    @State public var headerFont: Font = Font.subheadline
    @State public var showHeaderText: Bool = true
    
    public var body: some View {
        VStack(alignment: .leading) {
            if showHeaderText {
                Text("Card Details")
                    .bold()
                    .font(headerFont)
                    .padding([.horizontal])
            }
            PaymentCardInput(cardData: $cardData)
                .paymentCardInputStyle(EncryptedPaymentCardInput())
        }
    }
}

#Preview {
    VStack {
        PaymentCardDetailView(cardData: .constant(PaymentCardData()))
        PaymentCardDetailView(cardData: .constant(PaymentCardData()), showHeaderText: false)
    }
}
