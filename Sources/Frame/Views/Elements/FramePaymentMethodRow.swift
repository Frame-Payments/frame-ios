import SwiftUI

/// A SwiftUI view that renders a single selectable payment method row.
///
/// Displays the payment method's brand or bank icon, masked account number, and
/// expiration or account-type details. A selection indicator is shown when the
/// row is the currently chosen payment method. Tapping the row invokes `onTap`.
public struct FramePaymentMethodRow: View {
    @Environment(\.frameTheme) private var theme

    /// The payment method data to display in this row.
    public let paymentMethod: FrameObjects.PaymentMethod

    /// Whether this row is currently selected.
    public let isSelected: Bool

    /// Closure invoked when the user taps the row.
    public let onTap: () -> Void

    /// Creates a new payment method row.
    ///
    /// - Parameters:
    ///   - paymentMethod: The payment method whose details are rendered.
    ///   - isSelected: Pass `true` to render the row in its selected state.
    ///   - onTap: Closure called when the user taps the row.
    public init(paymentMethod: FrameObjects.PaymentMethod,
                isSelected: Bool,
                onTap: @escaping () -> Void) {
        self.paymentMethod = paymentMethod
        self.isSelected = isSelected
        self.onTap = onTap
    }

    /// The content and layout of the payment method row.
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

    /// Returns `true` when the payment method is an ACH bank account.
    private var isACH: Bool {
        paymentMethod.type == .ach
    }

    /// The asset name of the icon representing the payment method's brand or bank.
    private var iconName: String {
        if isACH { return "bank-icon" }
        return paymentMethod.card?.brandIconName ?? "CreditCardIcon"
    }

    /// The masked account or card number shown as the row's primary label.
    private var primaryText: String {
        if isACH {
            return "•••• \(paymentMethod.ach?.lastFour ?? "")"
        }
        return "•••• \(paymentMethod.card?.lastFourDigits ?? "")"
    }

    /// The account type (ACH) or expiration date (card) shown as the row's secondary label.
    private var secondaryText: String {
        if isACH {
            return "\((paymentMethod.ach?.accountType?.rawValue ?? "").capitalized) Account"
        }
        return "Exp. \(paymentMethod.card?.expirationMonth ?? "")/\(paymentMethod.card?.expirationYear ?? "")"
    }
}
