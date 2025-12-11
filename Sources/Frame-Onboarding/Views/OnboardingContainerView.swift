//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 11/24/25.
//

import SwiftUI

enum OnboardingFlow: Int, CaseIterable {
    case selectPaymentMethod = 1
    case confirmPaymentMethod = 2
    case userVerification = 3
}

struct SwiftUIView: View {
    @State private var onboardingFlow: OnboardingFlow = .selectPaymentMethod
    
    let customerId: String
    
    var body: some View {
        VStack {
            containerHeader
                .padding(.bottom)
            
            switch onboardingFlow {
            case .selectPaymentMethod:
                SelectPaymentMethodView(customerId: customerId)
            case .confirmPaymentMethod:
                SecurePMVerificationView()
            case .userVerification:
                UserIdentificationView()
            }
            
            Spacer()
        }.ignoresSafeArea()
    }
    
    var containerHeader: some View {
        VStack {
            Rectangle().fill(Color.init(hex: "#325054"))
                .overlay {
                    VStack {
                        Spacer()
                        Text("Step \(onboardingFlow.rawValue) of \(OnboardingFlow.allCases.count)")
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                    }
                }
        }
        .frame(height: 100.0)
    }
}

#Preview {
    SwiftUIView(customerId: "cust_123")
}
