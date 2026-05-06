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
    @Environment(\.frameTheme) private var theme

    @Binding public var cardData: PaymentCardData
    public var showHeaderText: Bool = true

    public init(cardData: Binding<PaymentCardData>, showHeaderText: Bool = true) {
        self._cardData = cardData
        self.showHeaderText = showHeaderText
    }

    public var body: some View {
        VStack(alignment: .leading) {
            if showHeaderText {
                Text("Card Details")
                    .bold()
                    .font(theme.fonts.label)
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
