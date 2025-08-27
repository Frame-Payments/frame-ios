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
        // Note: To use this SDK, you must add your sandbox secret key here.
        FrameNetworking.shared.initializeWithAPIKey("INSERT_SANDBOX_KEY_HERE", debugMode: true)
        
        Task {
            await self.getCustomers()
            await self.getPaymentMethods()
            await self.getSubscriptions()
            await self.getChargeIntents()
            await self.getRefunds()
        }
    }
    
    //completionHandler
    func getPaymentMethods() {
        PaymentMethodsAPI.getPaymentMethods { (paymentMethods, error) in
            if let paymentMethods = paymentMethods?.data {
                DispatchQueue.main.async {
                    self.paymentMethods = paymentMethods
                }
            }
        }
    }
    
    func getSubscriptions() {
        SubscriptionsAPI.getSubscriptions { subscriptions, error in
            if let subscriptions = subscriptions?.data {
                DispatchQueue.main.async {
                    self.subscriptions = subscriptions
                }
            }
        }
    }
    
    func getCustomers() {
        CustomersAPI.getCustomers { (customers, error) in
            if let customers = customers?.data {
                DispatchQueue.main.async {
                    self.customers = customers
                }
            }
        }
    }
    
    func getChargeIntents() {
        ChargeIntentsAPI.getAllChargeIntents() { (chargeIntents, error) in
            if let chargeIntents = chargeIntents?.data {
                DispatchQueue.main.async {
                    self.chargeIntents = chargeIntents
                }
            }
        }
    }
    
    func getRefunds() {
        RefundsAPI.getRefunds { (refunds, error) in
            if let refunds = refunds?.data {
                DispatchQueue.main.async {
                    self.refunds = refunds
                }
            }
        }
    }
    
    //async await
    func getPaymentMethods() async {
        do {
            if let paymentMethods = try await PaymentMethodsAPI.getPaymentMethods().0?.data {
                DispatchQueue.main.async {
                    self.paymentMethods = paymentMethods
                }
            }
        } catch let error {
            print (error.localizedDescription)
        }
    }
    
    func getSubscriptions() async {
        do {
            if let subscriptions = try await SubscriptionsAPI.getSubscriptions().0?.data {
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
            if let customers = try await CustomersAPI.getCustomers().0?.data {
                DispatchQueue.main.async {
                    self.customers = customers
                }
            }
        } catch let error {
            print (error.localizedDescription)
        }
    }
    
    func getChargeIntents() async {
        if let intents = try? await ChargeIntentsAPI.getAllChargeIntents().0?.data {
            DispatchQueue.main.async {
                self.chargeIntents = intents
            }
        }
    }
    
    func getRefunds() async {
        if let refunds = try? await RefundsAPI.getRefunds().0?.data {
            DispatchQueue.main.async {
                self.refunds = refunds
            }
        }
    }
}
