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
    enum ConfirmPaymentMethodSteps {
        case selectPayment
        case verifyPayment
    }
    
    @Environment(\.frameTheme) private var theme
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel

    @State private var canCustomerContinue: Bool = false
    @State private var currentPaymentStep: ConfirmPaymentMethodSteps = .selectPayment
    @State private var showAddPaymentMethod: Bool = false
    @State private var onlyAddressVerification: Bool = false
    @State private var paymentVerified: Bool = false
    @State private var returnToSelectPayment: Bool = false
    
    @Binding var continueToNextStep: Bool
    @Binding var returnToPreviousStep: Bool
    
    let examplePaymentMethod = FrameObjects.PaymentMethod(id: "method_123", type: .card, object: "payment_method", created: 0, updated: 0, livemode: true, card: FrameObjects.PaymentCard(brand: "mastercard", expirationMonth: "08", expirationYear: "29", currency: "usd", lastFourDigits: "1111"), status: .active)
    
    var body: some View {
        NavigationStack {
            switch currentPaymentStep {
            case .selectPayment:
                selectPaymentView
                    .navigationDestination(isPresented: $showAddPaymentMethod) {
                        AddPaymentMethodView(onboardingContainerViewModel: onboardingContainerViewModel,
                                             onlyAddressVerification: onlyAddressVerification)
                            .navigationBarBackButtonHidden()
                    }
            case .verifyPayment:
                SecurePMVerificationView(type: .threeDS,
                                         onboardingContainerViewModel: onboardingContainerViewModel,
                                         continueToNextStep: $paymentVerified,
                                         returnToPreviousStep: $returnToSelectPayment)
            }
        }
        .onAppear {
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
        .onChange(of: returnToSelectPayment) { oldValue, newValue in
            guard returnToSelectPayment else { return }
            
            self.currentPaymentStep = .selectPayment
            self.returnToSelectPayment = false
        }
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
                    
                    //TODO: Check if `card_verification` is active on the capabilities, start 3DS flow
//                    if onboardingContainerViewModel.requiredCapabilities.contains(.cardVerification) {
//                        await onboardingContainerViewModel.start3DSecureProcess()
//                        self.currentPaymentStep = .verifyPayment
//                    } else {
//                        self.paymentVerified = true
//                    }
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
                        paymentMethodView(paymentMethod: paymentMethod)
                    }
                }
                headerScrollTitles(name: "Add Payment Method")
                addPaymentMethodRow
            }
        }
    }
    
    func headerScrollTitles(name: String) -> some View {
        HStack {
            Text(name)
                .bold()
                .font(theme.fonts.bodySmall)
                .padding(.horizontal)
                .padding(.vertical, 8.0)
            Spacer()
        }
    }

    var addPaymentMethodRow: some View {
        HStack {
            Image("emptycard", bundle: FrameResources.module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48.0, height: 32.0)
                .padding(.horizontal)
            Text("Debit/Credit Card")
                .bold()
                .font(theme.fonts.bodySmall)
            Spacer()
            Image("right-chevron", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .stroke(theme.colors.surfaceStroke, lineWidth: 1)
        )
        .padding(.horizontal)
        .onTapGesture {
            self.showAddPaymentMethod = true
        }
    }

    func paymentMethodView(paymentMethod: FrameObjects.PaymentMethod) -> some View {
        HStack {
            Image(paymentMethod.card?.brand ?? "", bundle: FrameResources.module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48.0, height: 32.0)
                .padding(.horizontal)
            VStack(alignment: .leading) {
                Text("•••• \(paymentMethod.card?.lastFourDigits ?? "")")
                    .bold()
                    .font(theme.fonts.bodySmall)
                    .padding(.bottom, 1.0)
                Text("Exp. \(paymentMethod.card?.expirationMonth ?? "")/\(paymentMethod.card?.expirationYear ?? "")")
                    .font(theme.fonts.caption)
            }
            Spacer()
            Image(onboardingContainerViewModel.selectedPaymentMethod == paymentMethod ? "filled-selection" : "empty-selection", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .stroke(theme.colors.surfaceStroke, lineWidth: 1)
        )
        .padding(.horizontal)
        .onTapGesture {
            onboardingContainerViewModel.selectedPaymentMethod = paymentMethod
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
