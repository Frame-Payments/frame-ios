//
//  ContentViewModel.swift
//  FrameExample-iOS
//
//  Created by Frame Payments on 1/17/25.
//  Copyright © 2025 Frame Payments. All rights reserved.
//

import Foundation
import Frame

class ContentViewModel: ObservableObject, @unchecked Sendable {
    @Published var paymentMethods: [FrameObjects.PaymentMethod] = []
    @Published var subscriptions: [FrameObjects.Subscription] = []
    @Published var subscriptionPhases: [FrameObjects.SubscriptionPhase] = []
    @Published var customerIdentity: FrameObjects.CustomerIdentity?
    @Published var customers: [FrameObjects.Customer] = []
    @Published var chargeIntents: [FrameObjects.ChargeIntent] = []
    @Published var refunds: [FrameObjects.Refund] = []
    /// The onboarding-session token (`onb_sess_…`) minted for the demo flow, if any.
    @Published var onboardingClientSecret: String?
    
    // Replace with your Apple Pay merchant ID registered in your entitlements
    let applePayMerchantId: String = "merchant.com.yourapp"
    
    init() {
        // The SDK is publishable-key first: pass your publishable key (pk_) here. Secret keys
        // grant full merchant privileges and must not ship in an app binary — serve sk_ from your
        // backend. This example sets a secret key only to exercise the legacy server-side demo
        // calls below; production apps should omit it.
        FrameNetworking.shared.initialize(publishableKey: "ENTER_PUBLISHABLE_KEY_HERE",
                                          secretKey: "ENTER_SECRET_KEY_HERE",
//                                          theme: FrameTheme(
//                                              colors: .init(primaryButton: .purple, error: .orange),
//                                              fonts: .init(title: .custom("Avenir-Black", size: 28)),
//                                              radii: .init(medium: 16)
//                                          ),
                                          applePayMerchantId: applePayMerchantId,
                                          debugMode: true)

        Task {
            await self.getCustomers()
            await self.getPaymentMethods()
            await self.getSubscriptions()
            await self.getChargeIntents()
            await self.getRefunds()
//            await self.getSubscriptionPhases(subscriptionId: "")
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

    // MARK: Onboarding session (demo / testing only)

    /// Mints an onboarding-session token (`onb_sess_…`) for the given account so the example app can
    /// exercise the onboarding flow end-to-end.
    ///
    /// - Important: This is **not** the intended production path. Creating an onboarding session is a
    ///   server-only operation that authenticates with your secret key (`sk_`), which must never ship
    ///   in an app binary. Real integrations mint this token from their backend
    ///   (`POST /v1/onboarding_sessions`) and hand it to the app. The example app does it inline only
    ///   because it already configures an `sk_` to exercise the legacy server-side demo calls.
    /// - Parameter accountId: The existing Frame account to onboard.
    func mintOnboardingClientSecret(accountId: String) async {
        let request = OnboardingSessionRequest.CreateOnboardingSessionRequest(
            accountId: accountId,
            steps: [.idVerification, .geoCompliance, .paymentMethod]
        )
        do {
            let (session, error) = try await OnboardingSessionsAPI.createOnboardingSession(request: request)
            if let clientSecret = session?.clientSecret {
                DispatchQueue.main.async {
                    self.onboardingClientSecret = clientSecret
                }
            } else {
                print("⚠️ Frame example: failed to mint onboarding session token. Error: \(String(describing: error))")
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
