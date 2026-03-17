//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/24/25.
//

import SwiftUI
import Frame

public enum OnboardingFlow: Int, CaseIterable, Identifiable {
    public var id: String {
        return "\(self.rawValue)"
    }

//    case countryVerification
//    case geolocationVerification
//    case uploadDocuments
    
    case personalInformation = 0
    case confirmPaymentMethod = 1
    case confirmBankAccount = 2
    case verificationSubmitted = 3
}

extension FrameObjects.Capabilities {
    public var onboardingStep: OnboardingFlow {
        switch self {
        /* - Platforms will use either .kyc OR .kycprefill capability, not both.
           - Phone verification is seperate from prefill, used to validate number for auth via Twilio.
           - Phone verification is almost always REQUIRED */
        case .ageVerification, .kyc, .kycPrefill, .phoneVerification, .creatorShield, .geoCompliance:
            return .personalInformation
        /* - Card verification enables 3DS flow.
           - Address Verification adds the address section to the Add Payment method screen. */
        case .cardVerification, .cardSend, .cardReceive, .addressVerification:
            return .confirmPaymentMethod
        case .bankAccountVerification, .bankAccountSend, .bankAccountReceive:
            return .confirmBankAccount
        }
    }
}

public struct OnboardingContainerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var onboardingContainerViewModel: OnboardingContainerViewModel
    
    @State private var currentStep: OnboardingFlow = .personalInformation
    @State private var continueToNextStep: Bool = false
    @State private var returnToPreviousStep: Bool = false
    
    public init(accountId: String? = nil, requiredCapabilities: [FrameObjects.Capabilities] = []) {
        self.onboardingContainerViewModel = OnboardingContainerViewModel(accountId: accountId, requiredCapabilities: requiredCapabilities)
        
        if requiredCapabilities != [] {
            // Map capabilites to onboarding flow steps
            let onboardingSet = Set(requiredCapabilities.map { $0.onboardingStep })
            var onboardingArray = Array(onboardingSet).sorted(by: { $0.rawValue < $1.rawValue })
            onboardingArray.append(.verificationSubmitted)
            
            onboardingContainerViewModel.progressiveSteps = [onboardingArray.first ?? .personalInformation]
            onboardingContainerViewModel.onboardingFlow = onboardingArray
            self._currentStep = State(initialValue: onboardingArray.first ?? .personalInformation)
        } else {
            onboardingContainerViewModel.progressiveSteps = [.personalInformation]
            onboardingContainerViewModel.onboardingFlow = [.personalInformation, .verificationSubmitted]
            self._currentStep = State(initialValue: .personalInformation)
        }
    }
    
    public var body: some View {
        VStack {
            containerHeader
            switch currentStep {
            case .confirmPaymentMethod:
                SelectPaymentMethodView(onboardingContainerViewModel: onboardingContainerViewModel,
                                        continueToNextStep: $continueToNextStep,
                                        returnToPreviousStep: $returnToPreviousStep)
            case .confirmBankAccount:
                SelectPayoutMethodView(onboardingContainerViewModel: onboardingContainerViewModel,
                                       continueToNextStep: $continueToNextStep,
                                       returnToPreviousStep: $returnToPreviousStep)
            case .personalInformation:
                UserIdentificationView(onboardingContainerViewModel: onboardingContainerViewModel,
                                       continueToNextStep: $continueToNextStep)
//            case .geolocationVerification:
//                GeolocationView(onboardingContainerViewModel: onboardingContainerViewModel,
//                                continueToNextStep: $continueToNextStep)
//            case .uploadDocuments:
//                UploadIdentificationView(onboardingContainerViewModel: onboardingContainerViewModel,
//                                         continueToNextStep: $continueToNextStep,
//                                         returnToPreviousStep: $returnToPreviousStep)
            case .verificationSubmitted:
                VerificationSubmittedView(continueToNextStep: $continueToNextStep)
            }
            Spacer()
        }
        .ignoresSafeArea()
        .keyboardDoneToolbar()
        .onAppear {
            if onboardingContainerViewModel.accountId != nil {
                Task {
                    await onboardingContainerViewModel.checkExistingAccount(updateCapabilies: true)
                }
            }
        }
        .onChange(of: continueToNextStep) { oldValue, newValue in
            guard continueToNextStep else { return }
            guard onboardingContainerViewModel.onboardingFlow.last != currentStep else {
                self.dismiss()
                return
            } // Complete onboarding here.
            
            let index: Int = (onboardingContainerViewModel.onboardingFlow.firstIndex(of: currentStep) ?? 0) + 1
            self.currentStep = onboardingContainerViewModel.onboardingFlow[index]
            self.continueToNextStep = false
        }
        .onChange(of: returnToPreviousStep, { oldValue, newValue in
            guard returnToPreviousStep else { return }
            guard onboardingContainerViewModel.onboardingFlow.first != currentStep else { return }
            
            let index: Int = (onboardingContainerViewModel.onboardingFlow.firstIndex(of: currentStep) ?? 0) - 1
            self.currentStep = onboardingContainerViewModel.onboardingFlow[index]
            self.returnToPreviousStep = false
        })
        .onChange(of: currentStep) {
            let index: Int = (onboardingContainerViewModel.onboardingFlow.firstIndex(of: currentStep) ?? 0) + 1
            onboardingContainerViewModel.progressiveSteps = Array(onboardingContainerViewModel.onboardingFlow[0..<index])
        }
        .onChange(of: onboardingContainerViewModel.progressiveSteps, { oldValue, newValue in
            self.currentStep = onboardingContainerViewModel.progressiveSteps.first ?? .personalInformation
        })
    }
    
    var containerHeader: some View {
        Rectangle()
            .fill(Color(hex: "#FCFBF8"))
            .overlay {
                VStack {
                    Spacer()
                    HStack {
                        ForEach(onboardingContainerViewModel.onboardingFlow) { step in
                            Image(onboardingContainerViewModel.progressiveSteps.contains(step) ? "filled-onboarding-indicator" : "empty-onboarding-indicator", bundle: FrameResources.module)
                                .resizable()
                                .frame(height: 5.0)
                        }
                    }
                    .padding(.bottom, 15.0)
                    .padding(.horizontal)
                    Divider()
                }
            }
            .frame(height: 100.0)
    }
}

#Preview {
    OnboardingContainerView(requiredCapabilities: [.kycPrefill, .cardVerification, .geoCompliance, .bankAccountVerification, .ageVerification])
}
