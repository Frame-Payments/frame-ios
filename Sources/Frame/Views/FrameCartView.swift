//
//  FrameCartView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/27/24.
//

import SwiftUI

public struct FrameCartView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.frameTheme) private var theme
    @ObservedObject var cartViewModel: FrameCartViewModel

    @State var customer: FrameObjects.Customer?
    @State var cartItems: [any FrameCartItem]

    @State var cartViewTitle: String
    @State var subtitle: String
    @State var cartItemHeight: CGFloat
    @State var checkoutButtonTitle: String

    @State var continueToCheckout: Bool = false

    public init(
        customer: FrameObjects.Customer?,
        cartItems: [any FrameCartItem],
        shippingAmountInCents: Int,
        cartViewTitle: String = "Frame Payments",
        subtitle: String = "Cart",
        cartItemHeight: CGFloat = 65.0,
        checkoutButtonTitle: String = "Checkout"
    ) {
        self.cartViewModel = FrameCartViewModel(cartItems: cartItems, shippingAmount: shippingAmountInCents)
        self.customer = customer
        self.cartItems = cartItems
        self.cartViewTitle = cartViewTitle
        self.subtitle = subtitle
        self.cartItemHeight = cartItemHeight
        self.checkoutButtonTitle = checkoutButtonTitle
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                cartTitle
                mainCartView
                checkoutButton
            }
            .navigationDestination(isPresented: $continueToCheckout) {
                FrameCheckoutView(customerId: customer?.id, paymentAmount: cartViewModel.finalTotal, merchantId: "test.merchant.id") { chargeIntent in
                    self.dismiss()
                }
                .toolbar(.hidden)
            }
        }
    }

    @ViewBuilder
    var cartTitle: some View {
        Text(cartViewTitle)
            .font(theme.fonts.title)
            .foregroundColor(theme.colors.textPrimary)
            .padding()
        Divider()
    }

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
    FrameCartView(customer: FrameObjects.Customer(id: "1", created: nil, shippingAddress: nil,
                                                  updated: nil, livemode: false, name: "", phone: nil, email: nil,
                                                  description: nil, object: nil, billingAddress: nil, metadata: nil),
                  cartItems: [],
                  shippingAmountInCents: 1000)
}

#Preview("Dark") {
    FrameCartView(customer: FrameObjects.Customer(id: "1", created: nil, shippingAddress: nil,
                                                  updated: nil, livemode: false, name: "", phone: nil, email: nil,
                                                  description: nil, object: nil, billingAddress: nil, metadata: nil),
                  cartItems: [],
                  shippingAmountInCents: 1000)
        .preferredColorScheme(.dark)
}
