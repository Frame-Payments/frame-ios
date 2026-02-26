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
    case confirmPaymentMethod = 1
    case confirmPayoutMethod = 2
    case geolocationVerification = 4
    case personalInformation = 0
    case uploadDocuments = 3
    case verificationSubmitted = 5
}

extension FrameObjects.Capabilities {
    public var onboardingStep: OnboardingFlow {
        switch self {
        case .kyc, .kycPrefill, .phoneVerification, .creatorShield:
            return .personalInformation
        case .cardVerification, .cardSend, .cardReceive, .addressVerification:
            return .confirmPaymentMethod
        case .bankAccountVerification, .bankAccountSend, .bankAccountReceive:
            return .confirmPayoutMethod
        case .geoCompliance:
            return .geolocationVerification
        case .ageVerification:
            return .uploadDocuments
        }
    }
}

public struct OnboardingContainerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var onboardingContainerViewModel: OnboardingContainerViewModel
    
    @State private var currentStep: OnboardingFlow = .personalInformation
    @State private var onboardingFlow: [OnboardingFlow] = [.personalInformation, .confirmPaymentMethod, .confirmPayoutMethod, .uploadDocuments, .verificationSubmitted]
    @State private var progressiveSteps: [OnboardingFlow] = [.personalInformation]
    @State private var continueToNextStep: Bool = false
    @State private var returnToPreviousStep: Bool = false
    
    public init(accountId: String? = nil, requiredCapabilities: [FrameObjects.Capabilities] = []) {
        self.onboardingContainerViewModel = OnboardingContainerViewModel(accountId: accountId, requiredCapabilities: requiredCapabilities)
        // Map capabilites to onboarding flow steps
        let onboardingSet = Set(requiredCapabilities.map { $0.onboardingStep })
        self.onboardingFlow = Array(onboardingSet).sorted(by: { $0.rawValue > $1.rawValue })
        self.onboardingFlow.append(.verificationSubmitted)
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
            case .personalInformation:
                UserIdentificationView(onboardingContainerViewModel: onboardingContainerViewModel,
                                       continueToNextStep: $continueToNextStep)
            case .geolocationVerification:
                GeolocationView(onboardingContainerViewModel: onboardingContainerViewModel,
                                continueToNextStep: $continueToNextStep)
            case .uploadDocuments:
                UploadIdentificationView(onboardingContainerViewModel: onboardingContainerViewModel,
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
    OnboardingContainerView(requiredCapabilities: [.kycPrefill, .cardVerification, .bankAccountVerification, .ageVerification])
}
