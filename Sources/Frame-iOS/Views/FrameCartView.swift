//
//  FrameCartView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/27/24.
//

import SwiftUI

public struct FrameCartView: View {
    @ObservedObject var cartViewModel: FrameCartViewModel
    
    @State var customer: FrameObjects.Customer
    @State var cartItems: [any FrameCartItem]
    
    // Customizable Attributes
    @State var backgroundColor: Color
    
    // Cart Title
    @State var cartViewTitle: String
    @State var cartViewTitleFont: Font
    @State var cartViewTitleForegroundColor: Color
    
    // Cart Subtitle
    @State var subtitle: String
    @State var subtitleFont: Font
    @State var subtitleForegroundColor: Color
    
    // Cart Item
    @State var cartItemFont: Font
    @State var cartItemForegroundColor: Color
    @State var cartItemBackgroundColor: Color
    @State var cartItemBorderColor: Color
    @State var cartItemHeight: CGFloat
    
    //Auxiliary Titles
    @State var auxiliaryTitleFont: Font
    @State var auxiliaryTitleForegroundColor: Color
    
    //Total Title
    @State var totalFont: Font
    @State var totalForegroundColor: Color
    
    // Checkout Button
    @State var checkoutButtonTitle: String
    @State var checkoutButtonFont: Font
    @State var checkoutButtonBackgroundColor: Color
    @State var checkoutButtonForegroundColor: Color
    
    @State var continueToCheckout: Bool = false
    
    public init(customer: FrameObjects.Customer, cartItems: [any FrameCartItem], shippingAmountInCents: Int, backgroundColor: Color = .white, cartViewTitle: String = "Frame Payments", cartViewTitleFont: Font = .title, cartViewTitleForegroundColor: Color = .black, subtitle: String = "Cart", subtitleFont: Font = .headline, subtitleForegroundColor: Color = .black, cartItemFont: Font = .headline, cartItemForegroundColor: Color = .black, cartItemBackgroundColor: Color = .clear, cartItemBorderColor: Color = .gray, cartItemHeight: CGFloat = 65.0, auxiliaryTitleFont: Font = .headline, auxiliaryTitleForegroundColor: Color = .gray, totalFont: Font = .headline, totalForegroundColor: Color = .black, checkoutButtonTitle: String = "Checkout", checkoutButtonFont: Font = .headline, checkoutButtonBackgroundColor: Color = .black, checkoutButtonForegroundColor: Color = .white) {
        
        self.cartViewModel = FrameCartViewModel(cartItems: cartItems, shippingAmount: shippingAmountInCents)
        self.customer = customer
        self.cartItems = cartItems
        self.backgroundColor = backgroundColor
        self.cartViewTitle = cartViewTitle
        self.cartViewTitleFont = cartViewTitleFont
        self.cartViewTitleForegroundColor = cartViewTitleForegroundColor
        self.subtitle = subtitle
        self.subtitleFont = subtitleFont
        self.subtitleForegroundColor = subtitleForegroundColor
        self.cartItemFont = cartItemFont
        self.cartItemForegroundColor = cartItemForegroundColor
        self.cartItemBackgroundColor = cartItemBackgroundColor
        self.cartItemBorderColor = cartItemBorderColor
        self.cartItemHeight = cartItemHeight
        self.auxiliaryTitleFont = auxiliaryTitleFont
        self.auxiliaryTitleForegroundColor = auxiliaryTitleForegroundColor
        self.totalFont = totalFont
        self.totalForegroundColor = totalForegroundColor
        self.checkoutButtonTitle = checkoutButtonTitle
        self.checkoutButtonFont = checkoutButtonFont
        self.checkoutButtonBackgroundColor = checkoutButtonBackgroundColor
        self.checkoutButtonForegroundColor = checkoutButtonForegroundColor
    }
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                cartTitle
                mainCartView
                checkoutButton
            }
            .navigationDestination(isPresented: $continueToCheckout) {
                FrameCheckoutView(customerId: customer.id, paymentAmount: cartViewModel.finalTotal)
            }
        }
    }
    
    @ViewBuilder
    var cartTitle: some View {
        Text(cartViewTitle)
            .font(cartViewTitleFont)
            .foregroundColor(cartViewTitleForegroundColor)
            .padding()
        Divider()
    }
    
    @ViewBuilder
    var mainCartView: some View {
        ScrollView {
            HStack {
                Text(subtitle)
                    .multilineTextAlignment(.leading)
                    .font(subtitleFont)
                    .foregroundColor(subtitleForegroundColor)
                    .padding()
                Spacer()
            }
            ForEach(cartItems, id: \.id) { item in
                cartItemView(item)
                    .frame(height: cartItemHeight)
            }
            HStack {
                Text("Subtotal")
                    .font(auxiliaryTitleFont)
                    .foregroundColor(auxiliaryTitleForegroundColor)
                Spacer()
                Text(CurrencyFormatter.shared.convertCentsToCurrencyString(cartViewModel.subtotal))
                    .font(auxiliaryTitleFont)
                    .foregroundColor(auxiliaryTitleForegroundColor)
            }
            .padding()
            HStack {
                Text("Shipping")
                    .font(auxiliaryTitleFont)
                    .foregroundColor(auxiliaryTitleForegroundColor)
                Spacer()
                Text(CurrencyFormatter.shared.convertCentsToCurrencyString(cartViewModel.shippingAmount))
                    .font(auxiliaryTitleFont)
                    .foregroundColor(auxiliaryTitleForegroundColor)
            }
            .padding([.horizontal, .bottom])
            Divider()
            HStack {
                Text("Total")
                    .font(totalFont)
                    .foregroundColor(totalForegroundColor)
                Spacer()
                Text(CurrencyFormatter.shared.convertCentsToCurrencyString(cartViewModel.finalTotal))
                    .font(totalFont)
                    .foregroundColor(totalForegroundColor)
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
                .font(cartItemFont)
                .foregroundColor(cartItemForegroundColor)
            Spacer()
            Text(CurrencyFormatter.shared.convertCentsToCurrencyString(item.amountInCents))
                .font(cartItemFont)
                .foregroundColor(cartItemForegroundColor)
                .padding(.trailing)
        }
        .frame(height: cartItemHeight)
        .cornerRadius(10.0)
        .overlay(
            RoundedRectangle(cornerRadius: 10.0)
                .fill(cartItemBackgroundColor)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    var checkoutButton: some View {
        Button {
            self.continueToCheckout = true
        } label: {
            Text(checkoutButtonTitle)
                .font(checkoutButtonFont)
                .foregroundColor(checkoutButtonForegroundColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 42.0)
        .frame(maxWidth: .infinity)
        .background(checkoutButtonBackgroundColor)
        .cornerRadius(10.0)
        .padding(.horizontal)
    }
}

#Preview {
    FrameCartView(customer: FrameObjects.Customer(id: "1", created: nil, shippingAddress: nil,
                                                  updated: nil, livemode: false, name: "", phone: nil, email: nil,
                                                  description: nil, object: nil, metadata: nil, billingAddress: nil),
                  cartItems: [],
                  shippingAmountInCents: 1000)
}
