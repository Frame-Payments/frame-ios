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
    @StateObject private var billingVM: BillingAddressViewModel
    @StateObject private var bankVM: BankAccountViewModel

    @State private var selectedAccountType: FrameObjects.PaymentAccountType = .checking
    @State private var accountTypeString: String = FrameObjects.PaymentAccountType.checking.rawValue.capitalized
    @State private var showAccountTypePicker: Bool = false
    @State private var showManualForm: Bool = false

    init(onboardingContainerViewModel: OnboardingContainerViewModel) {
        self._onboardingContainerViewModel = StateObject(wrappedValue: onboardingContainerViewModel)
        self._billingVM = StateObject(wrappedValue: BillingAddressViewModel(
            address: onboardingContainerViewModel.createdBillingAddress,
            mode: .usOnly
        ))
        self._bankVM = StateObject(wrappedValue: BankAccountViewModel(
            account: onboardingContainerViewModel.bankAccount
        ))
    }

    var body: some View {
        VStack(alignment: .leading) {
            addPayoutMethodView
            Spacer()
        }
        .onChange(of: selectedAccountType, { oldValue, newValue in
            self.bankVM.account.accountType = selectedAccountType
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
        PageHeaderView(headerTitle: "Add Bank Account") {
            self.dismiss()
        }
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ContinueButton(buttonText: "Connect Bank Account", enabled: .constant(!onboardingContainerViewModel.isConnectingPlaidBank)) {
                    Task {
                        await onboardingContainerViewModel.openPlaidLink(from: topViewController()) {
                            self.dismiss()
                        }
                    }
                }
                .overlay {
                    if onboardingContainerViewModel.isConnectingPlaidBank {
                        ProgressView()
                    }
                }

                Button("Enter manually") {
                    showManualForm = true
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

                if showManualForm {
                    BankAccountDetailView(viewModel: bankVM)
                    DropDownWithHeaderView(headerText: .constant("Account Type"),
                                           dropDownText: $accountTypeString,
                                           showDropdownPicker: $showAccountTypePicker)
                    BillingAddressDetailView(viewModel: billingVM)
                    KeyboardSpacing()
                    ContinueButton(buttonText: "Add Bank Account", enabled: .constant(true)) {
                        bankVM.account.accountType = selectedAccountType
                        let bankOK = bankVM.validate()
                        let addressOK = billingVM.validate()
                        guard bankOK, addressOK else { return }
                        onboardingContainerViewModel.bankAccount = bankVM.account
                        onboardingContainerViewModel.createdBillingAddress = billingVM.address
                        Task {
                            await onboardingContainerViewModel.addNewPayoutMethod()
                            self.dismiss()
                        }
                    }
                }
            }
        }
    }

    private func topViewController() -> UIViewController {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else {
            return UIViewController()
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

#Preview {
    AddPayoutMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []))
}
