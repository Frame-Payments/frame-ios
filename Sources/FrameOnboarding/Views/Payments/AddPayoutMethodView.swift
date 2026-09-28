//
//  AddPayoutMethodView.swift
//  Frame-iOS
//

import SwiftUI
import EvervaultInputs
import Frame

struct AddPayoutMethodView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.frameTheme) private var theme
    @StateObject private var onboardingContainerViewModel: OnboardingContainerViewModel
    @StateObject private var bankVM: BankAccountViewModel

    @State private var selectedAccountType: FrameObjects.PaymentAccountType = .checking
    @State private var accountTypeString: String = FrameObjects.PaymentAccountType.checking.rawValue.capitalized
    @State private var showAccountTypePicker: Bool = false
    @State private var showManualForm: Bool = false

    init(onboardingContainerViewModel: OnboardingContainerViewModel) {
        self._onboardingContainerViewModel = StateObject(wrappedValue: onboardingContainerViewModel)
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
            // Single horizontal inset for the whole column — child views must not add their own.
            VStack(alignment: .leading, spacing: theme.spacing.formBlock) {
                MethodOptionRow(
                    iconName: "connect-bank-account-icon",
                    title: "Connect a bank account"
                ) {
                    guard let presenter = UIApplication.shared.topViewController else { return }
                    Task {
                        await onboardingContainerViewModel.openPlaidLink(from: presenter) {
                            self.dismiss()
                        }
                    }
                }

                Button {
                    showManualForm.toggle()
                } label: {
                    HStack {
                        Text("Enter bank details manually")
                            .font(theme.fonts.bodySmall)
                            .foregroundStyle(theme.colors.textPrimary)
                        Spacer()
                        Image(systemName: showManualForm ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radii.medium)
                            .fill(theme.colors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.medium)
                            .strokeBorder(theme.colors.surfaceStroke, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if showManualForm {
                    BankAccountDetailView(viewModel: bankVM, applyHorizontalPadding: false)
                    DropDownWithHeaderView(headerText: .constant("Account type"),
                                           dropDownText: $accountTypeString,
                                           showDropdownPicker: $showAccountTypePicker,
                                           applyHorizontalPadding: false)
                    ContinueButton(buttonText: "Save bank",
                                   isLoading: .constant(onboardingContainerViewModel.isPerformingAction),
                                   includeOuterPadding: false) {
                        bankVM.account.accountType = selectedAccountType
                        guard bankVM.validate() else { return }
                        onboardingContainerViewModel.bankAccount = bankVM.account
                        Task {
                            await onboardingContainerViewModel.addNewPayoutMethod()
                            self.dismiss()
                        }
                    }
                    KeyboardSpacing(spacingHeight: 200.0)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    AddPayoutMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []))
}
