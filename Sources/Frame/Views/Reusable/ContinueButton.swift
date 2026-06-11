//
//  ContinueButton.swift
//  Frame-iOS
//
//  Primary action button shared by both Frame (checkout) and FrameOnboarding.
//  Drives the in-button loading spinner from `isLoading` and form-validity gating
//  from `enabled`. Both default to permissive values so most callers can omit them.
//
//  Colors and corner radius come from the injected FrameTheme. Pick `.secondary`
//  for an outlined, brand-colored button (e.g. inverse of the primary).
//

import SwiftUI

/// A themed primary-action button shared across Frame checkout and FrameOnboarding flows.
///
/// `ContinueButton` renders a rounded-rectangle button whose fill color, text color, and corner
/// radius are driven by the ambient ``FrameTheme``. An in-button ``ProgressView`` replaces the
/// label while ``isLoading`` is `true`, and the button is automatically disabled when either
/// ``enabled`` is `false` or a loading operation is in progress.
public struct ContinueButton: View {
    /// The visual style of the button.
    public enum Style {
        /// A solid, filled button using the theme's primary button colors.
        case primary
        /// An outlined button using the theme's secondary button colors.
        case secondary
    }

    @Environment(\.frameTheme) private var theme

    /// The text label displayed inside the button when not loading.
    public let buttonText: String
    /// The visual style applied to the button.
    public let style: Style

    /// Controls whether the button is interactive. When `false` the button renders in its disabled appearance.
    @Binding public var enabled: Bool
    /// When `true` the button label is replaced with a circular progress indicator and taps are ignored.
    @Binding public var isLoading: Bool

    /// The closure executed when the button is tapped and is not in a loading state.
    public var buttonAction: () -> ()

    /// Creates a `ContinueButton`.
    ///
    /// - Parameters:
    ///   - buttonText: The label shown inside the button. Defaults to `"Continue"`.
    ///   - style: The visual style of the button. Defaults to `.primary`.
    ///   - enabled: A binding that gates interactivity. Defaults to always `true`.
    ///   - isLoading: A binding that shows an in-button spinner when `true`. Defaults to always `false`.
    ///   - buttonAction: The closure invoked on a valid tap.
    public init(buttonText: String = "Continue",
                style: Style = .primary,
                enabled: Binding<Bool> = .constant(true),
                isLoading: Binding<Bool> = .constant(false),
                buttonAction: @escaping () -> ()) {
        self.buttonText = buttonText
        self.style = style
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
                    } else if enabled && style == .secondary {
                        RoundedRectangle(cornerRadius: theme.radii.medium)
                            .stroke(theme.colors.secondaryButtonText, lineWidth: 1.0)
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
