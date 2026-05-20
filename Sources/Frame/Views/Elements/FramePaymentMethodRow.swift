import SwiftUI

public struct FramePaymentMethodRow: View {
    @Environment(\.frameTheme) private var theme

    public let paymentMethod: FrameObjects.PaymentMethod
    public let isSelected: Bool
    public let onTap: () -> Void

    public init(paymentMethod: FrameObjects.PaymentMethod,
                isSelected: Bool,
                onTap: @escaping () -> Void) {
        self.paymentMethod = paymentMethod
        self.isSelected = isSelected
        self.onTap = onTap
    }

    public var body: some View {
        HStack {
            Image(iconName, bundle: FrameResources.module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48.0, height: 32.0)
                .padding(.horizontal)
            VStack(alignment: .leading) {
                Text(primaryText)
                    .bold()
                    .font(theme.fonts.bodySmall)
                    .padding(.bottom, 1.0)
                Text(secondaryText)
                    .font(theme.fonts.caption)
            }
            Spacer()
            Image(isSelected ? "filled-selection" : "empty-selection", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .stroke(isSelected ? theme.colors.textPrimary : theme.colors.surfaceStroke, lineWidth: 1)
        )
        .onTapGesture(perform: onTap)
    }

    private var isACH: Bool {
        paymentMethod.type == .ach
    }

    private var iconName: String {
        if isACH { return "bank-icon" }
        return paymentMethod.card?.brandIconName ?? "CreditCardIcon"
    }

    private var primaryText: String {
        if isACH {
            return "•••• \(paymentMethod.ach?.lastFour ?? "")"
        }
        return "•••• \(paymentMethod.card?.lastFourDigits ?? "")"
    }

    private var secondaryText: String {
        if isACH {
            return "\((paymentMethod.ach?.accountType?.rawValue ?? "").capitalized) Account"
        }
        return "Exp. \(paymentMethod.card?.expirationMonth ?? "")/\(paymentMethod.card?.expirationYear ?? "")"
    }
}
