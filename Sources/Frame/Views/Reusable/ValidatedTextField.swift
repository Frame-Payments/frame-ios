//
//  ValidatedTextField.swift
//  Frame-iOS
//

import SwiftUI

public struct ValidatedTextField: View {
    private let prompt: String
    @Binding var text: String
    @Binding var error: String?
    
    private var keyboardType: UIKeyboardType
    private var characterLimit: Int?
    private var compactError: Bool
    private var errorSpacing: CGFloat

    public init(prompt: String,
                text: Binding<String>,
                error: Binding<String?>,
                keyboardType: UIKeyboardType = .default,
                characterLimit: Int? = nil,
                compactError: Bool = false,
                errorSpacing: CGFloat = 4) {
        self.prompt = prompt
        self._text = text
        self._error = error
        self.keyboardType = keyboardType
        self.characterLimit = characterLimit
        self.compactError = compactError
        self.errorSpacing = errorSpacing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: compactError ? 0 : errorSpacing) {
            TextField("", text: $text, prompt: Text(prompt))
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
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.bottom, errorSpacing)
            }
        }
    }
}
