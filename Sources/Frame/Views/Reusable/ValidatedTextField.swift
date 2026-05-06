//
//  ValidatedTextField.swift
//  Frame-iOS
//

import SwiftUI

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
