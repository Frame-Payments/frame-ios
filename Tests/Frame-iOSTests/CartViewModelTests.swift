//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/21/24.
//

import XCTest
@testable import Frame

final class CartViewModelTests: XCTestCase {
    struct TestCartItem: FrameCartItem {
        var id: String
        var imageURL: String
        var title: String
        var amountInCents: Int
    }
    
    func testCartSubtotal() {
        // Empty cart Items
        let viewModel = FrameCartViewModel(cartItems: [], shippingAmount: 0)
        XCTAssertEqual(viewModel.cartItems.count, 0)
        XCTAssertEqual(viewModel.subtotal, 0)

        let cartItem1 = TestCartItem(id: "1", imageURL: "", title: "Product 1", amountInCents: 1000)
        let cartItem2 = TestCartItem(id: "2", imageURL: "", title: "Product 2", amountInCents: 2000)
        let cartItem3 = TestCartItem(id: "3", imageURL: "", title: "Product 3", amountInCents: 3000)
        
        // Check subtotal at initialization
        let viewModel2 = FrameCartViewModel(cartItems: [cartItem1, cartItem2], shippingAmount: 0)
        XCTAssertEqual(viewModel2.cartItems.count, 2)
        XCTAssertEqual(viewModel2.subtotal, 3000)

        // Check cart count with appending items
        viewModel2.cartItems.append(cartItem3)
        XCTAssertEqual(viewModel2.cartItems.count, 3)
        
        // Check subtotal after appending items
        XCTAssertEqual(viewModel2.subtotal, 6000)
        
        // Valid item exist
        XCTAssertEqual(viewModel2.cartItems.contains(where: { $0.title == "Product 3"}), true)
    }
    
    func testCartFinalTotal() {
        // Empty cart Items and free shipping
        let viewModel = FrameCartViewModel(cartItems: [], shippingAmount: 0)
        XCTAssertEqual(viewModel.cartItems.count, 0)
        XCTAssertEqual(viewModel.finalTotal, 0)

        let cartItem1 = TestCartItem(id: "1", imageURL: "", title: "Product 1", amountInCents: 1000)
        let cartItem2 = TestCartItem(id: "2", imageURL: "", title: "Product 2", amountInCents: 2000)
        let cartItem3 = TestCartItem(id: "3", imageURL: "", title: "Product 3", amountInCents: 3000)
        
        // Check finalTotal at initialization
        let viewModel2 = FrameCartViewModel(cartItems: [cartItem1, cartItem2], shippingAmount: 0)
        XCTAssertEqual(viewModel2.cartItems.count, 2)
        XCTAssertEqual(viewModel2.finalTotal, 3000)
        
        viewModel2.shippingAmount = 500
        XCTAssertEqual(viewModel2.finalTotal, 3500)

        // Check cart count with appending items
        viewModel2.cartItems.append(cartItem3)
        XCTAssertEqual(viewModel2.cartItems.count, 3)
        
        // Check final total after appending items
        XCTAssertEqual(viewModel2.finalTotal, 6500)
        
        // Valid item exist
        XCTAssertEqual(viewModel2.cartItems.contains(where: { $0.title == "Product 3"}), true)
    }
}
