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
                bankAccountDetails
                Text("Account Type")
                    .bold()
                    .font(.subheadline)
                    .padding([.horizontal, .top])
                dropdownSelectionBox(titleName: "")
                billingAddressDetails
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
    
    @ViewBuilder
    var bankAccountDetails: some View {
        Text("Bank Account Details")
            .bold()
            .font(.subheadline)
            .padding([.horizontal, .top])
        RoundedRectangle(cornerRadius: 10.0)
            .fill(.white)
            .stroke(.gray.opacity(0.3))
            .frame(height: 100.0)
            .overlay {
                VStack(spacing: 0) {
                    TextField("",
                              text: $onboardingContainerViewModel.bankAccount.routingNumber.orEmpty,
                              prompt: Text("Routing Number"))
                    .frame(height: 49.0)
                    .padding(.horizontal)
                    Divider()
                    TextField("",
                              text: $onboardingContainerViewModel.bankAccount.accountNumber.orEmpty,
                              prompt: Text("Account Number"))
                    .frame(height: 49.0)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
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
    
    @ViewBuilder
    func dropdownSelectionBox(titleName: String) -> some View {
        Text(titleName)
            .padding([.horizontal])
            .fontWeight(.semibold)
            .font(.system(size: 13.0))
        HStack {
            Text(selectedAccountType.rawValue.capitalized)
                .fontWeight(.medium)
                .font(.system(size: 14.0))
                .padding()
            Spacer()
            Image("down-chevron", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 42.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding([.horizontal])
        .onTapGesture {
            self.showAccountTypePicker.toggle()
        }
    }
}

#Preview {
    AddPayoutMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(customerId: "", components: SessionComponents()))
}
