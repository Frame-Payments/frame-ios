//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/17/26.
//

import SwiftUI

public struct TermsOfServiceView: View {
    // Public configurable URLs (default to placeholders if not provided)
    @State private var privacyPolicyURL: URL = URL(string: "https://framepayments.com/privacy")!
    @State private var termsOfServiceURL: URL = URL(string: "https://framepayments.com/terms")!

    // Style configuration
    public var font: Font = .system(size: 13)
    public var textColor: Color = .secondary
    public var linkColor: Color = FrameColors.mainButtonColor
    public var alignment: Alignment = .center
    public var padded: Bool = false

    private var composed: AttributedString {
        var result = AttributedString("By clicking continue, you agree to the terms of Frame's ")
        // Append Privacy Policy link
        var privacy = AttributedString("Privacy Policy")
        privacy.link = privacyPolicyURL
        privacy.font = .system(size: 13.0, weight: .bold)
        privacy.foregroundColor = UIColor(linkColor)
        result.append(privacy)
        
        // Append connector text
        var andText = AttributedString(" and ")
        result.append(andText)
        
        // Append Terms of Service link
        var terms = AttributedString("Terms of Service")
        terms.link = termsOfServiceURL
        terms.font = .system(size: 13.0, weight: .bold)
        terms.foregroundColor = UIColor(linkColor)
        result.append(terms)
        result.append(AttributedString("."))
        return result
    }

    public var body: some View {
        let textView = Text(composed)
            .font(font)
            .foregroundStyle(textColor)
            .multilineTextAlignment(alignment == .leading ? .leading : alignment == .trailing ? .trailing : .center)

        Group {
            if padded {
                textView
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: alignment)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
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
