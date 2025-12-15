//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 12/11/25.
//

import SwiftUI

struct ContinueButton: View {
    @State var buttonColor: Color = Color(hex: "2B4146")
    @State var buttonText: String = "Continue"
    @Binding var enabled: Bool
    var buttonAction: () -> ()
    
    var body: some View {
        Button {
            buttonAction()
        } label: {
            RoundedRectangle(cornerRadius: 10.0)
                .fill(enabled ? buttonColor : .gray.opacity(0.1))
                .overlay {
                    Text(buttonText)
                        .bold()
                        .foregroundColor(enabled ? .white : .gray)
                }
        }
        .disabled(!enabled)
        .frame(height: 50.0)
        .padding()
    }
}

#Preview {
    Group {
        ContinueButton(enabled: .constant(true), buttonAction: {})
        ContinueButton(enabled: .constant(false), buttonAction: {})
    }
}
