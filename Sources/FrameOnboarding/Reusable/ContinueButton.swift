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
    @Binding public var isLoading: Bool

    public var buttonAction: () -> ()

    public init(buttonColor: Color = FrameColors.mainButtonColor,
                buttonText: String = "Continue",
                buttonTextColor: Color = .white,
                enabled: Binding<Bool>,
                isLoading: Binding<Bool> = .constant(false),
                buttonAction: @escaping () -> ()) {
        self._buttonColor = State(initialValue: buttonColor)
        self._buttonText = State(initialValue: buttonText)
        self._buttonTextColor = State(initialValue: buttonTextColor)
        self._enabled = enabled
        self._isLoading = isLoading
        self.buttonAction = buttonAction
    }

    public var body: some View {
        Button {
            guard !isLoading else { return }
            buttonAction()
        } label: {
            RoundedRectangle(cornerRadius: 10.0)
                .fill(enabled ? buttonColor : FrameColors.unfilledButtonColor)
                .overlay {
                    if !enabled && !isLoading {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(FrameColors.unfilledButtonStrokeColor, lineWidth: 1.0)
                    }
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(buttonTextColor)
                    } else {
                        Text(buttonText)
                            .bold()
                            .foregroundColor(enabled ? buttonTextColor : FrameColors.unfilledButtonTextColor)
                    }
                }
        }
        .disabled(!enabled || isLoading)
        .frame(height: 50.0)
        .padding()
    }
}

#Preview {
    Group {
        ContinueButton(enabled: .constant(true), buttonAction: {})
        ContinueButton(enabled: .constant(false), buttonAction: {})
        ContinueButton(enabled: .constant(true), isLoading: .constant(true), buttonAction: {})
    }
}
