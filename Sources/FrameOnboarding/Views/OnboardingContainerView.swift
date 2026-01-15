//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/24/25.
//

import SwiftUI
import Frame

public enum OnboardingFlow: String, CaseIterable, Identifiable {
    public var id: String {
        return "\(self.rawValue)"
    }

    case countryVerification
    case confirmPaymentMethod
    case confirmPayoutMethod
    case uploadDocuments
    case uploadSelfie
    case verificationSubmitted
}

public struct OnboardingContainerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var onboardingContainerViewModel: OnboardingContainerViewModel
    
    @State private var currentStep: OnboardingFlow = .countryVerification
    @State private var onboardingFlow: [OnboardingFlow] = [.countryVerification, .confirmPaymentMethod, .confirmPayoutMethod, .uploadDocuments, .verificationSubmitted]
    @State private var progressiveSteps: [OnboardingFlow] = [.countryVerification]
    @State private var continueToNextStep: Bool = false
    @State private var returnToPreviousStep: Bool = false
    
    let customerId: String
    
    public init(customerId: String, customOnboardingFlow: [OnboardingFlow]? = nil) {
        self.customerId = customerId
        self.onboardingContainerViewModel = OnboardingContainerViewModel(customerId: customerId,
                                                                         components: SessionComponents(paymentMethod: PaymentMethodComponent(enabled: true),
                                                                                                       identityVerification: IdentityVerificationComponent(enabled: true)))
        if let customOnboardingFlow {
            self.onboardingFlow = customOnboardingFlow
            self.currentStep = customOnboardingFlow.first ?? .countryVerification
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
            case .confirmPayoutMethod:
                SelectPayoutMethodView(onboardingContainerViewModel: onboardingContainerViewModel,
                                       continueToNextStep: $continueToNextStep,
                                       returnToPreviousStep: $returnToPreviousStep)
            case .countryVerification:
                UserIdentificationView(onboardingContainerViewModel: onboardingContainerViewModel,
                                       continueToNextStep: $continueToNextStep)
            case .uploadDocuments:
                UploadIdentificationView(onboardingContainerViewModel: onboardingContainerViewModel,
                                         continueToNextStep: $continueToNextStep,
                                         returnToPreviousStep: $returnToPreviousStep)
            case .uploadSelfie:
                UploadSelfieView(onboardingContainerViewModel: onboardingContainerViewModel,
                                 continueToNextStep: $continueToNextStep,
                                 returnToPreviousStep: $returnToPreviousStep)
            case .verificationSubmitted:
                VerificationSubmittedView(continueToNextStep: $continueToNextStep)
            }
            Spacer()
        }
        .ignoresSafeArea()
        .keyboardDoneToolbar()
        .onChange(of: continueToNextStep) { oldValue, newValue in
            guard continueToNextStep else { return }
            guard onboardingFlow.last != currentStep else {
                self.dismiss()
                return
            } // Complete onboarding here.
            
            let index: Int = (onboardingFlow.firstIndex(of: currentStep) ?? 0) + 1
            self.currentStep = onboardingFlow[index]
            self.continueToNextStep = false
        }
        .onChange(of: returnToPreviousStep, { oldValue, newValue in
            guard returnToPreviousStep else { return }
            guard onboardingFlow.first != currentStep else { return }
            
            let index: Int = (onboardingFlow.firstIndex(of: currentStep) ?? 0) - 1
            self.currentStep = onboardingFlow[index]
            self.returnToPreviousStep = false
        })
        .onChange(of: currentStep) {
            let index: Int = (onboardingFlow.firstIndex(of: currentStep) ?? 0) + 1
            self.progressiveSteps = Array(self.onboardingFlow[0..<index])
        }
    }
    
    var containerHeader: some View {
        Rectangle()
            .fill(Color(hex: "#FCFBF8"))
            .overlay {
                VStack {
                    Spacer()
                    HStack {
                        ForEach(onboardingFlow) { step in
                            Image(progressiveSteps.contains(step) ? "filled-onboarding-indicator" : "empty-onboarding-indicator", bundle: FrameResources.module)
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
    OnboardingContainerView(customerId: "cust_123")
}
