//
//  AddPaymentMethodView.swift
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
    @StateObject private var billingVM: BillingAddressViewModel
    @State private var cardError: String?

    var onlyAddressVerification: Bool = false

    init(onboardingContainerViewModel: OnboardingContainerViewModel, onlyAddressVerification: Bool) {
        self._onboardingContainerViewModel = StateObject(wrappedValue: onboardingContainerViewModel)
        self.onlyAddressVerification = onlyAddressVerification
        self._billingVM = StateObject(wrappedValue: BillingAddressViewModel(
            address: onboardingContainerViewModel.createdBillingAddress,
            mode: .usOnly
        ))
    }

    var body: some View {
        VStack(alignment: .leading) {
            addPaymentMethodView
        }
        .onChange(of: onboardingContainerViewModel.cardData) { _, _ in
            cardError = nil
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
                    if let cardError {
                        Text(cardError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                }
                BillingAddressDetailView(viewModel: billingVM)
                ContinueButton(enabled: .constant(true)) {
                    let addressOK = billingVM.validate()
                    var cardOK = true
                    if !onlyAddressVerification {
                        if let err = Validators.validateCard(onboardingContainerViewModel.cardData) {
                            cardError = err
                            cardOK = false
                        } else {
                            cardError = nil
                        }
                    }
                    guard addressOK && cardOK else { return }
                    onboardingContainerViewModel.createdBillingAddress = billingVM.address
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
