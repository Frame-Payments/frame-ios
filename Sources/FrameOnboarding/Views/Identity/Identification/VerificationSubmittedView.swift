//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/12/25.
//

import SwiftUI
import Frame

/// The final screen of the onboarding flow. Renders from the resolved ``OnboardingOutcome``
/// rather than asserting success — only `approved` gets the congratulatory copy.
struct VerificationSubmittedView: View {
    @Environment(\.frameTheme) private var theme
    @Binding var continueToNextStep: Bool

    /// How onboarding ended. `nil` while the outcome is still being resolved.
    var outcome: OnboardingOutcome?

    /// Whether the outcome is still being fetched.
    var isResolving: Bool = false

    var body: some View {
        VStack(spacing: 10.0) {
            Spacer()
            if isResolving {
                ProgressView()
                Text("Checking your verification…")
                    .font(theme.fonts.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.top, 4.0)
            } else {
                Image(iconName, bundle: FrameResources.module)
                Text(title)
                    .font(theme.fonts.heading)
                    .fontWeight(.semibold)
                Text(bodyText)
                    .multilineTextAlignment(.center)
                    .font(theme.fonts.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal, 24.0)
            }
            Spacer()
            ContinueButton(buttonText: buttonText, enabled: .constant(!isResolving)) {
                self.continueToNextStep = true
            }
            .padding(.bottom)
        }
    }

    /// `person-check` only for an approval; every other ending shows the alert mark.
    private var iconName: String {
        switch outcome ?? .pendingReview {
        case .approved: return "person-check"
        case .pendingReview, .declined, .actionRequired: return "person-alert 2"
        }
    }

    private var title: String {
        switch outcome ?? .pendingReview {
        case .approved: return "Verification Submitted"
        case .pendingReview: return "Verification In Review"
        case .declined: return "Verification Unsuccessful"
        case .actionRequired: return "More Information Needed"
        }
    }

    /// Prefers the server-authored message so every Frame surface says the same words.
    private var bodyText: String {
        switch outcome ?? .pendingReview {
        case .approved:
            return "Congratulations! You’ve submitted your identity verification check. You’re ready to proceed."
        case .pendingReview:
            return "We’re reviewing your information. This usually doesn’t take long, and we’ll be in touch once it’s complete."
        case .declined(let message):
            // No retry affordance: a terminal decline cannot be changed by trying again.
            return message ?? "We weren’t able to verify your identity. Please contact support if you think this is a mistake."
        case .actionRequired(let message):
            return message ?? "We need a bit more information from you before we can finish verifying your identity. Please contact support."
        }
    }

    private var buttonText: String {
        outcome?.isSuccess == true ? "Done" : "Close"
    }
}

#Preview("Approved") {
    VerificationSubmittedView(continueToNextStep: .constant(false), outcome: .approved)
}

#Preview("In review") {
    VerificationSubmittedView(continueToNextStep: .constant(false), outcome: .pendingReview)
}

#Preview("Declined") {
    VerificationSubmittedView(continueToNextStep: .constant(false), outcome: .declined(message: nil))
}
