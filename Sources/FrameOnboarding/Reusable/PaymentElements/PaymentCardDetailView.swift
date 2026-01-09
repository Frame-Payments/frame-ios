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
    @Binding var cardData: PaymentCardData
    
    @State var headerFont: Font = Font.subheadline
    
    public var body: some View {
        VStack(alignment: .leading) {
            Text("Card Details")
                .bold()
                .font(headerFont)
                .padding([.horizontal])
            PaymentCardInput(cardData: $cardData)
                .paymentCardInputStyle(EncryptedPaymentCardInput())
        }
    }
}

#Preview {
    PaymentCardDetailView(cardData: .constant(PaymentCardData()))
}
