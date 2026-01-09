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
                PaymentCardDetailView(cardData: $onboardingContainerViewModel.cardData)
                BillingAddressDetailView(addressLineOne: $onboardingContainerViewModel.createdBillingAddress.addressLine1.orEmpty,
                                         addressLineTwo: $onboardingContainerViewModel.createdBillingAddress.addressLine2.orEmpty,
                                         city: $onboardingContainerViewModel.createdBillingAddress.city.orEmpty,
                                         state: $onboardingContainerViewModel.createdBillingAddress.state.orEmpty,
                                         zipCode: $onboardingContainerViewModel.createdBillingAddress.postalCode,
                                         country: $onboardingContainerViewModel.createdBillingAddress.country.orEmpty)
                ContinueButton(enabled: $canCustomerContinue) {
                    Task {
                        await onboardingContainerViewModel.addNewPaymentMethod()
                        self.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddPaymentMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(customerId: "", components: SessionComponents()))
}
