//
//  ValidatedTextField.swift
//  Frame-iOS
//

import SwiftUI

struct ValidatedTextField: View {
    let prompt: String
    @Binding var text: String
    @Binding var error: String?
    var keyboardType: UIKeyboardType = .default
    var characterLimit: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("", text: $text, prompt: Text(prompt))
                .keyboardType(keyboardType)
                .frame(height: 49.0)
                .padding(.horizontal)
                .onChange(of: text) { newValue in
                    if let limit = characterLimit, newValue.count > limit {
                        text = String(newValue.prefix(limit))
                    }
                    if error != nil { error = nil }
                }
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }
        }
    }
}
