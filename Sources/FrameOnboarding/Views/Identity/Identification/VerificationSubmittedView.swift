//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/12/25.
//

import SwiftUI
import Frame

struct VerificationSubmittedView: View {
    @Environment(\.frameTheme) private var theme
    @Binding var continueToNextStep: Bool

    var body: some View {
        VStack(spacing: 10.0) {
            Spacer()
            Image("person-check", bundle: FrameResources.module)
            Text("Verification Submitted")
                .font(theme.fonts.heading)
                .fontWeight(.semibold)
            Text("Congratulations! You’ve submitted your identity verification check. You’re ready to proceed.")
                .multilineTextAlignment(.center)
                .font(theme.fonts.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
                .padding(.horizontal, 24.0)
            Spacer()
            ContinueButton(buttonText: "Done") {
                self.continueToNextStep = true
            }
            .padding(.bottom)
        }
    }
}

#Preview {
    VerificationSubmittedView(continueToNextStep: .constant(false))
}
