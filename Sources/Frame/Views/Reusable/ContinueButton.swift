//
//  ContinueButton.swift
//  Frame-iOS
//
//  Primary action button shared by both Frame (checkout) and FrameOnboarding.
//  Drives the in-button loading spinner from `isLoading` and form-validity gating
//  from `enabled`. Both default to permissive values so most callers can omit them.
//
//  Colors and corner radius come from the injected FrameTheme. Pick `.secondary`
//  for inverse-styled buttons (e.g. neutral background, brand-colored text).
//

import SwiftUI

public struct ContinueButton: View {
    public enum Style {
        case primary
        case secondary
    }

    @Environment(\.frameTheme) private var theme

    @State public var buttonText: String = "Continue"
    @State public var style: Style = .primary

    @Binding public var enabled: Bool
    @Binding public var isLoading: Bool

    public var buttonAction: () -> ()

    public init(buttonText: String = "Continue",
                style: Style = .primary,
                enabled: Binding<Bool> = .constant(true),
                isLoading: Binding<Bool> = .constant(false),
                buttonAction: @escaping () -> ()) {
        self._buttonText = State(initialValue: buttonText)
        self._style = State(initialValue: style)
        self._enabled = enabled
        self._isLoading = isLoading
        self.buttonAction = buttonAction
    }

    private var fillColor: Color {
        switch style {
        case .primary:   return theme.colors.primaryButton
        case .secondary: return theme.colors.secondaryButton
        }
    }

    private var textColor: Color {
        switch style {
        case .primary:   return theme.colors.primaryButtonText
        case .secondary: return theme.colors.secondaryButtonText
        }
    }

    public var body: some View {
        Button {
            guard !isLoading else { return }
            buttonAction()
        } label: {
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .fill(enabled ? fillColor : theme.colors.disabledButton)
                .overlay {
                    if !enabled && !isLoading {
                        RoundedRectangle(cornerRadius: theme.radii.medium)
                            .stroke(theme.colors.disabledButtonStroke, lineWidth: 1.0)
                    }
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(textColor)
                    } else {
                        Text(buttonText)
                            .font(theme.fonts.button)
                            .bold()
                            .foregroundColor(enabled ? textColor : theme.colors.disabledButtonText)
                    }
                }
        }
        .disabled(!enabled || isLoading)
        .frame(height: 50.0)
        .padding()
    }
}

#Preview {
    Group {
        ContinueButton(buttonAction: {})
        ContinueButton(style: .secondary, buttonAction: {})
        ContinueButton(enabled: .constant(false), buttonAction: {})
        ContinueButton(isLoading: .constant(true), buttonAction: {})
    }
}
