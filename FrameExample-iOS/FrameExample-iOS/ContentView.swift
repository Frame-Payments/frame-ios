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
    // Test variables. Will use later in tandom with UI to show functionality.
    @State var paymentMethods: [FrameObjects.PaymentMethod]?
    @State var subscriptions: [FrameObjects.Subscription]?
    @State var customers: [FrameObjects.Customer]?
    @State var chargeIntents: [FrameObjects.ChargeIntent]?
    @State var refunds: [FrameObjects.Refund]?
    
    @State var showCheckoutView: Bool = false
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Frame Payments Playground")
            
            Button {
                self.showCheckoutView = true
            } label: {
                Text("Cart View (Sheet)")
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
        .padding()
        .task {
            FrameNetworking.shared.initializeWithAPIKey("") // Step 1 to using the framework.
            await self.getPaymentMethodsAsync()
            self.getPaymentMethods()
            
            await self.getSubscriptionsAsync()
            self.getSubscriptions()
        }
        .sheet(isPresented: $showCheckoutView) {
            FrameCartView(cartItems: [ExampleCartItem(id: "1",
                                                      imageURL: "https://messinahembry.com/cdn/shop/files/38c90b7b-e8dd-4d6d-ad17-d97b72c7c35f.jpg?v=1727534281",
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
    }
    
    //completionHandler
    func getPaymentMethods() {
        PaymentMethodsAPI().getPaymentMethods() { paymentMethods in
            if let paymentMethods {
                self.paymentMethods = paymentMethods
            }
        }
    }
    
    func getSubscriptions() {
        SubscriptionsAPI().getSubscriptions { subscriptions in
            if let subscriptions {
                self.subscriptions = subscriptions
            }
        }
    }
    
    func getCustomers() {
        CustomersAPI().getCustomers { customers in
            if let customers {
                self.customers = customers
            }
        }
    }
    
    func getChargeIntents() {
        ChargeIntentsAPI().getAllChargeIntents() { chargeIntents in
            if let chargeIntents {
                self.chargeIntents = chargeIntents
            }
        }
    }
    
    func getRefunds() {
        RefundsAPI().getRefunds { refunds in
            if let refunds {
                self.refunds = refunds
            }
        }
    }
    
    //async await
    func getPaymentMethodsAsync() async {
        self.paymentMethods = try? await PaymentMethodsAPI().getPaymentMethods()
    }
    
    func getSubscriptionsAsync() async {
        self.subscriptions = try? await SubscriptionsAPI().getSubscriptions()
    }
    
    func getCustomers() async {
        self.customers = try? await CustomersAPI().getCustomers()
    }
    
    func getChargeIntents() async {
        self.chargeIntents = try? await ChargeIntentsAPI().getAllChargeIntents()
    }
    
    func getRefunds() async {
        self.refunds = try? await RefundsAPI().getRefunds()
    }
}

#Preview {
    ContentView()
}
