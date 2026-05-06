//
//  PhoneNumberTextField.swift
//  Frame-iOS
//

import SwiftUI
import PhoneNumberKit

public struct PhoneNumberTextField: View {
    @Environment(\.frameTheme) private var theme

    let prompt: String
    @Binding var text: String
    @Binding var error: String?
    var regionCode: String
    var compactError: Bool = false

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

    public var body: some View {
        VStack(alignment: .leading, spacing: compactError ? 0 : 4) {
            TextField("", text: $text, prompt: Text(prompt))
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

    private func apply(formatted newValue: String) {
        let reformatted = Self.formatter(for: regionCode).formatPartial(newValue)
        if reformatted != text {
            text = reformatted
        }
    }

    /// PartialFormatter is reasonably cheap to construct but we cache per-region to avoid
    /// rebuilding on every keystroke. Driven by the `regionCode` parameter so there is no
    /// stored state that can lag behind the parent's selection.
    private static let formatterCache = NSCache<NSString, PartialFormatter>()

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
