//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 11/24/25.
//

import SwiftUI
import Frame_iOS

enum OnboardingFlow: String, CaseIterable, Identifiable {
    var id: String {
        return "\(self.rawValue)"
    }

    case countryVerification
    case confirmPaymentMethod
    case uploadDocuments
    case onboardingComplete
}

struct OnboardingContainerView: View {
    @State private var currentStep: OnboardingFlow = .countryVerification
    @State private var onboardingFlow: [OnboardingFlow] = [.countryVerification, .confirmPaymentMethod, .uploadDocuments, .onboardingComplete]
    @State private var progressiveSteps: [OnboardingFlow] = [.countryVerification]
    @State private var continueToNextStep: Bool = false
    @State private var returnToPreviousStep: Bool = false
    
    let customerId: String
    
    init(customerId: String, customOnboardingFlow: [OnboardingFlow]? = nil) {
        self.customerId = customerId
        
        if let customOnboardingFlow {
            self.onboardingFlow = customOnboardingFlow
            self.currentStep = customOnboardingFlow.first ?? .countryVerification
        }
    }
    
    var body: some View {
        VStack {
            containerHeader
            switch currentStep {
            case .confirmPaymentMethod:
                SelectPaymentMethodView(continueToNextStep: $continueToNextStep,
                                        returnToPreviousStep: $returnToPreviousStep,
                                        customerId: customerId)
            case .countryVerification:
                UserIdentificationView(continueToNextStep: $continueToNextStep)
            case .uploadDocuments:
                UploadIdentificationView(continueToNextStep: $continueToNextStep, returnToPreviousStep: $returnToPreviousStep)
            case .onboardingComplete:
                VerificationSubmittedView()
            }
            Spacer()
        }
        .ignoresSafeArea()
        .onChange(of: continueToNextStep) { oldValue, newValue in
            guard continueToNextStep else { return }
            guard onboardingFlow.last != currentStep else { return } // Complete onboarding here.
            
            let index: Int = (onboardingFlow.firstIndex(of: currentStep) ?? 0) + 1
            self.currentStep = onboardingFlow[index]
            print(currentStep.rawValue)
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
                        }
                    }
                    .padding(.bottom, 15.0)
                    Divider()
                }
            }
            .frame(height: 100.0)
    }
}

#Preview {
    OnboardingContainerView(customerId: "cust_123")
}
