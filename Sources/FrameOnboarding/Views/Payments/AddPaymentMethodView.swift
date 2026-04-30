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

    var onlyAddressVerification: Bool = false

    init(onboardingContainerViewModel: OnboardingContainerViewModel, onlyAddressVerification: Bool) {
        self._onboardingContainerViewModel = StateObject(wrappedValue: onboardingContainerViewModel)
        self.onlyAddressVerification = onlyAddressVerification
    }

    var body: some View {
        VStack(alignment: .leading) {
            addPaymentMethodView
        }
        .onChange(of: onboardingContainerViewModel.cardData) { _, _ in
            if onboardingContainerViewModel.fieldErrors[.paymentCard] != nil {
                onboardingContainerViewModel.fieldErrors[.paymentCard] = nil
            }
        }
    }

    var addPaymentMethodView: some View {
        VStack(alignment: .leading) {
            PageHeaderView(headerTitle: "Add New Payment Method") {
                self.dismiss()
            }
            ScrollView {
                if !onlyAddressVerification {
                    PaymentCardDetailView(cardData: $onboardingContainerViewModel.cardData)
                    if let cardError = onboardingContainerViewModel.fieldErrors[.paymentCard] {
                        Text(cardError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                }
                BillingAddressDetailView(viewModel: onboardingContainerViewModel,
                                         addressNamespace: .payment,
                                         addressLineOne: $onboardingContainerViewModel.createdBillingAddress.addressLine1.orEmpty,
                                         addressLineTwo: $onboardingContainerViewModel.createdBillingAddress.addressLine2.orEmpty,
                                         city: $onboardingContainerViewModel.createdBillingAddress.city.orEmpty,
                                         state: $onboardingContainerViewModel.createdBillingAddress.state.orEmpty,
                                         zipCode: $onboardingContainerViewModel.createdBillingAddress.postalCode,
                                         country: $onboardingContainerViewModel.createdBillingAddress.country.orEmpty)
                ContinueButton(enabled: .constant(true)) {
                    guard onboardingContainerViewModel.validateAllPaymentMethod(onlyAddress: onlyAddressVerification) else { return }
                    Task {
                        if onlyAddressVerification {
                            await onboardingContainerViewModel.updatePaymentMethod()
                        } else {
                            await onboardingContainerViewModel.addNewPaymentMethod()
                        }
                        self.dismiss()
                    }
                }
                KeyboardSpacing()
            }
        }
    }
}

#Preview {
    AddPaymentMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []), onlyAddressVerification: false)
}
