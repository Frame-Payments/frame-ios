//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/17/26.
//

import SwiftUI
import Frame

public struct TermsOfServiceView: View {
    @Environment(\.frameTheme) private var theme

    // Public configurable URLs (default to placeholders if not provided)
    @State private var privacyPolicyURL: URL = URL(string: "https://framepayments.com/privacy")!
    @State private var termsOfServiceURL: URL = URL(string: "https://framepayments.com/terms")!

    public var alignment: Alignment = .center
    public var padded: Bool = false

    private var composed: AttributedString {
        let linkFont = theme.fonts.caption.bold()
        let linkColor = UIColor(theme.colors.primaryButton)

        var result = AttributedString("By clicking continue, you agree to the terms of Frame's ")
        // Append Privacy Policy link
        var privacy = AttributedString("Privacy Policy")
        privacy.link = privacyPolicyURL
        privacy.font = linkFont
        privacy.foregroundColor = linkColor
        result.append(privacy)

        // Append connector text
        let andText = AttributedString(" and ")
        result.append(andText)

        // Append Terms of Service link
        var terms = AttributedString("Terms of Service")
        terms.link = termsOfServiceURL
        terms.font = linkFont
        terms.foregroundColor = linkColor
        result.append(terms)
        result.append(AttributedString("."))
        return result
    }

    public var body: some View {
        let textView = Text(composed)
            .font(theme.fonts.caption)
            .foregroundStyle(theme.colors.textSecondary)
            .multilineTextAlignment(alignment == .leading ? .leading : alignment == .trailing ? .trailing : .center)

        Group {
            if padded {
                textView
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: alignment)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                            .fill(theme.colors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                            .stroke(theme.colors.surfaceStroke, lineWidth: 1)
                    )
            } else {
                textView
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
        .accessibilityLabel("By clicking continue, you agree to the terms of Frame's Privacy Policy and Terms of Service.")
    }
}

#Preview {
    VStack(spacing: 16) {
        TermsOfServiceView(
            padded: true
        )
        .padding(.horizontal)

        TermsOfServiceView(
            alignment: .leading, padded: false
        )
        .padding(.horizontal)
    }
}

#Preview("Dark") {
    VStack(spacing: 16) {
        TermsOfServiceView(padded: true).padding(.horizontal)
        TermsOfServiceView(alignment: .leading, padded: false).padding(.horizontal)
    }
    .preferredColorScheme(.dark)
}
