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

    case selectPaymentMethod = 1
    case confirmPaymentMethod = 2
    case userVerification = 3
    case onboardingComplete = 4
}

struct SwiftUIView: View {
    @State private var currentStep: OnboardingFlow = .selectPaymentMethod
    @State private var onboardingFlow: [OnboardingFlow] = [.selectPaymentMethod, .confirmPaymentMethod, .userVerification, .onboardingComplete]
    @State private var progressiveSteps: [OnboardingFlow] = [.selectPaymentMethod]
    
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
            case .selectPaymentMethod:
                SelectPaymentMethodView(customerId: customerId)
            case .confirmPaymentMethod:
                SecurePMVerificationView()
            case .userVerification:
                UserIdentificationView()
            case .onboardingComplete:
                UserIdentificationView()
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
    SwiftUIView(customerId: "cust_123")
}
