//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import EvervaultInputs
import Frame

/// A SwiftUI view that renders a payment card entry form with an optional "Card Details" header.
///
/// Wrap this view in a parent form or sheet to collect encrypted card data from the user.
/// Card input is handled by `PaymentCardInput` using the Evervault encrypted input component,
/// and the result is written back through the `cardData` binding.
public struct PaymentCardDetailView: View {
    @Environment(\.frameTheme) private var theme

    /// The card data collected from the user, updated in real time as the user types.
    @Binding public var cardData: PaymentCardData

    /// Controls whether the "Card Details" section header is displayed above the input field.
    public var showHeaderText: Bool = true

    /// Creates a payment card detail view.
    /// - Parameters:
    ///   - cardData: A binding to the `PaymentCardData` value that receives live card input.
    ///   - showHeaderText: Pass `false` to hide the "Card Details" header label. Defaults to `true`.
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
