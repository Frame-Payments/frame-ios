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
    @State private var walletButtonError: String?

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
                    walletButton
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
                walletButtonError.map {
                    Text($0)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                ContinueButton(isLoading: .constant(onboardingContainerViewModel.isPerformingAction)) {
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

    @ViewBuilder
    var walletButton: some View {
        if let merchantId = onboardingContainerViewModel.applePayMerchantId,
           !merchantId.isEmpty,
           let accountId = onboardingContainerViewModel.accountId,
           !accountId.isEmpty {
            FrameApplePayButton(
                mode: .addToOwner,
                owner: .account(accountId),
                merchantId: merchantId,
                addCheckoutDivider: true,
                buttonType: .continue,
            ) { result in
                switch result {
                case .success(.paymentMethod(let pm)):
                    onboardingContainerViewModel.appendNewlyAddedPaymentMethod(pm)
                    self.dismiss()
                case .success(.charge):
                    // Not produced in `.addToOwner` mode.
                    break
                case .failure(let error):
                    self.walletButtonError = (error as NSError).localizedDescription
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    AddPaymentMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []), onlyAddressVerification: false)
}
