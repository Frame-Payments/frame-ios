//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/19/25.
//

import SwiftUI
import EvervaultInputs
import Frame

struct SelectPaymentMethodView: View {
    @Environment(\.frameTheme) private var theme
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel

    @State private var canCustomerContinue: Bool = false
    @State private var showAddPaymentMethod: Bool = false
    @State private var onlyAddressVerification: Bool = false
    @State private var paymentVerified: Bool = false
    
    @Binding var continueToNextStep: Bool
    @Binding var returnToPreviousStep: Bool
    
    let examplePaymentMethod = FrameObjects.PaymentMethod(id: "method_123", type: .card, object: "payment_method", created: 0, updated: 0, livemode: true, card: FrameObjects.PaymentCard(brand: "mastercard", expirationMonth: "08", expirationYear: "29", currency: "usd", lastFourDigits: "1111"), status: .active)
    
    var body: some View {
        NavigationStack {
            selectPaymentView
                .navigationDestination(isPresented: $showAddPaymentMethod) {
                    AddPaymentMethodView(onboardingContainerViewModel: onboardingContainerViewModel,
                                         onlyAddressVerification: onlyAddressVerification)
                        .navigationBarBackButtonHidden()
                }
        }
        .onAppear {
            AccountEventEmitter.emit(name: .paymentMethodStepStarted, screen: .paymentMethod)
            Task {
                await onboardingContainerViewModel.loadExistingPaymentMethods()
            }
        }
        .onChange(of: onboardingContainerViewModel.selectedPaymentMethod) { oldValue, newValue in
            self.canCustomerContinue = newValue != nil
        }
        .onChange(of: paymentVerified, { oldValue, newValue in
            guard paymentVerified else { return }
            self.continueToNextStep = true
        })
    }
    
    var selectPaymentView: some View {
        VStack(alignment: .leading) {
            listPaymentMethodsView
            Spacer()
            ContinueButton(enabled: $canCustomerContinue,
                           isLoading: .constant(onboardingContainerViewModel.isPerformingAction)) {
                Task {
                    // Check if address is present on the selected card.
                    if onboardingContainerViewModel.requiredCapabilities.contains(.addressVerification), onboardingContainerViewModel.selectedPayoutMethod?.billing?.addressLine1 == nil {
                        self.onlyAddressVerification = true
                        self.showAddPaymentMethod = true
                    } else {
                        self.paymentVerified = true
                    }

                }
            }
            .padding(.bottom)
        }
    }
    
    var listPaymentMethodsView: some View {
        Group {
            PageHeaderView(headerTitle: "Select A Payment Method") {
                self.returnToPreviousStep = true
            }
            Text("Choose a saved payment method or add a new one to continue")
                .fontWeight(.light)
                .font(theme.fonts.bodySmall)
                .padding(.horizontal)
            ScrollView {
                if !onboardingContainerViewModel.paymentMethods.isEmpty {
                    headerScrollTitles(name: "Saved Payment Methods")
                    ForEach(onboardingContainerViewModel.paymentMethods) { paymentMethod in
                        FramePaymentMethodRow(
                            paymentMethod: paymentMethod,
                            isSelected: onboardingContainerViewModel.selectedPaymentMethod == paymentMethod
                        ) {
                            onboardingContainerViewModel.selectedPaymentMethod = paymentMethod
                            AccountEventEmitter.emit(name: .savedPaymentMethodSelected, screen: .paymentMethod)
                        }
                        .padding(.horizontal)
                    }
                }
                headerScrollTitles(name: "Add a payment method")
                MethodOptionRow(iconName: "add-card-icon", title: "Add a card") {
                    AccountEventEmitter.emit(name: .addPaymentMethodStarted, screen: .paymentMethod)
                    self.showAddPaymentMethod = true
                }
                .padding(.horizontal)
            }
        }
    }
    
    func headerScrollTitles(name: String) -> some View {
        HStack {
            Text(name)
                .font(theme.fonts.label)
                .padding(.horizontal)
                .padding(.vertical, 8.0)
            Spacer()
        }
    }

}

#Preview {
    SelectPaymentMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []),
                            continueToNextStep: .constant(false),
                            returnToPreviousStep: .constant(false))
}

#Preview("Dark") {
    SelectPaymentMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []),
                            continueToNextStep: .constant(false),
                            returnToPreviousStep: .constant(false))
        .preferredColorScheme(.dark)
}
