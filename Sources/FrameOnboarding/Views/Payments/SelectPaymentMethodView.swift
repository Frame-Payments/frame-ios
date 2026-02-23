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
    
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel
    
    @State private var canCustomerContinue: Bool = false
    @State private var currentPaymentStep: ConfirmPaymentMethodSteps = .selectPayment
    @State private var showAddPaymentMethod: Bool = false
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
                        AddPaymentMethodView(onboardingContainerViewModel: onboardingContainerViewModel)
                            .navigationBarBackButtonHidden()
                    }
            case .verifyPayment:
                SecurePMVerificationView(onboardingContainerViewModel: onboardingContainerViewModel,
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
            ContinueButton(enabled: $canCustomerContinue) {
                Task {
                    await onboardingContainerViewModel.start3DSecureProcess()
                    self.currentPaymentStep = .verifyPayment
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
                .font(.system(size: 14.0))
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
                .font(.system(size: 14.0))
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
                .font(.system(size: 14.0))
            Spacer()
            Image("right-chevron", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
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
                    .font(.system(size: 14.0))
                    .padding(.bottom, 1.0)
                Text("Exp. \(paymentMethod.card?.expirationMonth ?? "")/\(paymentMethod.card?.expirationYear ?? "")")
                    .font(.system(size: 12.0))
            }
            Spacer()
            Image(onboardingContainerViewModel.selectedPaymentMethod == paymentMethod ? "filled-selection" : "empty-selection", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .onTapGesture {
            onboardingContainerViewModel.selectedPaymentMethod = paymentMethod
        }
    }
}

#Preview {
    SelectPaymentMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(customerId: ""),
                            continueToNextStep: .constant(false),
                            returnToPreviousStep: .constant(false))
}
