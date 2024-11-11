//
//  FrameCartViewModel.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/27/24.
//

import Foundation

class FrameCartViewModel: ObservableObject {
    @Published var cartItems: [any FrameCartItem]
    var shippingAmount: Int
    
    init(cartItems: [any FrameCartItem], shippingAmount: Int) {
        self.cartItems = cartItems
        self.shippingAmount = shippingAmount
    }
    
    var subtotal: Int {
        cartItems.reduce(0) { $0 + $1.amountInCents }
    }
    
    var finalTotal: Int {
        subtotal + shippingAmount
    }
}
