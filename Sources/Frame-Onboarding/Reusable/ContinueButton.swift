//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 12/11/25.
//

import SwiftUI
import Frame_iOS

// Reusable colors
let secondaryTextColor = Color("TextColorSecondary", bundle: FrameResources.module)
let mainButtonColor = Color("MainButtonColor", bundle: FrameResources.module)

struct ContinueButton: View {
    @State var buttonColor: Color = mainButtonColor
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
                    if !enabled {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.0)
                    }
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
