//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 11/24/25.
//

import SwiftUI
import Frame_iOS

enum OnboardingFlow: Int, CaseIterable, Identifiable {
    var id: String {
        return "\(self.rawValue)"
    }

    case confirmPaymentMethod = 1
    case countryVerification = 2
    case uploadDocuments = 3
    case onboardingComplete = 4
}

struct OnboardingContainerView: View {
    @State private var currentStep: OnboardingFlow = .confirmPaymentMethod
    @State private var onboardingFlow: [OnboardingFlow] = [.confirmPaymentMethod, .countryVerification, .uploadDocuments, .onboardingComplete]
    @State private var progressiveSteps: [OnboardingFlow] = [.confirmPaymentMethod]
    
    let customerId: String
    
    init(customerId: String, customOnboardingFlow: [OnboardingFlow]? = nil) {
        self.customerId = customerId
        
        if let customOnboardingFlow, let first = customOnboardingFlow.first {
            self.onboardingFlow = customOnboardingFlow
            self.progressiveSteps = [first]
        }
    }
    
    var body: some View {
        VStack {
            containerHeader
            switch currentStep {
            case .confirmPaymentMethod:
                SelectPaymentMethodView(customerId: customerId)
            case .countryVerification:
                UserIdentificationView()
            case .uploadDocuments:
                UploadPhotosView()
            case .onboardingComplete:
                VerificationSubmittedView()
            }
            Spacer()
        }
        .ignoresSafeArea()
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
