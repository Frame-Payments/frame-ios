//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/11/25.
//

import SwiftUI
import EvervaultInputs
import Frame
import LinkKit

struct AddPayoutMethodView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var onboardingContainerViewModel: OnboardingContainerViewModel

    @State private var selectedAccountType: FrameObjects.PaymentAccountType = .checking
    @State private var accountTypeString: String = FrameObjects.PaymentAccountType.checking.rawValue.capitalized
    @State private var canCustomerContinue: Bool = false
    @State private var showAccountTypePicker: Bool = false
    @State private var showManualForm: Bool = false
    @State private var plaidHandler: Handler?

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
            self.onboardingContainerViewModel.bankAccount.accountType = selectedAccountType
            self.accountTypeString = selectedAccountType.rawValue.capitalized
        })
        .onChange(of: onboardingContainerViewModel.plaidLinkToken) { _, token in
            guard let token else { return }
            onboardingContainerViewModel.plaidLinkToken = nil
            var config = LinkTokenConfiguration(token: token) { success in
                Task { @MainActor in
                    guard let account = success.metadata.accounts.first,
                          !account.id.isEmpty else {
                        onboardingContainerViewModel.isConnectingPlaidBank = false
                        return
                    }
                    await onboardingContainerViewModel.handlePlaidSuccess(
                        publicToken: success.publicToken,
                        plaidAccountId: account.id,
                        institutionName: success.metadata.institution?.name,
                        subtype: account.subtype.rawValue
                    )
                    self.dismiss()
                }
            }
            config.onExit = { exit in
                Task { @MainActor in
                    onboardingContainerViewModel.isConnectingPlaidBank = false
                }
                if let error = exit.error {
                    print("Plaid Link exited with error: \(error.displayMessage ?? error.errorCode)")
                }
            }
            let result = Plaid.create(config)
            switch result {
            case .success(let handler):
                self.plaidHandler = handler
                handler.open(presentUsing: .viewController(topViewController()))
            case .failure(let error):
                onboardingContainerViewModel.isConnectingPlaidBank = false
                print("Plaid.create failed: \(error.localizedDescription)")
            }
        }
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
                        await onboardingContainerViewModel.fetchPlaidLinkToken()
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
                    ContinueButton(buttonText: "Add Bank Account", enabled: $canCustomerContinue) {
                        Task {
                            onboardingContainerViewModel.bankAccount.accountType = selectedAccountType
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
