//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI

/// A reusable single-line text field for payment-related forms in the onboarding flow.
///
/// Wraps a SwiftUI `TextField` with a fixed row height, optional bottom divider,
/// configurable keyboard type, and an optional character-count cap.
public struct ReusableFormTextField: View {
    /// The placeholder text displayed inside the field when it is empty.
    @State public var prompt: String
    /// The current text value entered by the user.
    @Binding public var text: String
    /// Whether a `Divider` is rendered below the text field.
    @State public var showDivider: Bool
    /// The keyboard type presented when the field becomes first responder.
    @State public var keyboardType: UIKeyboardType = .default
    /// Maximum number of characters allowed; `0` means no limit.
    @State public var characterLimit: Int = 0

    /// Creates a `ReusableFormTextField`.
    ///
    /// - Parameters:
    ///   - prompt: Placeholder text shown inside the field.
    ///   - text: Binding to the string value managed by the parent view.
    ///   - showDivider: Pass `true` to display a `Divider` beneath the field.
    ///   - keyboardType: The keyboard style to present; defaults to `.default`.
    ///   - characterLimit: Maximum character count; pass `0` (default) for no limit.

    public var body: some View {
        TextField("", text: $text, prompt: Text(prompt))
            .frame(height: 49.0)
            .keyboardType(keyboardType)
            .padding(.horizontal)
            .onChange(of: text) { newValue in
                if characterLimit > 0, newValue.count > characterLimit {
                    text = String(newValue.prefix(characterLimit))
                }
            }
        if showDivider {
            Divider()
        }
    }
}

#Preview {
    VStack {
        ReusableFormTextField(prompt: "Example prompt", text: .constant(""), showDivider: true, keyboardType: . numberPad)
        ReusableFormTextField(prompt: "Example prompt 2", text: .constant(""), showDivider: false, keyboardType: . numberPad)
    }
}
