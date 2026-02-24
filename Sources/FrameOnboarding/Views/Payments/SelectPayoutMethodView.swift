//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/8/26.
//

import SwiftUI
import EvervaultInputs
import Frame

struct SelectPayoutMethodView: View {
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel
    
    @State private var canCustomerContinue: Bool = false
    @State private var showAddPayoutMethod: Bool = false
    
    @Binding var continueToNextStep: Bool
    @Binding var returnToPreviousStep: Bool
    
    var body: some View {
        NavigationStack {
            selectPayoutView
                .navigationDestination(isPresented: $showAddPayoutMethod) {
                    AddPayoutMethodView(onboardingContainerViewModel: onboardingContainerViewModel)
                        .navigationBarBackButtonHidden()
                }
        }
        .onChange(of: onboardingContainerViewModel.selectedPayoutMethod) { oldValue, newValue in
            self.canCustomerContinue = newValue != nil
        }
    }
    
    var selectPayoutView: some View {
        VStack(alignment: .leading) {
            listPaymentMethodsView
            Spacer()
            ContinueButton(enabled: $canCustomerContinue) {
                Task {
                    //TODO: Update the payout method via the backend.
//                    await onboardingContainerViewModel.updatePayoutMethod()
                    self.continueToNextStep = true
                }
            }
            .padding(.bottom)
        }
    }
    
    var listPaymentMethodsView: some View {
        Group {
            PageHeaderView(headerTitle: "Select A Payout Method") {
                self.returnToPreviousStep = true
            }
            Text("Choose a saved payout method or add a new one to continue")
                .fontWeight(.light)
                .font(.system(size: 14.0))
                .padding(.horizontal)
            ScrollView {
                if !onboardingContainerViewModel.payoutMethods.isEmpty {
                    headerScrollTitles(name: "Saved Payout Methods")
                    ForEach(onboardingContainerViewModel.payoutMethods) { payoutMethods in
                        payoutMethodView(payoutMethod: payoutMethods)
                    }
                }
                headerScrollTitles(name: "Add Payout Method")
                addPayoutMethodRow
            }
        }
    }
    
    func headerScrollTitles(name: String) -> some View {
        HStack {
            Text(name)
                .bold()
                .font(.system(size: 14.0))
                .padding(.horizontal)
                .padding(.vertical, 8.0)
            Spacer()
        }
    }
    
    var addPayoutMethodRow: some View {
        HStack {
            Image("emptycard", bundle: FrameResources.module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48.0, height: 32.0)
                .padding(.horizontal)
            Text("Bank Account (ACH)")
                .bold()
                .font(.system(size: 14.0))
            Spacer()
            Image("right-chevron", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .onTapGesture {
            self.showAddPayoutMethod = true
        }
    }
    
    func payoutMethodView(payoutMethod: FrameObjects.PaymentMethod) -> some View {
        HStack {
            Image("bank-icon", bundle: FrameResources.module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48.0, height: 32.0)
                .padding(.horizontal)
            VStack(alignment: .leading) {
                Text("•••• \(payoutMethod.ach?.lastFour ?? "")")
                    .bold()
                    .font(.system(size: 14.0))
                    .padding(.bottom, 1.0)
                Text((payoutMethod.ach?.accountType?.rawValue.capitalized ?? "") + " Account")
                    .font(.system(size: 12.0))
            }
            Spacer()
            Image(onboardingContainerViewModel.selectedPayoutMethod == payoutMethod ? "filled-selection" : "empty-selection", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .onTapGesture {
            onboardingContainerViewModel.selectedPayoutMethod = payoutMethod
        }
    }
}

#Preview {
    SelectPayoutMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []),
                            continueToNextStep: .constant(false),
                            returnToPreviousStep: .constant(false))
}
