//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/11/25.
//

import SwiftUI
import EvervaultInputs
import Frame

struct AddPaymentMethodView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var onboardingContainerViewModel: OnboardingContainerViewModel
    
    @State private var canCustomerContinue: Bool = false
    
    init(onboardingContainerViewModel: OnboardingContainerViewModel) {
        self._onboardingContainerViewModel = StateObject(wrappedValue: onboardingContainerViewModel)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            addPaymentMethodView
            Spacer()
        }
        .onChange(of: onboardingContainerViewModel.cardData) { oldValue, newValue in
            self.canCustomerContinue = onboardingContainerViewModel.checkIfCustomerCanContinueWithPaymentMethod()
        }
        .onChange(of: onboardingContainerViewModel.createdBillingAddress) { oldValue, newValue in
            self.canCustomerContinue = onboardingContainerViewModel.checkIfCustomerCanContinueWithPaymentMethod()
        }
    }
    
    var addPaymentMethodView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                PageHeaderView(headerTitle: "Add New Payment Method") {
                    self.dismiss()
                }
                Text("Card Details")
                    .bold()
                    .font(.subheadline)
                    .padding([.horizontal])
                PaymentCardInput(cardData: $onboardingContainerViewModel.cardData)
                    .paymentCardInputStyle(EncryptedPaymentCardInput())
                billingAddressDetails
                ContinueButton(enabled: $canCustomerContinue) {
                    Task {
                        await onboardingContainerViewModel.addNewPaymentMethod()
                        self.dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var billingAddressDetails: some View {
        Text("Billing Address")
            .bold()
            .font(.subheadline)
            .padding([.horizontal, .top])
        RoundedRectangle(cornerRadius: 10.0)
            .fill(.white)
            .stroke(.gray.opacity(0.3))
            .frame(height: 200.0)
            .overlay {
                VStack(spacing: 0) {
                    TextField("",
                              text: $onboardingContainerViewModel.createdBillingAddress.addressLine1.orEmpty,
                              prompt: Text("Address Line 1"))
                    .frame(height: 49.0)
                    .padding(.horizontal)
                    Divider()
                    TextField("",
                              text: $onboardingContainerViewModel.createdBillingAddress.addressLine2.orEmpty,
                              prompt: Text("Address Line 2"))
                    .frame(height: 49.0)
                    .padding(.horizontal)
                    Divider()
                    HStack {
                        TextField("",
                                  text: $onboardingContainerViewModel.createdBillingAddress.city.orEmpty,
                                  prompt: Text("City"))
                        .frame(height: 49.0)
                        .padding(.horizontal)
                        TextField("",
                                  text: $onboardingContainerViewModel.createdBillingAddress.state.orEmpty,
                                  prompt: Text("State"))
                        .frame(height: 49.0)
                        .padding(.horizontal)
                    }
                    .frame(height: 49.0)
                    Divider()
                    TextField("",
                              text: $onboardingContainerViewModel.createdBillingAddress.postalCode,
                              prompt: Text("Zip Code"))
                    .frame(height: 49.0)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
    }
}

#Preview {
    AddPaymentMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(customerId: "", components: SessionComponents()))
}
