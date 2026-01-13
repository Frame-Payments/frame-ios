//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 1/9/26.
//

import SwiftUI

public struct ReusableFormTextField: View {
    @State var prompt: String
    @Binding var text: String
    @State var showDivider: Bool
    @State var keyboardType: UIKeyboardType = .default
    @State var characterLimit: Int = 0
    
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
    ReusableFormTextField(prompt: "Example prompt", text: .constant(""), showDivider: true, keyboardType: . numberPad)
}
