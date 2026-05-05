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
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var onboardingContainerViewModel: OnboardingContainerViewModel

    var onComplete: (() -> Void)?

    @State private var continueToNextStep: Bool = false
    @State private var returnToPreviousStep: Bool = false
    @State private var startedOnboarding: Bool = false
    @State private var accountLoaded: Bool = false

    public init(accountId: String? = nil,
                requiredCapabilities: [FrameObjects.Capabilities] = [],
                applePayMerchantId: String? = nil,
                onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onboardingContainerViewModel = OnboardingContainerViewModel(accountId: accountId,
                                                                         requiredCapabilities: requiredCapabilities,
                                                                         applePayMerchantId: applePayMerchantId)
        
        if requiredCapabilities != [] {
            // Map capabilites to onboarding flow steps
            let onboardingSet = Set(requiredCapabilities.map { $0.onboardingStep })
            var onboardingArray = Array(onboardingSet).sorted(by: { $0.rawValue < $1.rawValue })
            onboardingArray.append(.verificationSubmitted)
            
            onboardingContainerViewModel.progressiveSteps = [onboardingArray.first ?? .personalInformation]
            onboardingContainerViewModel.onboardingFlow = onboardingArray
            onboardingContainerViewModel.currentStep = onboardingArray.first ?? .personalInformation
        } else {
            onboardingContainerViewModel.progressiveSteps = [.personalInformation]
            onboardingContainerViewModel.onboardingFlow = [.personalInformation, .verificationSubmitted]
            onboardingContainerViewModel.currentStep = .personalInformation
        }
    }
    
    public var body: some View {
        VStack {
            if startedOnboarding {
                containerHeader
                switch onboardingContainerViewModel.currentStep {
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
                                           continueToNextStep: $continueToNextStep,
                                           returnToPreviousStep: $returnToPreviousStep)
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
            } else {
                onboardingIntro
            }
            Spacer()
        }
        .ignoresSafeArea()
        .keyboardDoneToolbar()
        .onAppear {
            if onboardingContainerViewModel.accountId != nil {
                Task {
                    await onboardingContainerViewModel.checkExistingAccount(updateCapabilies: true)
                    self.accountLoaded = true
                }
            } else {
                self.accountLoaded = true
            }
        }
        .onChange(of: continueToNextStep) { oldValue, newValue in
            guard continueToNextStep else { return }
            guard onboardingContainerViewModel.onboardingFlow.last != onboardingContainerViewModel.currentStep else {
                onComplete?()
                self.dismiss()
                return
            } // Complete onboarding here.
            
            let index: Int = (onboardingContainerViewModel.onboardingFlow.firstIndex(of: onboardingContainerViewModel.currentStep) ?? 0) + 1
            onboardingContainerViewModel.currentStep = onboardingContainerViewModel.onboardingFlow[index]
            self.continueToNextStep = false
        }
        .onChange(of: returnToPreviousStep, { oldValue, newValue in
            guard returnToPreviousStep else { return }
            guard onboardingContainerViewModel.onboardingFlow.first != onboardingContainerViewModel.currentStep else {
                self.startedOnboarding = false
                self.returnToPreviousStep = false
                return
            }
            
            let index: Int = (onboardingContainerViewModel.onboardingFlow.firstIndex(of: onboardingContainerViewModel.currentStep) ?? 0) - 1
            onboardingContainerViewModel.currentStep = onboardingContainerViewModel.onboardingFlow[index]
            self.returnToPreviousStep = false
        })
        .onChange(of: onboardingContainerViewModel.currentStep) {
            let index: Int = (onboardingContainerViewModel.onboardingFlow.firstIndex(of: onboardingContainerViewModel.currentStep) ?? 0) + 1
            onboardingContainerViewModel.progressiveSteps = Array(onboardingContainerViewModel.onboardingFlow[0..<index])
        }
    }
    
    var containerHeader: some View {
        Rectangle()
            .fill(FrameColors.onboardingHeaderBackground)
            .overlay {
                VStack {
                    Spacer()
                    HStack {
                        ForEach(onboardingContainerViewModel.onboardingFlow) { step in
                            Capsule()
                                .fill(progressIndicatorColor(filled: onboardingContainerViewModel.progressiveSteps.contains(step)))
                                .frame(height: 5.0)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 15.0)
                    .padding(.horizontal)
                    Divider()
                }
            }
            .frame(height: 100.0)
    }

    private func progressIndicatorColor(filled: Bool) -> Color {
        switch (colorScheme, filled) {
        case (.dark, true):  return FrameColors.onboardingProgressFilledOnBrand
        case (.dark, false): return FrameColors.onboardingProgressEmptyOnBrand
        case (_, true):      return FrameColors.mainButtonColor
        case (_, false):     return FrameColors.surfaceStrokeColor
        }
    }
    
    var onboardingIntro: some View {
        VStack(spacing: 15.0) {
            Spacer()
            Image("shield-icon", bundle: FrameResources.module)
            Text("Verify Your Identity")
                .font(.system(size: 18.0))
                .fontWeight(.semibold)
            Text("We’re required by law to verify your identity. This takes about 2 minutes and you’ll need a Government ID and a selfie.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14.0))
                .foregroundColor(FrameColors.secondaryTextColor)
                .padding(.horizontal, 24.0)
            Spacer()
            ContinueButton(enabled: $accountLoaded) {
                self.startedOnboarding = true
            }
            .padding(.bottom)
        }
    }
}

#Preview {
    OnboardingContainerView(requiredCapabilities: [.kycPrefill, .cardVerification, .geoCompliance, .bankAccountVerification, .ageVerification])
}
