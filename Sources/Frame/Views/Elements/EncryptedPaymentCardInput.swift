//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/11/24.
//

import SwiftUI
import EvervaultInputs

/// A `PaymentCardInputStyle` that renders a themed, encrypted payment card input
/// composed of a card number field above a side-by-side expiry and CVC field,
/// styled according to the active ``FrameTheme``.
public struct EncryptedPaymentCardInput: PaymentCardInputStyle {
    /// Creates an ``EncryptedPaymentCardInput`` style instance.
    public init() {}

    /// Builds the styled body view for the given payment card input configuration.
    ///
    /// - Parameter configuration: The configuration provided by the `PaymentCardInput` environment.
    /// - Returns: A themed view containing the card number, expiry, and CVC fields.
    public func makeBody(configuration: Configuration) -> some View {
        ThemedBody(configuration: configuration)
    }

    private struct ThemedBody: View {
        @Environment(\.frameTheme) private var theme
        let configuration: Configuration

        var body: some View {
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .fill(theme.colors.surface)
                .stroke(theme.colors.surfaceStroke)
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
}

#Preview {
    // Evervault Card Input
    PaymentCardInput(cardData: .constant(PaymentCardData()))
        .paymentCardInputStyle(EncryptedPaymentCardInput())
}

#Preview("Dark") {
    PaymentCardInput(cardData: .constant(PaymentCardData()))
        .paymentCardInputStyle(EncryptedPaymentCardInput())
        .preferredColorScheme(.dark)
}
