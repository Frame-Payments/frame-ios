//
//  ValidatedTextField.swift
//  Frame-iOS
//

import SwiftUI

/// A reusable SwiftUI text field that displays an inline or stacked validation error message.
///
/// `ValidatedTextField` wraps a standard `TextField` and binds to an optional error string.
/// When the error is non-nil it is shown either beside the field (inline) or below it (stacked).
/// Typing into the field automatically clears the current error and enforces an optional
/// character limit, making it suitable for form inputs throughout the SDK.
public struct ValidatedTextField: View {
    @Environment(\.frameTheme) private var theme

    private let prompt: String
    @Binding var text: String
    @Binding var error: String?

    private var keyboardType: UIKeyboardType
    private var characterLimit: Int?
    private var compactError: Bool
    private var errorSpacing: CGFloat
    private var inlineError: Bool

    /// Creates a new `ValidatedTextField`.
    ///
    /// - Parameters:
    ///   - prompt: Placeholder text shown inside the field when it is empty.
    ///   - text: Two-way binding to the current field value.
    ///   - error: Two-way binding to an optional validation error message; the field clears this automatically when the user types.
    ///   - keyboardType: The keyboard style to present. Defaults to `.default`.
    ///   - characterLimit: Maximum number of characters allowed. Input beyond this limit is silently truncated. Pass `nil` for no limit.
    ///   - compactError: When `true`, the error label is suppressed and no extra vertical space is reserved for it.
    ///   - inlineError: When `true`, the error label is placed to the right of the field in a horizontal stack rather than below it.
    ///   - errorSpacing: Points of spacing between the field and the error label (or between elements in compact/inline layouts). Defaults to `4`.
    public init(prompt: String,
                text: Binding<String>,
                error: Binding<String?>,
                keyboardType: UIKeyboardType = .default,
                characterLimit: Int? = nil,
                compactError: Bool = false,
                inlineError: Bool = false,
                errorSpacing: CGFloat = 4) {
        self.prompt = prompt
        self._text = text
        self._error = error
        self.keyboardType = keyboardType
        self.characterLimit = characterLimit
        self.compactError = compactError
        self.inlineError = inlineError
        self.errorSpacing = errorSpacing
    }

    /// The view hierarchy that renders the text field and its optional validation error label.
    public var body: some View {
        VStack(alignment: .leading, spacing: compactError ? 0 : errorSpacing) {
            if inlineError {
                HStack(spacing: errorSpacing) {
                    TextField("", text: $text, prompt: Text(prompt))
                        .font(theme.fonts.body)
                        .keyboardType(keyboardType)
                        .frame(height: 49.0)
                        .padding(.horizontal)
                        .onChange(of: text) { _, newValue in
                            if let limit = characterLimit, newValue.count > limit {
                                text = String(newValue.prefix(limit))
                            }
                            if error != nil { error = nil }
                        }
                    if let error, !compactError {
                        Text(error)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.colors.error)
                        Spacer()
                    }
                }
            } else {
                TextField("", text: $text, prompt: Text(prompt))
                    .font(theme.fonts.body)
                    .keyboardType(keyboardType)
                    .frame(height: 49.0)
                    .padding(.horizontal)
                    .onChange(of: text) { _, newValue in
                        if let limit = characterLimit, newValue.count > limit {
                            text = String(newValue.prefix(limit))
                        }
                        if error != nil { error = nil }
                    }
                if let error, !compactError {
                    Text(error)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.colors.error)
                        .padding(.horizontal)
                        .padding(.bottom, errorSpacing)
                }
            }
        }
    }
}
