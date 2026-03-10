//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/11/25.
//

import SwiftUI

public struct ContinueButton: View {
    @State public var buttonColor: Color = FrameColors.mainButtonColor
    @State public var buttonText: String = "Continue"
    @State public var buttonTextColor: Color = .white
    
    @Binding public var enabled: Bool
    
    public var buttonAction: () -> ()
    
    public var body: some View {
        Button {
            buttonAction()
        } label: {
            RoundedRectangle(cornerRadius: 10.0)
                .fill(enabled ? buttonColor : FrameColors.unfilledButtonColor)
                .overlay {
                    if !enabled {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(FrameColors.unfilledButtonStrokeColor, lineWidth: 1.0)
                    }
                    Text(buttonText)
                        .bold()
                        .foregroundColor(enabled ? buttonTextColor : FrameColors.unfilledButtonTextColor)
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
