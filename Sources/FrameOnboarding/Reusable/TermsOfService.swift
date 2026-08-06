//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/17/26.
//

import SwiftUI
import Frame

/// A SwiftUI view that renders a Frame terms-of-service consent line with tappable
/// Privacy Policy and Terms of Service hyperlinks, styled using the active ``FrameTheme``.
///
/// Embed this view below any primary action button to inform users that proceeding
/// implies acceptance of Frame's legal agreements.
public struct TermsOfServiceView: View {
    @Environment(\.frameTheme) private var theme

    /// The horizontal alignment applied to the consent text and its containing frame.
    public var alignment: Alignment = .center
    /// When `true`, the view is wrapped in a rounded-rectangle surface with a stroke border.
    public var padded: Bool = false

    private var composed: AttributedString {
        let linkFont = theme.fonts.caption.bold()
        let linkColor = UIColor(theme.colors.primaryButton)

        var result = AttributedString("By clicking continue, you agree to the terms of Frame's ")
        var privacy = AttributedString("Privacy Policy")
        privacy.link = LegalConfiguration.privacyURL
        privacy.font = linkFont
        privacy.foregroundColor = linkColor
        result.append(privacy)

        result.append(AttributedString(" and "))

        var terms = AttributedString("Terms of Service")
        terms.link = LegalConfiguration.termsURL
        terms.font = linkFont
        terms.foregroundColor = linkColor
        result.append(terms)
        result.append(AttributedString("."))
        return result
    }

    /// Creates a ``TermsOfServiceView``.
    ///
    /// - Parameters:
    ///   - alignment: Horizontal alignment for the consent text. Defaults to `.center`.
    ///   - padded: When `true`, wraps the text in a themed rounded-rectangle surface. Defaults to `false`.
    public init(alignment: Alignment = .center, padded: Bool = false) {
        self.alignment = alignment
        self.padded = padded
    }

    /// The view hierarchy that renders the attributed consent text.
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
