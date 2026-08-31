//
//  ValidatedTextField.swift
//  Frame-iOS
//

import SwiftUI

/// Which characters a field accepts, for inputs where a whole class of input is never valid.
///
/// A client-side affordance, not validation: it stops obviously-wrong input before submit, and the
/// API stays the authority on what it accepts.
public enum TextFieldInputRestriction {
    /// Everything is accepted.
    case none

    /// Letters, plus the punctuation that real names and place names contain — `O'Fallon`,
    /// `Stoke-on-Trent`, `St. Louis`, `Jr.`
    ///
    /// "Letter" is any Unicode letter, so `José`, `Müller` and `李` pass. Names here are compared
    /// against a government ID during KYC, so silently dropping a character an applicant's legal
    /// name actually contains would cause a verification failure.
    case textOnly

    /// Whether this restriction admits `character`.
    func allows(_ character: Character) -> Bool {
        switch self {
        case .none:
            return true
        case .textOnly:
            return character.isLetter || character.isWhitespace || "-'.".contains(character)
        }
    }

    /// `text` with every disallowed character removed.
    func filter(_ text: String) -> String {
        switch self {
        case .none:
            return text
        case .textOnly:
            return String(text.filter { allows($0) })
        }
    }
}

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
    private var textContentType: UITextContentType?
    private var characterLimit: Int?
    private var inputRestriction: TextFieldInputRestriction
    private var compactError: Bool
    private var errorSpacing: CGFloat
    private var inlineError: Bool
    private var focused: FocusState<Bool>.Binding?

    /// Creates a new `ValidatedTextField`.
    ///
    /// - Parameters:
    ///   - prompt: Placeholder text shown inside the field when it is empty.
    ///   - text: Two-way binding to the current field value.
    ///   - error: Two-way binding to an optional validation error message; the field clears this automatically when the user types.
    ///   - keyboardType: The keyboard style to present. Defaults to `.default`.
    ///   - textContentType: Semantic hint used by the system to offer QuickType/Contacts autofill (e.g. `.postalCode`). Pass `nil` to disable.
    ///   - characterLimit: Maximum number of characters allowed. Input beyond this limit is silently truncated. Pass `nil` for no limit.
    ///   - inputRestriction: Which characters the field accepts. Disallowed characters are stripped
    ///     as they arrive, from typing, paste and autofill alike. Defaults to `.none`.
    ///   - compactError: When `true`, the error label is suppressed and no extra vertical space is reserved for it.
    ///   - inlineError: When `true`, the error label is placed to the right of the field in a horizontal stack rather than below it.
    ///   - errorSpacing: Points of spacing between the field and the error label (or between elements in compact/inline layouts). Defaults to `4`.
    ///   - focused: Optional binding to the owner's focus state, so a caller that draws something
    ///     alongside the field — an autocomplete list, for instance — can tell when it is being
    ///     edited. Pass `nil` when focus does not matter.
    public init(prompt: String,
                text: Binding<String>,
                error: Binding<String?>,
                keyboardType: UIKeyboardType = .default,
                textContentType: UITextContentType? = nil,
                characterLimit: Int? = nil,
                inputRestriction: TextFieldInputRestriction = .none,
                compactError: Bool = false,
                inlineError: Bool = false,
                errorSpacing: CGFloat = 4,
                focused: FocusState<Bool>.Binding? = nil) {
        self.prompt = prompt
        self._text = text
        self._error = error
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.characterLimit = characterLimit
        self.inputRestriction = inputRestriction
        self.compactError = compactError
        self.inlineError = inlineError
        self.errorSpacing = errorSpacing
        self.focused = focused
    }

    /// The view hierarchy that renders the text field and its optional validation error label.
    public var body: some View {
        VStack(alignment: .leading, spacing: compactError ? 0 : errorSpacing) {
            if inlineError {
                HStack(spacing: errorSpacing) {
                    TextField("", text: $text, prompt: Text(prompt))
                        .font(theme.fonts.body)
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                        .frame(height: 49.0)
                        .padding(.horizontal)
                        .onChange(of: text) { _, newValue in
                            applyInputRules(to: newValue)
                            if error != nil { error = nil }
                        }
                        .modifier(OptionalFocusModifier(focused: focused))
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
                    .textContentType(textContentType)
                    .frame(height: 49.0)
                    .padding(.horizontal)
                    .onChange(of: text) { _, newValue in
                        applyInputRules(to: newValue)
                        if error != nil { error = nil }
                    }
                    .modifier(OptionalFocusModifier(focused: focused))
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

    /// Strips disallowed characters, then truncates — in that order, so filtering can't pull a
    /// character in from beyond the limit. Writes back only on a change, since assigning `text`
    /// unconditionally would re-enter `.onChange`.
    private func applyInputRules(to newValue: String) {
        var updated = inputRestriction.filter(newValue)
        if let limit = characterLimit, updated.count > limit {
            updated = String(updated.prefix(limit))
        }
        if updated != newValue { text = updated }
    }
}

/// Applies `.focused()` only when the caller supplied a binding.
///
/// `.focused()` takes a non-optional binding, so the choice cannot be made inside a view builder
/// without giving the field a different type in each branch.
private struct OptionalFocusModifier: ViewModifier {
    let focused: FocusState<Bool>.Binding?

    func body(content: Content) -> some View {
        if let focused {
            content.focused(focused)
        } else {
            content
        }
    }
}
