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
    @Published var subscriptionPhases: [FrameObjects.SubscriptionPhase] = []
    @Published var customerIdentity: FrameObjects.CustomerIdentity?
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
            await self.getSubscriptionPhases(subscriptionId: "")
//            await self.getCustomerIdentity(customerIdentity: "")
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
    
    func getSubscriptionPhases(subscriptionId: String) {
        SubscriptionPhasesAPI.listAllSubscriptionPhases(subscriptionId: subscriptionId) { subscriptionPhases, error in
            if let subscriptionPhases = subscriptionPhases?.phases {
                DispatchQueue.main.async {
                    self.subscriptionPhases = subscriptionPhases
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
    
    func getCustomerIdentity(customerIdentity: String) {
        CustomerIdentityAPI.getCustomerIdentityWith(customerIdentityId: customerIdentity) { (customerIdentity, error) in
            if let customerIdentity = customerIdentity {
                DispatchQueue.main.async {
                    self.customerIdentity = customerIdentity
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
            let (paymentMethods, _) = try await PaymentMethodsAPI.getPaymentMethods()
            if let methods = paymentMethods?.data {
                DispatchQueue.main.async {
                    self.paymentMethods = methods
                }
            }
        } catch let error {
            print (error.localizedDescription)
        }
    }
    
    func getSubscriptions() async {
        do {
            let (subscriptions, _) = try await SubscriptionsAPI.getSubscriptions()
            if let subscriptions = subscriptions?.data {
                DispatchQueue.main.async {
                    self.subscriptions = subscriptions
                }
            }
        } catch let error {
            print (error.localizedDescription)
        }
    }
    
    func getSubscriptionPhases(subscriptionId: String) async {
        do {
            let (subscriptionPhases, _) = try await SubscriptionPhasesAPI.listAllSubscriptionPhases(subscriptionId: subscriptionId)
            if let subscriptionPhases = subscriptionPhases?.phases {
                DispatchQueue.main.async {
                    self.subscriptionPhases = subscriptionPhases
                }
            }
        } catch let error {
            print (error.localizedDescription)
        }
    }
    
    func getCustomerIdentity(customerIdentity: String) async {
        do {
            let (identity, _) = try await CustomerIdentityAPI.getCustomerIdentityWith(customerIdentityId: customerIdentity)
            if let identity {
                DispatchQueue.main.async {
                    self.customerIdentity = identity
                }
            }
        } catch let error {
            print (error.localizedDescription)
        }
    }
    
    func getCustomers() async {
        do {
            let (customers, _) = try await CustomersAPI.getCustomers()
            if let customers = customers?.data {
                DispatchQueue.main.async {
                    self.customers = customers
                }
            }
        } catch let error {
            print (error.localizedDescription)
        }
    }
    
    func getChargeIntents() async {
        do {
            let (intents, _) = try await ChargeIntentsAPI.getAllChargeIntents()
            if let intents = intents?.data {
                DispatchQueue.main.async {
                    self.chargeIntents = intents
                }
            }
        } catch let error {
            print (error.localizedDescription)
        }
    }
    
    func getRefunds() async {
        do {
            let (refunds, _) = try await RefundsAPI.getRefunds()
            if let refunds = refunds?.data {
                DispatchQueue.main.async {
                    self.refunds = refunds
                }
            }
        } catch let error {
            print (error.localizedDescription)
        }
    }
}
