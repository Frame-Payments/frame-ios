//
//  ContentView.swift
//  FrameExample-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import SwiftUI
import Frame_iOS

struct ContentView: View {
    @State var paymentMethods: [FrameObjects.PaymentMethod]?
    @State var subscriptions: [FrameObjects.Subscription]?
    @State var customers: [FrameObjects.Customer]?
    @State var chargeIntents: [FrameObjects.ChargeIntent]?
    @State var refunds: [FrameObjects.Refund]?
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .task {
            FrameNetworking.shared.initializeWithAPIKey("") // Step 1 to using the framework.
            await self.getPaymentMethodsAsync()
            self.getPaymentMethods()
            
            await self.getSubscriptionsAsync()
            self.getSubscriptions()
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
