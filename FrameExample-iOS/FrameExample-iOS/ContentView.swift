//
//  ContentView.swift
//  FrameExample-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import SwiftUI
import Frame
import FrameOnboarding

struct ExampleCartItem: FrameCartItem {
    var id: String
    var imageURL: String
    var title: String
    var amountInCents: Int
}

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel = ContentViewModel()
    @Environment(\.frameTheme) var theme

    @State private var presentedCheckout: ExampleCheckoutSession?
    @State var showAddPaymentMethodView: Bool = false
    @State var showSelectPayoutMethodView: Bool = false
    @State var showOnboardingSheet: Bool = false
    @State private var businessOnboarding: BusinessOnboardingLaunch?
    @State var applePayResult: String? = nil

    let requiredCapabilities: [FrameObjects.Capabilities] = [.kycPrefill, .geoCompliance, .ageVerification]
    let businessCapabilities: [FrameObjects.Capabilities] = [.phoneVerification, .geoCompliance]
    private let exampleCartItems: [ExampleCartItem] = [
        ExampleCartItem(id: "1",
                        imageURL: "https://img.kwcdn.com/product/fancy/5048db00-f41b-47e6-9268-2c0e3d2629e2.jpg?imageView2/2/w/800/q/70/format/webp",
                        title: "Vintage Track Jacket",
                        amountInCents: 10000),
        ExampleCartItem(id: "2",
                        imageURL: "https://hourscollection.com/cdn/shop/files/ZipHoodie-Grey-productphoto_2.png?v=1762198126&width=1080",
                        title: "Zip Up Hoodie",
                        amountInCents: 25000)
    ]
    private let exampleShippingCents = 4000
    private var exampleCartTotal: Int {
        exampleCartItems.reduce(exampleShippingCents) { $0 + $1.amountInCents }
    }
    
    var body: some View {
        VStack {
            Text("FrameOS Playground")
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            Text("Tap a button below to view your Frame data after you have entered your API key!")
                .multilineTextAlignment(.center)
                .padding()
            ScrollView {
                cartButton
                addPaymentMethodButton
                selectPayoutMethodButton
                onboardingButton
                businessOnboardingButton
                
                // Apple Pay button — only visible on devices that support Apple Pay
                FrameApplePayButton(
                    mode: .charge(amount: 35000, currency: "usd"),
                    owner: .account(viewModel.accountId)
                ) { result in
                    switch result {
                    case .success(.charge(let chargeId)):
                        applePayResult = "Payment succeeded! Charge or Transfer Id: \(chargeId)"
                    case .success(.paymentMethod):
                        break
                    case .failure(let error):
                        applePayResult = "Payment failed: \(error.localizedDescription)"
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .frameToastOverlay()
        .alert("Apple Pay Result", isPresented: Binding(
            get: { applePayResult != nil },
            set: { if !$0 { applePayResult = nil } }
        )) {
            Button("OK") { applePayResult = nil }
        } message: {
            Text(applePayResult ?? "")
        }
        .sheet(isPresented: $showOnboardingSheet, content: {
            // Example app has no backend, so this token was minted with sk_ above. Production apps
            // mint POST /v1/onboarding_sessions on their server and pass the client secret in.
            if let clientSecret = viewModel.onboardingClientSecret {
            OnboardingContainerView(clientSecret: clientSecret,
                                    accountId: viewModel.accountId == "ENTER_AN_ACCOUNT_ID" ? nil : viewModel.accountId,
                                    requiredCapabilities: requiredCapabilities) { result in
                switch result {
                case .completed(let id):
                    viewModel.accountId = id
                // The flow ran to the end but the applicant isn't verified. Keep the account id —
                // it's still needed to scope follow-up calls — but don't treat this as onboarded.
                case .finishedUnverified(let id, let outcome):
                    viewModel.accountId = id
                    print("Onboarding finished unverified: \(outcome)")
                case .cancelled:
                    return
                case .failed(let error):
                    print(error.localizedDescription)
                }
            }
            }
        })
        .sheet(item: $businessOnboarding) { launch in
            OnboardingContainerView(clientSecret: launch.clientSecret,
                                    accountId: launch.accountId,
                                    accountType: .business,
                                    requiredCapabilities: businessCapabilities) { result in
                switch result {
                case .completed(let id):
                    FrameToastCenter.shared.show("Business onboarding completed: \(id)")
                case .finishedUnverified(let id, let outcome):
                    FrameToastCenter.shared.show("Business onboarding finished unverified: \(id) \(outcome)")
                case .cancelled:
                    return
                case .failed(let error):
                    FrameToastCenter.shared.show(error.localizedDescription)
                }
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $presentedCheckout) { checkout in
            FrameCartView(accountId: checkout.accountId,
                          cartItems: exampleCartItems,
                          shippingAmountInCents: exampleShippingCents,
                          cartViewTitle: "Messina Clothing",
                          checkoutClientSecret: checkout.clientSecret,
                          onResult: { result in
                switch result {
                    case .completed(let id):
                        FrameToastCenter.shared.show("Completed: \(id)")
                    case .cancelled:
                        FrameToastCenter.shared.show("Cancelled flow")
                    case .failed(let error):
                        FrameToastCenter.shared.show("Failed: \(error.localizedDescription)")
                    // Checkout never ends unverified; the cart only forwards it, so surface it.
                    case .finishedUnverified(_, let outcome):
                        FrameToastCenter.shared.show("Finished unverified: \(outcome)")
                }
            })
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddPaymentMethodView, content: {
            if let clientSecret = viewModel.onboardingClientSecret {
                FrameAddPaymentMethodView(clientSecret: clientSecret, accountId: viewModel.accountId)
                    .presentationDragIndicator(.visible)
            }
        })
        .sheet(isPresented: $showSelectPayoutMethodView, content: {
            if let clientSecret = viewModel.onboardingClientSecret {
            FrameSelectPayoutMethodView(clientSecret: clientSecret, accountId: viewModel.accountId, onResult: { result in
                // This screen leaves dismissal to its host, so close the sheet here.
                self.showSelectPayoutMethodView = false
                switch result {
                    case .completed(let id):
                        FrameToastCenter.shared.show("Primary payout method: \(id)")
                    case .cancelled:
                        FrameToastCenter.shared.show("Cancelled flow")
                    case .failed(let error):
                        FrameToastCenter.shared.show("Failed: \(error.localizedDescription)")
                    // Picking a payout method never ends unverified, but don't go silent on it.
                    case .finishedUnverified(_, let outcome):
                        FrameToastCenter.shared.show("Finished unverified: \(outcome)")
                }
            })
                .presentationDragIndicator(.visible)
            }
        })
    }
    
    var onboardingButton: some View {
        Button {
            // Example app has no backend. Production apps mint POST /v1/onboarding_sessions
            // on their server with sk_ and pass the client secret in.
            Task {
                let accountId = UUID(uuidString: viewModel.accountId) == nil
                    ? await viewModel.createEmptyIndividualAccount(capabilities: requiredCapabilities) ?? ""
                    : viewModel.accountId
                viewModel.accountId = accountId
                if await viewModel.mintOnboardingClientSecret(accountId: accountId) != nil {
                    self.showOnboardingSheet = true
                }
            }
        } label: {
            Text("Show Onboarding Flow")
                .font(.headline)
                .foregroundColor(theme.colors.primaryButtonText)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 45.0)
        .frame(maxWidth: .infinity)
        .background(theme.colors.primaryButton)
        .cornerRadius(10.0)
        .padding()
    }

    var businessOnboardingButton: some View {
        Button {
            // Example app has no backend. Production apps create the business account and mint
            // POST /v1/onboarding_sessions on their server with sk_, then pass the client secret in.
            Task {
                let created = await viewModel.createEmptyBusinessAccount(capabilities: businessCapabilities)
                guard let accountId = created.accountId else {
                    FrameToastCenter.shared.show(created.errorMessage ?? "Could not create a business account.")
                    return
                }
                guard let clientSecret = await viewModel.mintOnboardingClientSecret(accountId: accountId, publish: false) else {
                    FrameToastCenter.shared.show("Could not mint an onboarding client secret.")
                    return
                }
                businessOnboarding = BusinessOnboardingLaunch(accountId: accountId, clientSecret: clientSecret)
            }
        } label: {
            Text("Show Business Onboarding")
                .font(.headline)
                .foregroundColor(theme.colors.primaryButtonText)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 45.0)
        .frame(maxWidth: .infinity)
        .background(theme.colors.primaryButton)
        .cornerRadius(10.0)
        .padding([.horizontal, .bottom])
    }
    
    var cartButton: some View {
        Button {
            // Example app has no backend. Production apps mint POST /v1/checkout_sessions
            // on their server with sk_ and pass the client secret in. Checkout refreshes an
            // expired token with the secret key configured on this example.
            Task {
                let accountId = viewModel.accountId.isEmpty
                    ? await viewModel.createEmptyIndividualAccount(capabilities: requiredCapabilities) ?? ""
                    : viewModel.accountId
                viewModel.accountId = accountId
                // A session without a locked amount cannot create a transfer.
                if let secret = await viewModel.mintCheckoutClientSecret(accountId: accountId, amountCents: exampleCartTotal) {
                    self.presentedCheckout = ExampleCheckoutSession(accountId: accountId, clientSecret: secret)
                }
            }
        } label: {
            Text("Show Cart/Checkout")
                .font(.headline)
                .foregroundColor(theme.colors.primaryButtonText)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 45.0)
        .frame(maxWidth: .infinity)
        .background(theme.colors.primaryButton)
        .cornerRadius(10.0)
        .padding([.horizontal, .bottom])
    }
    
    var addPaymentMethodButton: some View {
        Button {
            // Example app has no backend. Production apps mint POST /v1/onboarding_sessions
            // on their server with sk_ and pass the client secret in.
            Task {
                let accountId = UUID(uuidString: viewModel.accountId) == nil
                    ? await viewModel.createEmptyIndividualAccount(capabilities: requiredCapabilities) ?? ""
                    : viewModel.accountId
                viewModel.accountId = accountId
                if await viewModel.mintOnboardingClientSecret(accountId: accountId) != nil {
                    self.showAddPaymentMethodView = true
                }
            }
        } label: {
            Text("Add New Payment Method")
                .font(.headline)
                .foregroundColor(theme.colors.primaryButtonText)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 45.0)
        .frame(maxWidth: .infinity)
        .background(theme.colors.primaryButton)
        .cornerRadius(10.0)
        .padding([.horizontal, .bottom])
    }
    
    var selectPayoutMethodButton: some View {
        Button {
            // Example app has no backend. Production apps mint POST /v1/onboarding_sessions
            // on their server with sk_ and pass the client secret in.
            Task {
                let accountId = UUID(uuidString: viewModel.accountId) == nil
                    ? await viewModel.createEmptyIndividualAccount(capabilities: requiredCapabilities) ?? ""
                    : viewModel.accountId
                viewModel.accountId = accountId
                if await viewModel.mintOnboardingClientSecret(accountId: accountId) != nil {
                    self.showSelectPayoutMethodView = true
                }
            }
        } label: {
            Text("Set Primary Payout Method")
                .font(.headline)
                .foregroundColor(theme.colors.primaryButtonText)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 45.0)
        .frame(maxWidth: .infinity)
        .background(theme.colors.primaryButton)
        .cornerRadius(10.0)
        .padding([.horizontal, .bottom])
    }
}

#Preview {
    ContentView()
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}

/// Business onboarding sheet value. The account and its `onb_sess_…` token travel together.
private struct BusinessOnboardingLaunch: Identifiable {
    let id = UUID()
    let accountId: String
    let clientSecret: String
}

/// Cart sheet value. The token travels with the presentation so checkout cannot open without it.
private struct ExampleCheckoutSession: Identifiable {
    let id = UUID()
    let accountId: String
    let clientSecret: FrameCheckoutClientSecret
}
