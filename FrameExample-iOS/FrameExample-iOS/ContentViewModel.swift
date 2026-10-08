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
    @Published var refunds: [FrameObjects.Refund] = []
    /// The onboarding-session token (`onb_sess_…`) minted for the demo flow, if any.
    @Published var onboardingClientSecret: String?
    
    // Replace with your Apple Pay merchant ID registered in your entitlements
    let applePayMerchantId: String = "merchant.com.yourapp"
    // Replace with an accountID from your dashboard.
    var accountId: String = "ENTER_AN_ACCOUNT_ID"
    
    init() {
        // The SDK is publishable-key first: pass your publishable key (pk_) here. Secret keys
        // grant full merchant privileges and must not ship in an app binary — serve sk_ from your
        // backend. This example sets a secret key only to exercise the legacy server-side demo
        // calls below; production apps should omit it.
        FrameNetworking.shared.initialize(publishableKey: "ENTER_PUBLISHABLE_KEY_HERE",
                                          secretKey: "ENTER_SECRET_KEY_HERE",
                                          accountId: accountId == "ENTER_AN_ACCOUNT_ID" ? nil : accountId,
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
    /// exercise the onboarding flow end-to-end. Returns the token, or `nil` when minting failed.
    ///
    /// - Important: This mint exists only because the example app has no backend. Production apps
    ///   mint `POST /v1/onboarding_sessions` on their server with `sk_` and pass the client secret in.
    ///   Creating a session authenticates with your secret key, which must never ship in an app binary.
    /// - Parameter accountId: The existing Frame account to onboard.
    /// - Returns: The `onb_sess_…` token, or `nil` if the request failed.
    func mintOnboardingClientSecret(accountId: String) async -> String? {
        let request = OnboardingSessionRequest.CreateOnboardingSessionRequest(
            accountId: accountId,
            steps: [.idVerification, .geoCompliance, .paymentMethod]
        )
        do {
            let (session, error) = try await OnboardingSessionsAPI.createOnboardingSession(request: request)
            if let clientSecret = session?.clientSecret, !clientSecret.isEmpty {
                await MainActor.run { self.onboardingClientSecret = clientSecret }
                return clientSecret
            } else {
                print("⚠️ Frame example: failed to mint onboarding session token. Error: \(String(describing: error))")
                return nil
            }
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
    
    /// Mints a checkout client secret (`chk_sess_…`) so the example can load a name, email, and
    /// saved cards. Returns the token, or `nil` when minting failed.
    ///
    /// - Important: This mint exists only because the example app has no backend. Production apps
    ///   mint `POST /v1/checkout_sessions` on their server with `sk_` and pass the client secret in.
    /// - Parameter accountId: The account checkout will charge.
    /// - Returns: The checkout token and its expiry, or `nil` if the request failed.
    func mintCheckoutClientSecret(
        accountId: String,
        amountCents: Int? = nil,
        currency: String = "usd"
    ) async -> FrameCheckoutClientSecret? {
        guard !accountId.isEmpty else { return nil }
        do {
            let amount = amountCents.map { FrameObjects.TransferV2Money(value: $0, currency: currency) }
            let (session, error) = try await CheckoutSessionsAPI.createCheckoutSession(accountId: accountId, amount: amount)
            if let clientSecret = session?.clientSecret, !clientSecret.isEmpty, let expiresAt = session?.expiresAt {
                return FrameCheckoutClientSecret(
                    clientSecret: clientSecret,
                    expiresAt: Date(timeIntervalSince1970: TimeInterval(expiresAt)),
                    amountCents: session?.amount?.value ?? amountCents,
                    amountCurrency: session?.amount?.currency ?? (amountCents == nil ? nil : currency)
                )
            }
            print("⚠️ Frame example: failed to mint checkout client secret. Error: \(String(describing: error))")
            return nil
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    func createEmptyIndividualAccount(capabilities: [FrameObjects.Capabilities]) async -> String? {
        // Note: callers (e.g. sendOTPVerification) already hold the action guard. Don't double-guard.
        do {
            let individualAccount = AccountRequest.CreateIndividualAccount(name: FrameObjects.AccountNameInfo(firstName: "", lastName: ""),
                                                                           email: "newaccount@gmail.com",
                                                                           phone: FrameObjects.AccountPhoneNumber(number: "", countryCode: ""),
                                                                           address: nil,
                                                                           birthdate: nil,
                                                                           ssn: nil)
            let profile = AccountRequest.CreateAccountProfile(business: nil, individual: individualAccount)
            let request = AccountRequest.CreateAccountRequest(accountType: .individual, profile: profile, capabilities: capabilities)
            let (account, _) = try await AccountsAPI.createAccount(request: request)
            guard let account else { return nil }
            return account.id
        } catch let error {
            print(error)
            return nil
        }
    }
}
