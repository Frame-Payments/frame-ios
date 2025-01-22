//
//  ContentViewModel.swift
//  FrameExample-iOS
//
//  Created by Frame Payments on 1/17/25.
//  Copyright © 2025 Frame Payments. All rights reserved.
//

import Foundation
import Frame_iOS

class ContentViewModel: ObservableObject, @unchecked Sendable {
    @Published var paymentMethods: [FrameObjects.PaymentMethod] = []
    @Published var subscriptions: [FrameObjects.Subscription] = []
    @Published var customers: [FrameObjects.Customer] = []
    @Published var chargeIntents: [FrameObjects.ChargeIntent] = []
    @Published var refunds: [FrameObjects.Refund] = []
    
    init() {
        // Step 1 to using the framework.
        FrameNetworking.shared.initializeWithAPIKey("sk_sandbox_WDmSrVpLbE3TUqLiF71DaATS")
        FrameNetworking.shared.debugMode = true
        
        Task {
            await self.getCustomers()
            await self.getPaymentMethods()
            await self.getRefunds()
        }
    }
    
    //completionHandler
    func getPaymentMethods() {
        PaymentMethodsAPI.getPaymentMethods { paymentMethods in
            if let paymentMethods {
                DispatchQueue.main.async {
                    self.paymentMethods = paymentMethods
                }
            }
        }
    }
    
    func getSubscriptions() {
        SubscriptionsAPI.getSubscriptions { subscriptions in
            if let subscriptions {
                DispatchQueue.main.async {
                    self.subscriptions = subscriptions
                }
            }
        }
    }
    
    func getCustomers() {
        CustomersAPI.getCustomers { customers in
            if let customers {
                DispatchQueue.main.async {
                    self.customers = customers
                }
            }
        }
    }
    
    func getChargeIntents() {
        ChargeIntentsAPI.getAllChargeIntents() { chargeIntents in
            if let chargeIntents {
                DispatchQueue.main.async {
                    self.chargeIntents = chargeIntents
                }
            }
        }
    }
    
    func getRefunds() {
        RefundsAPI.getRefunds { refunds in
            if let refunds {
                DispatchQueue.main.async {
                    self.refunds = refunds
                }
            }
        }
    }
    
    //async await
    func getPaymentMethods() async {
        do {
            if let paymentMethods = try await PaymentMethodsAPI.getPaymentMethods() {
                DispatchQueue.main.async {
                    self.paymentMethods = paymentMethods
                }
            }
        } catch let error {
            print (error.localizedDescription)
        }
    }
    
    func getSubscriptionsAsync() async {
        do {
            if let subscriptions = try await SubscriptionsAPI.getSubscriptions() {
                DispatchQueue.main.async {
                    self.subscriptions = subscriptions
                }
            }
        } catch let error {
            print (error.localizedDescription)
        }
    }
    
    func getCustomers() async {
        do {
            if let customers = try await CustomersAPI.getCustomers() {
                DispatchQueue.main.async {
                    self.customers = customers
                }
            }
        } catch let error {
            print (error.localizedDescription)
        }
    }
    
    func getChargeIntents() async {
        if let intents = try? await ChargeIntentsAPI.getAllChargeIntents() {
            DispatchQueue.main.async {
                self.chargeIntents = intents
            }
        }
    }
    
    func getRefunds() async {
        if let refunds = try? await RefundsAPI.getRefunds() {
            DispatchQueue.main.async {
                self.refunds = refunds
            }
        }
    }
}
