//
//  PhoneNumberTextField.swift
//  Frame-iOS
//

import SwiftUI
import PhoneNumberKit

/// A SwiftUI text field that formats phone numbers in real time using ``PhoneNumberKit``.
///
/// The field applies partial formatting as the user types, driven by the supplied
/// `regionCode`.  Validation errors are displayed beneath the field unless
/// `compactError` is `true`, in which case error text is suppressed so the
/// caller can display it elsewhere.
public struct PhoneNumberTextField: View {
    @Environment(\.frameTheme) private var theme

    let prompt: String
    @Binding var text: String
    @Binding var error: String?
    var regionCode: String
    var compactError: Bool = false

    /// Creates a phone-number text field.
    ///
    /// - Parameters:
    ///   - prompt: Placeholder text shown when the field is empty.
    ///   - text: Binding to the formatted phone-number string.
    ///   - error: Binding to an optional validation error message.  Set to a
    ///     non-nil value to display an error below the field; the field clears
    ///     this automatically when the user edits the text.
    ///   - regionCode: ISO 3166-1 alpha-2 region code used to select the
    ///     appropriate dialling prefix and formatting rules (e.g. `"US"`, `"GB"`).
    ///   - compactError: When `true`, the error label is hidden and the field
    ///     occupies less vertical space.  Defaults to `false`.
    public init(prompt: String,
                text: Binding<String>,
                error: Binding<String?>,
                regionCode: String,
                compactError: Bool = false) {
        self.prompt = prompt
        self._text = text
        self._error = error
        self.regionCode = regionCode
        self.compactError = compactError
    }

    /// The formatted text field together with its optional inline error label.
    public var body: some View {
        VStack(alignment: .leading, spacing: compactError ? 0 : 4) {
            TextField("", text: $text, prompt: Text(prompt))
                .font(theme.fonts.body)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .frame(height: 49.0)
                .padding(.horizontal)
                .onChange(of: text) { _, newValue in
                    apply(formatted: newValue)
                    if error != nil { error = nil }
                }
                .onChange(of: regionCode) { _, _ in
                    apply(formatted: text)
                }
            if let error, !compactError {
                Text(error)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.error)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }
        }
    }

    /// Reformats `newValue` through the region-specific ``PartialFormatter`` and writes the result back to `text` only when it differs, preventing recursive `onChange` cycles.
    private func apply(formatted newValue: String) {
        let reformatted = Self.formatter(for: regionCode).formatPartial(newValue)
        if reformatted != text {
            text = reformatted
        }
    }

    /// Per-region cache of ``PartialFormatter`` instances; avoids rebuilding on every keystroke while remaining consistent with the current `regionCode`.
    private static let formatterCache = NSCache<NSString, PartialFormatter>()

    /// Returns a cached ``PartialFormatter`` for `region`, creating and caching one on first access.
    ///
    /// - Parameter region: ISO 3166-1 alpha-2 region code.
    /// - Returns: A ``PartialFormatter`` configured for the given region without a dialling prefix.
    private static func formatter(for region: String) -> PartialFormatter {
        let key = region as NSString
        if let cached = formatterCache.object(forKey: key) {
            return cached
        }
        let new = PartialFormatter(defaultRegion: region, withPrefix: false)
        formatterCache.setObject(new, forKey: key)
        return new
    }
}
