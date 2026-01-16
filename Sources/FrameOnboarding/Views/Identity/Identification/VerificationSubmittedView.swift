//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/12/25.
//

import SwiftUI
import Frame

struct VerificationSubmittedView: View {
    @Binding var continueToNextStep: Bool
    
    var body: some View {
        VStack(spacing: 10.0) {
            Spacer()
            Image("person-check", bundle: FrameResources.module)
            Text("Verification Submitted")
                .font(.system(size: 18.0))
                .fontWeight(.semibold)
            Text("Congratulations! You’ve submitted your identity verification check. You’re ready to proceed.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14.0))
                .foregroundColor(secondaryTextColor)
                .padding(.horizontal, 24.0)
            Spacer()
            ContinueButton(buttonText: "Done", enabled: .constant(true)) {
                self.continueToNextStep = true
            }
            .padding(.bottom)
        }
    }
}

#Preview {
    VerificationSubmittedView(continueToNextStep: .constant(false))
}
