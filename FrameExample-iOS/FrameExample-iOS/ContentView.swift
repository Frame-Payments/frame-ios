//
//  ContentView.swift
//  FrameExample-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import SwiftUI
import Frame_iOS

struct ExampleCartItem: FrameCartItem {
    var id: String
    var imageURL: String
    var title: String
    var amountInCents: Int
}

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel = ContentViewModel()
    
    @State var showCheckoutView: Bool = false
    @State var showCustomersView: Bool = false
    @State var showPaymentMethodsView: Bool = false
    
    var body: some View {
        VStack {
            Text("Frame Payments \nSDK Playground")
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            Text("Tap a button below to view your Frame data after you have entered your API key!")
                .multilineTextAlignment(.center)
                .padding()
            allCustomersButton
                .disabled(viewModel.customers.isEmpty)
                .opacity(viewModel.customers.isEmpty ? 0.3 : 1)
            allPaymentMethodsButton
                .disabled(viewModel.paymentMethods.isEmpty)
                .opacity(viewModel.paymentMethods.isEmpty ? 0.3 : 1)
            allSubscriptionsButton
            allChargeIntentsButton
            allRefundsButton
            Spacer()
            cartButton
        }
        .padding()
        .sheet(isPresented: $showCheckoutView) {
            FrameCartView(customer: nil,
                          cartItems: [ExampleCartItem(id: "1",
                                                      imageURL: "https://img.kwcdn.com/product/fancy/5048db00-f41b-47e6-9268-2c0e3d2629e2.jpg?imageView2/2/w/800/q/70/format/webp",
                                                      title: "Vintage Track Jacket",
                                                      amountInCents: 10000),
                                      ExampleCartItem(id: "2",
                                                      imageURL: "https://cdn.shopify.com/s/files/1/0573/6433/files/4f311c56-b5aa-4136-89d1-c820f8494ecc_large.jpg?v=1730108286",
                                                      title: "Zip Up Hoodie",
                                                      amountInCents: 25000)],
                          shippingAmountInCents: 4000,
                          cartViewTitle: "Messina Clothing")
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCustomersView) {
            customersScrollView
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaymentMethodsView) {
            paymentMethodScrollView
                .presentationDragIndicator(.visible)
        }
    }
    
    var customersScrollView: some View {
        ScrollView {
            VStack {
                Text("Customers")
                    .font(.largeTitle)
                    .padding()
                ForEach(viewModel.customers) { customer in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Name: \(customer.name)")
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                            Text("Email: \(customer.email ?? "")")
                            Text("Phone: \(customer.phone ?? "Not Found")")
                        }
                        Spacer()
                    }
                    Divider()
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    var paymentMethodScrollView: some View {
        ScrollView {
            VStack {
                Text("Payment Methods")
                    .font(.largeTitle)
                    .padding()
                ForEach(viewModel.paymentMethods) { method in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("**Payment Method ID:** \n\(method.id)")
                            Text("**Customer ID:** \n\(method.customer ?? "")")
                        }
                        Spacer()
                    }
                    Divider()
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    var cartButton: some View {
        Button {
            self.showCheckoutView = true
        } label: {
            Text("Checkout")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 45.0)
        .frame(maxWidth: .infinity)
        .background(.black)
        .cornerRadius(10.0)
        .padding()
    }
    
    var allCustomersButton: some View {
        Button {
            self.showCustomersView = true
        } label: {
            Text("View All Customers")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 45.0)
        .frame(maxWidth: .infinity)
        .background(.black)
        .cornerRadius(10.0)
        .padding([.horizontal, .bottom])
    }
    
    var allPaymentMethodsButton: some View {
        Button {
            self.showPaymentMethodsView = true
        } label: {
            Text("View All Payment Methods")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 45.0)
        .frame(maxWidth: .infinity)
        .background(.black)
        .cornerRadius(10.0)
        .padding([.horizontal, .bottom])
    }
    
    var allSubscriptionsButton: some View {
        Button {
//            self.showCheckoutView = true
        } label: {
            Text("View All Subscriptions")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 45.0)
        .frame(maxWidth: .infinity)
        .background(.black)
        .cornerRadius(10.0)
        .padding([.horizontal, .bottom])
    }
    
    var allChargeIntentsButton: some View {
        Button {
//            self.showCheckoutView = true
        } label: {
            Text("View All Charge Intents")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 45.0)
        .frame(maxWidth: .infinity)
        .background(.black)
        .cornerRadius(10.0)
        .padding([.horizontal, .bottom])
    }
    
    var allRefundsButton: some View {
        Button {
//            self.showCheckoutView = true
        } label: {
            Text("View All Refunds")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 45.0)
        .frame(maxWidth: .infinity)
        .background(.black)
        .cornerRadius(10.0)
        .padding([.horizontal, .bottom])
    }
}

#Preview {
    ContentView()
}
