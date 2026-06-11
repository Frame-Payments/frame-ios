//
//  FrameCartView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/27/24.
//

import SwiftUI

/// A SwiftUI view that displays a shopping cart with line items, subtotal, shipping, and a
/// checkout button, then navigates to ``FrameCheckoutView`` to complete the payment.
public struct FrameCartView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.frameTheme) private var theme
    @ObservedObject var cartViewModel: FrameCartViewModel

    /// The list of cart items currently displayed in the view.
    @State var cartItems: [any FrameCartItem]

    /// The navigation-bar title rendered at the top of the cart sheet.
    @State var cartViewTitle: String

    /// A secondary heading shown above the list of cart items.
    @State var subtitle: String

    /// The fixed height applied to each cart-item row.
    @State var cartItemHeight: CGFloat

    /// The label displayed on the primary checkout action button.
    @State var checkoutButtonTitle: String

    @State var continueToCheckout: Bool = false
    @State private var didFinish = false

    private let onResult: ((FrameResult) -> Void)?

    /// The Frame account identifier used to scope the checkout session.
    var accountId: String

    /// Creates a ``FrameCartView`` pre-populated with the provided cart items and shipping cost.
    ///
    /// - Parameters:
    ///   - accountId: The Frame account identifier used to initiate the checkout session.
    ///   - cartItems: An array of items conforming to ``FrameCartItem`` to display in the cart.
    ///   - shippingAmountInCents: The shipping cost in the smallest currency unit (e.g. cents).
    ///   - cartViewTitle: The title shown in the navigation bar. Defaults to `"Frame Payments"`.
    ///   - subtitle: A secondary heading rendered above the item list. Defaults to `"Cart"`.
    ///   - cartItemHeight: The fixed height for each item row. Defaults to `65.0`.
    ///   - checkoutButtonTitle: The label on the checkout button. Defaults to `"Checkout"`.
    ///   - onResult: An optional closure called when the cart flow finishes, providing a
    ///     ``FrameResult`` that indicates completion, failure, or cancellation.
    public init(
        accountId: String,
        cartItems: [any FrameCartItem],
        shippingAmountInCents: Int,
        cartViewTitle: String = "Frame Payments",
        subtitle: String = "Cart",
        cartItemHeight: CGFloat = 65.0,
        checkoutButtonTitle: String = "Checkout",
        onResult: ((FrameResult) -> Void)? = nil
    ) {
        self.cartViewModel = FrameCartViewModel(cartItems: cartItems, shippingAmount: shippingAmountInCents)
        self.accountId = accountId
        self.cartItems = cartItems
        self.cartViewTitle = cartViewTitle
        self.subtitle = subtitle
        self.cartItemHeight = cartItemHeight
        self.checkoutButtonTitle = checkoutButtonTitle
        self.onResult = onResult
    }

    /// The root view hierarchy for the cart screen.
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                cartTitle
                mainCartView
                checkoutButton
            }
            .navigationDestination(isPresented: $continueToCheckout) {
                FrameCheckoutView(accountId: accountId, paymentAmount: cartViewModel.finalTotal) { result in
                    // Map the inner checkout's result into the cart's result. Treat the inner
                    // `.cancelled` (user backs out of checkout) as a return to the cart rather
                    // than terminating the cart flow — the cart sheet stays open and emits its
                    // own `.cancelled` only when the cart itself is dismissed.
                    switch result {
                    case .completed(let transferId):
                        didFinish = true
                        onResult?(.completed(id: transferId))
                        dismiss()
                    case .failed(let error):
                        didFinish = true
                        onResult?(.failed(error))
                        dismiss()
                    case .cancelled:
                        continueToCheckout = false
                    }
                }
                .toolbar(.hidden)
            }
        }
        .frameToastOverlay()
        .onDisappear {
            if !didFinish {
                didFinish = true
                onResult?(.cancelled)
            }
        }
    }

    /// A view that renders the styled cart title and a divider beneath it.
    @ViewBuilder
    var cartTitle: some View {
        Text(cartViewTitle)
            .font(theme.fonts.title)
            .foregroundColor(theme.colors.textPrimary)
            .padding()
        Divider()
    }

    /// A scrollable view containing the subtitle, item rows, and the subtotal/shipping/total summary.
    @ViewBuilder
    var mainCartView: some View {
        ScrollView {
            HStack {
                Text(subtitle)
                    .multilineTextAlignment(.leading)
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.colors.textPrimary)
                    .padding()
                Spacer()
            }
            ForEach(cartItems, id: \.id) { item in
                cartItemView(item)
                    .frame(height: cartItemHeight)
            }
            HStack {
                Text("Subtotal")
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.colors.textSecondary)
                Spacer()
                Text(CurrencyFormatter.shared.convertCentsToCurrencyString(cartViewModel.subtotal))
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding()
            HStack {
                Text("Shipping")
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.colors.textSecondary)
                Spacer()
                Text(CurrencyFormatter.shared.convertCentsToCurrencyString(cartViewModel.shippingAmount))
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding([.horizontal, .bottom])
            Divider()
            HStack {
                Text("Total")
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Text(CurrencyFormatter.shared.convertCentsToCurrencyString(cartViewModel.finalTotal))
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .padding()
            Spacer()
        }
    }

    /// Builds a single row view for the given cart item, showing its image, title, and price.
    ///
    /// - Parameter item: The cart item to render.
    /// - Returns: A styled `HStack` row representing the item.
    func cartItemView(_ item: any FrameCartItem) -> some View {
        HStack {
            AsyncImage(url: URL(string: item.imageURL)) { image in
                image
                    .resizable()
                    .frame(width: 40.0, height: 40.0)
                    .aspectRatio(contentMode: .fill)
                    .padding()
            } placeholder: {
                Color.gray
            }
            .frame(width: 40.0, height: 40.0)
            .padding(.leading)
            Text(item.title)
                .font(theme.fonts.headline)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            Text(CurrencyFormatter.shared.convertCentsToCurrencyString(item.amountInCents))
                .font(theme.fonts.headline)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.trailing)
        }
        .frame(height: cartItemHeight)
        .cornerRadius(theme.radii.medium)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .stroke(theme.colors.surfaceStroke, lineWidth: 1)
        )
        .padding(.horizontal)
    }

    /// A full-width button that advances the navigation stack to ``FrameCheckoutView``.
    var checkoutButton: some View {
        Button {
            self.continueToCheckout = true
        } label: {
            Text(checkoutButtonTitle)
                .font(theme.fonts.button)
                .foregroundColor(theme.colors.primaryButtonText)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 42.0)
        .frame(maxWidth: .infinity)
        .background(theme.colors.primaryButton)
        .cornerRadius(theme.radii.medium)
        .padding(.horizontal)
    }
}

#Preview {
    FrameCartView(accountId: "acc_1",
                  cartItems: [],
                  shippingAmountInCents: 1000)
}

#Preview("Dark") {
    FrameCartView(accountId: "acc_1",
                  cartItems: [],
                  shippingAmountInCents: 1000)
        .preferredColorScheme(.dark)
}
