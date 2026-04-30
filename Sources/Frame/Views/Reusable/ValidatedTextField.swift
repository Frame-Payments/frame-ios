//
//  ValidatedTextField.swift
//  Frame-iOS
//

import SwiftUI

public struct ValidatedTextField: View {
    let prompt: String
    @Binding var text: String
    @Binding var error: String?
    var keyboardType: UIKeyboardType = .default
    var characterLimit: Int? = nil
    var compactError: Bool = false

    public init(prompt: String,
                text: Binding<String>,
                error: Binding<String?>,
                keyboardType: UIKeyboardType = .default,
                characterLimit: Int? = nil,
                compactError: Bool = false) {
        self.prompt = prompt
        self._text = text
        self._error = error
        self.keyboardType = keyboardType
        self.characterLimit = characterLimit
        self.compactError = compactError
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: compactError ? 0 : 4) {
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
                    .padding(.bottom, 4)
            }
        }
    }
}
