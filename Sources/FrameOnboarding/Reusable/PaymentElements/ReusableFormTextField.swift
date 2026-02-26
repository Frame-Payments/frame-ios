//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI

public struct ReusableFormTextField: View {
    @State public var prompt: String
    @Binding public var text: String
    @State public var showDivider: Bool
    @State public var keyboardType: UIKeyboardType = .default
    @State public var characterLimit: Int = 0
    
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
