//
//  ContinueButton.swift
//  Frame-iOS
//
//  Primary action button shared by both Frame (checkout) and FrameOnboarding.
//  Drives the in-button loading spinner from `isLoading` and form-validity gating
//  from `enabled`. Both default to permissive values so most callers can omit them.
//

import SwiftUI

public struct ContinueButton: View {
    @State public var buttonColor: Color = FrameColors.mainButtonColor
    @State public var buttonText: String = "Continue"
    @State public var buttonTextColor: Color = FrameColors.brandButtonTextColor

    @Binding public var enabled: Bool
    @Binding public var isLoading: Bool

    public var buttonAction: () -> ()

    public init(buttonColor: Color = FrameColors.mainButtonColor,
                buttonText: String = "Continue",
                buttonTextColor: Color = FrameColors.brandButtonTextColor,
                enabled: Binding<Bool> = .constant(true),
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
        ContinueButton(buttonAction: {})
        ContinueButton(enabled: .constant(false), buttonAction: {})
        ContinueButton(isLoading: .constant(true), buttonAction: {})
    }
}
