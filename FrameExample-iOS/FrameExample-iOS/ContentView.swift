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
        let request = PaymentMethodRequest.GetPaymentMethodsRequest(perPage: 20, page: 2)
        PaymentMethodsAPI().getPaymentMethods(request: request) { paymentMethods in
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
    
    //async await
    func getPaymentMethodsAsync() async {
        let request = PaymentMethodRequest.GetPaymentMethodsRequest(perPage: 20, page: 2)
        self.paymentMethods = try? await PaymentMethodsAPI().getPaymentMethods(request: request)
    }
    
    func getSubscriptionsAsync() async {
        self.subscriptions = try? await SubscriptionsAPI().getSubscriptions()
    }
}

#Preview {
    ContentView()
}
