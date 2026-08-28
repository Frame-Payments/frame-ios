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

    @State var showCheckoutView: Bool = false
    @State var showAddPaymentMethodView: Bool = false
    @State var showSelectPayoutMethodView: Bool = false
    
    @State var showCustomersView: Bool = false
    @State var showPaymentMethodsView: Bool = false
    @State var showSubscriptionsView: Bool = false
    @State var showChargeIntentsView: Bool = false
    @State var showRefundsView: Bool = false
    @State var showSubscriptionPhases: Bool = false
    @State var showOnboardingSheet: Bool = false
    @State var applePayResult: String? = nil

    let requiredCapabilities: [FrameObjects.Capabilities] = [.kycPrefill, .geoCompliance, .ageVerification]
    
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
                Divider()
                allCustomersButton
                    .disabled(viewModel.customers.isEmpty)
                    .opacity(viewModel.customers.isEmpty ? 0.3 : 1)
                allPaymentMethodsButton
                    .disabled(viewModel.paymentMethods.isEmpty)
                    .opacity(viewModel.paymentMethods.isEmpty ? 0.3 : 1)
                allSubscriptionsButton
                    .disabled(viewModel.subscriptions.isEmpty)
                    .opacity(viewModel.subscriptions.isEmpty ? 0.3 : 1)
                allChargeIntentsButton
                    .disabled(viewModel.chargeIntents.isEmpty)
                    .opacity(viewModel.chargeIntents.isEmpty ? 0.3 : 1)
                allRefundsButton
                    .disabled(viewModel.refunds.isEmpty)
                    .opacity(viewModel.refunds.isEmpty ? 0.3 : 1)
                allSubscriptionPhasesButton
                    .disabled(viewModel.subscriptionPhases.isEmpty)
                    .opacity(viewModel.subscriptionPhases.isEmpty ? 0.3 : 1)
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
            // clientSecret is the onb_sess_… token minted above; the SDK binds every onboarding
            // request to it, scoping the flow to a single account.
            OnboardingContainerView(clientSecret: viewModel.onboardingClientSecret,
                                    accountId: viewModel.accountId,
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
        })
        .sheet(isPresented: $showCheckoutView) {
            FrameCartView(accountId: viewModel.accountId,
                          cartItems: [ExampleCartItem(id: "1",
                                                      imageURL: "https://img.kwcdn.com/product/fancy/5048db00-f41b-47e6-9268-2c0e3d2629e2.jpg?imageView2/2/w/800/q/70/format/webp",
                                                      title: "Vintage Track Jacket",
                                                      amountInCents: 10000),
                                      ExampleCartItem(id: "2",
                                                      imageURL: "https://hourscollection.com/cdn/shop/files/ZipHoodie-Grey-productphoto_2.png?v=1762198126&width=1080",
                                                      title: "Zip Up Hoodie",
                                                      amountInCents: 25000)],
                          shippingAmountInCents: 4000,
                          cartViewTitle: "Messina Clothing",
                          onResult: { result in
                switch result {
                    case .completed(let id):
                        FrameToastCenter.shared.show("Completed: \(id)")
                    case .cancelled:
                        FrameToastCenter.shared.show("Cancelled flow")
                    case .failed(let error):
                    FrameToastCenter.shared.show("Failed: \(error.localizedDescription)")
                }
            })
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddPaymentMethodView, content: {
            FrameAddPaymentMethodView(accountId: viewModel.accountId)
                .presentationDragIndicator(.visible)
        })
        .sheet(isPresented: $showSelectPayoutMethodView, content: {
            FrameSelectPayoutMethodView(accountId: viewModel.accountId, onResult: { result in
                // This screen leaves dismissal to its host, so close the sheet here.
                self.showSelectPayoutMethodView = false
                switch result {
                    case .completed(let id):
                        FrameToastCenter.shared.show("Primary payout method: \(id)")
                    case .cancelled:
                        FrameToastCenter.shared.show("Cancelled flow")
                    case .failed(let error):
                        FrameToastCenter.shared.show("Failed: \(error.localizedDescription)")
                }
            })
                .presentationDragIndicator(.visible)
        })
        .sheet(isPresented: $showCustomersView) {
            customersScrollView
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaymentMethodsView) {
            paymentMethodScrollView
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSubscriptionsView, content: {
            subscriptionsScrollView
                .presentationDragIndicator(.visible)
        })
        .sheet(isPresented: $showChargeIntentsView, content: {
            chargeIntentsScrollView
                .presentationDragIndicator(.visible)
        })
        .sheet(isPresented: $showRefundsView) {
            refundsScrollView
                .presentationDragIndicator(.visible)
        }
    }
    
    var customersScrollView: some View {
        ScrollView {
            VStack {
                Text("Customers")
                    .font(.title)
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
                    .font(.title)
                    .padding()
                ForEach(viewModel.paymentMethods) { method in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("**Payment Method ID:** \n\(method.id)")
                            Text("**Customer ID:** \n\(method.customerId ?? "")")
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
    
    var subscriptionsScrollView: some View {
        ScrollView {
            VStack {
                Text("Subscriptions")
                    .font(.title)
                    .padding()
                ForEach(viewModel.subscriptions) { subscription in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("**Subscription ID:** \n\(subscription.id)")
                            Text("**Customer ID:** \n\(subscription.customer ?? "")")
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
    
    var subscriptionPhasesScrollView: some View {
        ScrollView {
            VStack {
                Text("Subscription Phases")
                    .font(.title)
                    .padding()
                ForEach(viewModel.subscriptionPhases) { subscriptionPhase in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("**Subscription Phase ID:** \n\(subscriptionPhase.id)")
                            Text("**Pricing Type:** \n\(subscriptionPhase.pricingType?.rawValue ?? "")")
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
    
    var chargeIntentsScrollView: some View {
        ScrollView {
            VStack {
                Text("Charge Intents")
                    .font(.title)
                    .padding()
                ForEach(viewModel.chargeIntents) { intent in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("**Charge Intent ID:** \n\(intent.id)")
                            Text("**Customer ID:** \n\(intent.customer?.id ?? "")")
                            Text("**Payment Method Id:** \n\(intent.paymentMethod?.id ?? "")")
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
    
    var refundsScrollView: some View {
        ScrollView {
            VStack {
                Text("Refunds")
                    .font(.title)
                    .padding()
                ForEach(viewModel.refunds) { refund in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("**Refund ID:** \n\(refund.id)")
                            Text("**Charge Intent ID:** \n\(refund.chargeIntent ?? "")")
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
    
    var onboardingButton: some View {
        Button {
            // Demo/testing only: mint an onboarding-session token from the configured sk_ before
            // presenting the flow, then launch. Production apps mint this token on their backend
            // (POST /v1/onboarding_sessions) and pass it in as the clientSecret — see ContentViewModel.
            Task {
                if UUID(uuidString: viewModel.accountId) == nil  {
                    viewModel.accountId = await viewModel.createEmptyIndividualAccount(capabilities: requiredCapabilities) ?? ""
                    await viewModel.mintOnboardingClientSecret(accountId: viewModel.accountId)
                    self.showOnboardingSheet = true
                } else {
                    await viewModel.mintOnboardingClientSecret(accountId: viewModel.accountId)
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
    
    var cartButton: some View {
        Button {
            self.showCheckoutView = true
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
            self.showAddPaymentMethodView = true
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
            self.showSelectPayoutMethodView = true
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
    
    var allCustomersButton: some View {
        Button {
            self.showCustomersView = true
        } label: {
            Text("View All Customers")
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
    
    var allPaymentMethodsButton: some View {
        Button {
            self.showPaymentMethodsView = true
        } label: {
            Text("View All Payment Methods")
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
    
    var allSubscriptionsButton: some View {
        Button {
//            self.showCheckoutView = true
        } label: {
            Text("View All Subscriptions")
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
    
    var allChargeIntentsButton: some View {
        Button {
            self.showChargeIntentsView = true
        } label: {
            Text("View All Charge Intents")
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
    
    var allRefundsButton: some View {
        Button {
            self.showRefundsView = true
        } label: {
            Text("View All Refunds")
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
    
    var allSubscriptionPhasesButton: some View {
        Button {
            self.showSubscriptionPhases = true
        } label: {
            Text("View All Subscription Phases")
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
