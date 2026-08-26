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
    @Environment(\.frameTheme) private var theme
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel

    @State private var canCustomerContinue: Bool = false
    @State private var showAddPayoutMethod: Bool = false

    @Binding var continueToNextStep: Bool
    @Binding var returnToPreviousStep: Bool

    /// Set by standalone hosts. Nil in onboarding, which advances via ``continueToNextStep``.
    var onElected: ((FrameObjects.PaymentMethod) -> Void)?

    /// Set by standalone hosts. Nil in onboarding, which uses a back button instead of a close one.
    var onClose: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            selectPayoutView
                .navigationDestination(isPresented: $showAddPayoutMethod) {
                    AddPayoutMethodView(onboardingContainerViewModel: onboardingContainerViewModel)
                        .navigationBarBackButtonHidden()
                }
        }
        .onAppear {
            // Otherwise the list is only populated as a side effect of the card step, which an
            // account that skips that step never runs.
            Task {
                await onboardingContainerViewModel.loadExistingPaymentMethods()
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
                    guard let payoutMethod = onboardingContainerViewModel.selectedPayoutMethod else { return }

                    // On continue rather than on row tap, so browsing doesn't call the API per tap.
                    guard await onboardingContainerViewModel.electPayoutMethod(payoutMethod) else { return }

                    if let onElected {
                        onElected(payoutMethod)
                    } else {
                        self.continueToNextStep = true
                    }
                }
            }
            .padding(.bottom)
        }
    }
    
    var listPaymentMethodsView: some View {
        Group {
            PageHeaderView(useCloseButton: onClose != nil,
                           headerTitle: "Select A Payout Method") {
                if let onClose {
                    onClose()
                } else {
                    self.returnToPreviousStep = true
                }
            }
            Text("Choose a saved payout method or add a new one to continue")
                .fontWeight(.light)
                .font(theme.fonts.bodySmall)
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
                .font(theme.fonts.bodySmall)
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
                .font(theme.fonts.bodySmall)
            Spacer()
            Image("right-chevron", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .stroke(theme.colors.surfaceStroke, lineWidth: 1)
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
                    .font(theme.fonts.bodySmall)
                    .padding(.bottom, 1.0)
                HStack(spacing: 6.0) {
                    Text((payoutMethod.ach?.accountType?.rawValue.capitalized ?? "") + " Account")
                        .font(theme.fonts.caption)
                    if onboardingContainerViewModel.primaryPayoutMethodId == payoutMethod.id {
                        Text("Primary")
                            .font(theme.fonts.caption)
                            .bold()
                            .foregroundStyle(theme.colors.textPrimary)
                    }
                }
            }
            Spacer()
            Image(onboardingContainerViewModel.selectedPayoutMethod == payoutMethod ? "filled-selection" : "empty-selection", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .stroke(theme.colors.surfaceStroke, lineWidth: 1)
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

#Preview("Dark") {
    SelectPayoutMethodView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []),
                            continueToNextStep: .constant(false),
                            returnToPreviousStep: .constant(false))
        .preferredColorScheme(.dark)
}
