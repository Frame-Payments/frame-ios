//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/11/25.
//

import SwiftUI
import EvervaultInputs
import Frame

struct AddPayoutMethodView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var onboardingContainerViewModel: OnboardingContainerViewModel
    
    @State private var selectedAccountType: FrameObjects.PaymentAccountType = .checking
    @State private var accountTypeString: String = FrameObjects.PaymentAccountType.checking.rawValue.capitalized
    @State private var canCustomerContinue: Bool = false
    @State private var showAccountTypePicker: Bool = false
    
    init(onboardingContainerViewModel: OnboardingContainerViewModel) {
        self._onboardingContainerViewModel = StateObject(wrappedValue: onboardingContainerViewModel)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            addPayoutMethodView
            Spacer()
        }
        .onChange(of: onboardingContainerViewModel.bankAccount) { oldValue, newValue in
            self.canCustomerContinue = onboardingContainerViewModel.checkIfCustomerCanContinueWithPayoutMethod()
        }
        .onChange(of: onboardingContainerViewModel.createdBillingAddress) { oldValue, newValue in
            self.canCustomerContinue = onboardingContainerViewModel.checkIfCustomerCanContinueWithPayoutMethod()
        }
        .onChange(of: selectedAccountType, { oldValue, newValue in
            self.accountTypeString = selectedAccountType.rawValue.capitalized
        })
        .sheet(isPresented: $showAccountTypePicker) {
            Picker("type", selection: $selectedAccountType) {
                ForEach(FrameObjects.PaymentAccountType.allCases, id: \.self) { type in
                    Text(type.rawValue.capitalized)
                }
            }
            .pickerStyle(.wheel)
            .presentationDetents([.height(200.0)])
        }
    }
    
    @ViewBuilder
    var addPayoutMethodView: some View {
        PageHeaderView(headerTitle: "Add Bank Account (ACH)") {
            self.dismiss()
        }
        ScrollView {
            VStack(alignment: .leading) {
                BankAccountDetailView(routingNumber: $onboardingContainerViewModel.bankAccount.routingNumber.orEmpty,
                                      accountNumber: $onboardingContainerViewModel.bankAccount.accountNumber.orEmpty)
                DropDownWithHeaderView(headerText: .constant("Account Type"),
                                       dropDownText: $accountTypeString,
                                       showDropdownPicker: $showAccountTypePicker)
                BillingAddressDetailView(addressLineOne: $onboardingContainerViewModel.createdBillingAddress.addressLine1.orEmpty,
                                         addressLineTwo: $onboardingContainerViewModel.createdBillingAddress.addressLine2.orEmpty,
                                         city: $onboardingContainerViewModel.createdBillingAddress.city.orEmpty,
                                         state: $onboardingContainerViewModel.createdBillingAddress.state.orEmpty,
                                         zipCode: $onboardingContainerViewModel.createdBillingAddress.postalCode,
                                         country: $onboardingContainerViewModel.createdBillingAddress.country.orEmpty)
                KeyboardSpacing()
            }
        }
        ContinueButton(buttonText: "Add Bank Account", enabled: $canCustomerContinue) {
            Task {
                onboardingContainerViewModel.bankAccount.accountType = selectedAccountType
                await onboardingContainerViewModel.addNewPayoutMethod()
                self.dismiss()
            }
        }
    }
}

#Preview {
    AddPayoutMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: ""))
}
