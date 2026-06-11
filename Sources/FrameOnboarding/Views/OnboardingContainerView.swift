//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/24/25.
//

import SwiftUI
import Frame

/// Ordered steps that make up an onboarding flow presented by ``OnboardingContainerView``.
///
/// Each case maps to a distinct screen in the SDK's identity-verification and payment-setup
/// sequence. The flow is built at runtime from the ``FrameObjects/Capabilities`` values
/// supplied to ``OnboardingContainerView/init(accountId:requiredCapabilities:showIntroScreen:showCompletionScreen:onResult:)``.
public enum OnboardingFlow: Int, CaseIterable, Identifiable {
    /// A stable string identifier derived from the case's raw integer value.
    public var id: String {
        return "\(self.rawValue)"
    }

//    case countryVerification
//    case geolocationVerification
//    case uploadDocuments

    /// Collects personal-identification details and handles KYC / phone-verification flows.
    case personalInformation = 0
    /// Prompts the user to add or confirm a card payment method.
    case confirmPaymentMethod = 1
    /// Prompts the user to add or confirm a bank-account payout method.
    case confirmBankAccount = 2
    /// Displays a confirmation screen after all verification steps are submitted.
    case verificationSubmitted = 3
}

extension FrameObjects.Capabilities {
    /// Maps a ``FrameObjects/Capabilities`` value to the ``OnboardingFlow`` step that handles it.
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

/// Root SwiftUI view that orchestrates the Frame SDK's multi-step onboarding experience.
///
/// ``OnboardingContainerView`` accepts a list of required ``FrameObjects/Capabilities``,
/// derives the minimal ordered sequence of ``OnboardingFlow`` steps needed to satisfy them,
/// and presents each step in turn inside a unified chrome with a progress indicator header.
/// When the user completes or cancels the flow the ``onResult`` closure is called with a
/// ``FrameResult``.
public struct OnboardingContainerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.frameTheme) private var theme
    /// The view model that holds mutable onboarding state and drives step transitions.
    @ObservedObject var onboardingContainerViewModel: OnboardingContainerViewModel

    /// Closure invoked with the final ``FrameResult`` when the flow ends.
    var onResult: (FrameResult) -> Void
    /// Whether to show the introductory splash screen before the first onboarding step.
    var showIntroScreen: Bool
    /// Whether to show the ``OnboardingFlow/verificationSubmitted`` completion screen.
    var showCompletionScreen: Bool

    /// Triggers a forward navigation to the next onboarding step when set to `true`.
    @State private var continueToNextStep: Bool = false
    /// Triggers a backward navigation to the previous onboarding step when set to `true`.
    @State private var returnToPreviousStep: Bool = false
    /// Tracks whether the user has moved past the intro screen and into the step sequence.
    @State private var startedOnboarding: Bool = false
    /// Becomes `true` once any pre-existing account data has been fetched and is ready to display.
    @State private var accountLoaded: Bool = false
    /// Guards against emitting a `.cancelled` result on dismiss when the flow already completed.
    @State private var didFinish: Bool = false

    /// Creates an ``OnboardingContainerView`` configured for the given account and capability set.
    ///
    /// - Parameters:
    ///   - accountId: An existing Frame account ID to pre-populate data for, or `nil` to create a new account during onboarding.
    ///   - requiredCapabilities: The set of ``FrameObjects/Capabilities`` the user must satisfy; determines which steps are shown.
    ///   - showIntroScreen: Pass `false` to skip the introductory splash and begin the first step immediately. Defaults to `true`.
    ///   - showCompletionScreen: Pass `false` to omit the ``OnboardingFlow/verificationSubmitted`` confirmation screen. Defaults to `true`.
    ///   - onResult: Closure called with a ``FrameResult`` when the flow finishes or is cancelled.
    public init(accountId: String? = nil,
                requiredCapabilities: [FrameObjects.Capabilities] = [],
                showIntroScreen: Bool = true,
                showCompletionScreen: Bool = true,
                onResult: @escaping (FrameResult) -> Void = { _ in }) {
        self.onResult = onResult
        self.showIntroScreen = showIntroScreen
        self.showCompletionScreen = showCompletionScreen
        self.onboardingContainerViewModel = OnboardingContainerViewModel(accountId: accountId,
                                                                         requiredCapabilities: requiredCapabilities)

        if requiredCapabilities != [] {
            // Map capabilites to onboarding flow steps
            let onboardingSet = Set(requiredCapabilities.map { $0.onboardingStep })
            var onboardingArray = Array(onboardingSet).sorted(by: { $0.rawValue < $1.rawValue })
            if showCompletionScreen {
                onboardingArray.append(.verificationSubmitted)
            }

            onboardingContainerViewModel.progressiveSteps = [onboardingArray.first ?? .personalInformation]
            onboardingContainerViewModel.onboardingFlow = onboardingArray
            onboardingContainerViewModel.currentStep = onboardingArray.first ?? .personalInformation
        } else {
            onboardingContainerViewModel.progressiveSteps = [.personalInformation]
            onboardingContainerViewModel.onboardingFlow = showCompletionScreen
                ? [.personalInformation, .verificationSubmitted]
                : [.personalInformation]
            onboardingContainerViewModel.currentStep = .personalInformation
        }
    }
    
    /// The root view hierarchy: intro splash or the active step screen wrapped in a progress header.
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
            if !showIntroScreen {
                self.startedOnboarding = true
            }
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
                // Mark finished BEFORE dismiss so the cancel guard in .onDisappear doesn't fire.
                // The selected PaymentMethod id (if any) is what callers care about — Apple Pay
                // / card / ACH all converge here. Emit empty string for the "completed without
                // a method selection" path (rare; covers flows where onboarding only verifies
                // identity rather than collecting a payment method).
                didFinish = true
                onResult(.completed(id: onboardingContainerViewModel.selectedPaymentMethod?.id ?? ""))
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
        .frameToastOverlay()
        .onDisappear {
            if !didFinish {
                didFinish = true
                onResult(.cancelled)
            }
        }
    }
    
    /// A fixed-height header bar containing a segmented progress indicator for the onboarding steps.
    var containerHeader: some View {
        Rectangle()
            .fill(theme.colors.onboardingHeaderBackground)
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

    /// Returns the theme color for a single progress-indicator capsule.
    ///
    /// - Parameter filled: `true` if the step represented by the capsule has been reached or completed.
    /// - Returns: The appropriate ``FrameTheme`` color for the current color scheme and fill state.
    private func progressIndicatorColor(filled: Bool) -> Color {
        switch (colorScheme, filled) {
        case (.dark, true):  return theme.colors.onboardingProgressFilledOnBrand
        case (.dark, false): return theme.colors.onboardingProgressEmptyOnBrand
        case (_, true):      return theme.colors.primaryButton
        case (_, false):     return theme.colors.surfaceStroke
        }
    }

    /// The introductory splash screen shown before the first onboarding step when ``showIntroScreen`` is `true`.
    var onboardingIntro: some View {
        VStack(spacing: 15.0) {
            Spacer()
            Image("shield-icon", bundle: FrameResources.module)
            Text("Verify Your Identity")
                .font(theme.fonts.heading)
                .fontWeight(.semibold)
            Text("We’re required by law to verify your identity. This takes about 2 minutes and you’ll need a Government ID and a selfie.")
                .multilineTextAlignment(.center)
                .font(theme.fonts.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
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
