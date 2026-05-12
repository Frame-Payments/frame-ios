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

    @State var cartItems: [any FrameCartItem]

    @State var cartViewTitle: String
    @State var subtitle: String
    @State var cartItemHeight: CGFloat
    @State var checkoutButtonTitle: String

    @State var continueToCheckout: Bool = false

    private let checkoutCallback: ((_ success: Bool, _ transferId: String?) -> Void)?
    
    var accountId: String
    var merchantId: String

    public init(
        accountId: String,
        merchantId: String? = nil,
        cartItems: [any FrameCartItem],
        shippingAmountInCents: Int,
        cartViewTitle: String = "Frame Payments",
        subtitle: String = "Cart",
        cartItemHeight: CGFloat = 65.0,
        checkoutButtonTitle: String = "Checkout",
        checkoutCallback: ((_ success: Bool, _ transferId: String?) -> Void)? = nil
    ) {
        self.cartViewModel = FrameCartViewModel(cartItems: cartItems, shippingAmount: shippingAmountInCents)
        self.accountId = accountId
        self.merchantId = merchantId ?? "merchant.com.app"
        self.cartItems = cartItems
        self.cartViewTitle = cartViewTitle
        self.subtitle = subtitle
        self.cartItemHeight = cartItemHeight
        self.checkoutButtonTitle = checkoutButtonTitle
        self.checkoutCallback = checkoutCallback
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                cartTitle
                mainCartView
                checkoutButton
            }
            .navigationDestination(isPresented: $continueToCheckout) {
                FrameCheckoutView(accountId: accountId, paymentAmount: cartViewModel.finalTotal, merchantId: merchantId) { success, transferId in
                    self.checkoutCallback?(success, transferId)
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
