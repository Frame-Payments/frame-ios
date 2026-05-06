//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/19/25.
//

import SwiftUI
import Frame

enum CodeVerificationType {
    case threeDS
    case phone
    case proveOtp
    
    var codeCount: Int {
        return 6
    }
}

struct SecurePMVerificationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.frameTheme) private var theme
    @FocusState private var focusedField: Int?
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel
    
    @State private var codeInput: Bool = false
    @State private var enteredCode: String = ""
    @State private var codeResent: Bool = false
    
    @State private var codeInputOne: String = ""
    @State private var codeInputTwo: String = ""
    @State private var codeInputThree: String = ""
    @State private var codeInputFour: String = ""
    @State private var codeInputFive: String = ""
    @State private var codeInputSix: String = ""
    
    @Binding var continueToNextStep: Bool
    @Binding var returnToPreviousStep: Bool
    
    let type: CodeVerificationType
    let codeCount: Int

    init(type: CodeVerificationType, onboardingContainerViewModel: OnboardingContainerViewModel, continueToNextStep: Binding<Bool>, returnToPreviousStep: Binding<Bool>) {
        self.type = type
        self.codeCount = type.codeCount
        self._onboardingContainerViewModel = StateObject(wrappedValue: onboardingContainerViewModel)
        self._continueToNextStep = continueToNextStep
        self._returnToPreviousStep = returnToPreviousStep
    }
    
    private var headerTitle: String {
        switch type {
        case .threeDS:
            return "Verify Your Card"
        case .phone, .proveOtp:
            return "Enter Verification Code"
        }
    }

    private var bodyText: String {
        switch type {
        case .threeDS:
            return "We've sent a security code to your bank registered phone number ending in *"
        case .phone, .proveOtp:
            return "We've sent a verification code to your phone. Enter it below."
        }
    }

    var body: some View {
        VStack {
            PageHeaderView(headerTitle: headerTitle) {
                switch type {
                case .proveOtp:
                    onboardingContainerViewModel.cancelProveOTP()
                case .threeDS, .phone:
                    self.returnToPreviousStep = true
                }
            }
            Text(bodyText)
                .fontWeight(type == .proveOtp ? .regular : .light)
                .font(theme.fonts.bodySmall)
                .foregroundColor(type == .proveOtp ? theme.colors.textSecondary : .primary)
                .padding(.horizontal)
            codeContainerStack
            ContinueButton(enabled: $codeInput,
                           isLoading: .constant(onboardingContainerViewModel.isPerformingAction)) {
                Task {
                    switch type {
                    case .threeDS:
                        //TODO: Submit 3DS verification code to backend.
//                        await onboardingContainerViewModel.retrieve3DSChallenge(verificationId: enteredCode)
                        self.continueToNextStep = true
                    case .phone:
                        await onboardingContainerViewModel.confirmTwilioOTP(code: enteredCode)
                        if onboardingContainerViewModel.proveUserInfo != nil {
                            self.continueToNextStep = true
                        }
                    case .proveOtp:
                        onboardingContainerViewModel.submitProveOTP(enteredCode)
                    }
                }
            }
            if type == .threeDS {
                Button {
                    Task {
                        await onboardingContainerViewModel.resend3DSChallenge()
                        self.codeResent = true
                    }
                } label: {
                    Text("Resend Code")
                        .bold()
                        .foregroundColor(theme.colors.textPrimary)
                }
                .disabled(codeResent)
            }

            Spacer()
        }
    }
    
    var codeContainerStack: some View {
        HStack {
            if codeCount == 4 {
                Spacer().frame(height: 1.0)
            }
            ForEach(0..<codeCount, id: \.self) { index in
                VStack {
                    switch index {
                    case 0:
                        codeInputView(index: index, input: $codeInputOne)
                    case 1:
                        codeInputView(index: index, input: $codeInputTwo)
                    case 2:
                        codeInputView(index: index, input: $codeInputThree)
                    case 3:
                        codeInputView(index: index, input: $codeInputFour)
                    case 4:
                        codeInputView(index: index, input: $codeInputFive)
                    default:
                        codeInputView(index: index, input: $codeInputSix)
                    }
                }
                .frame(height: 70.0)
                .overlay {
                    RoundedRectangle(cornerRadius: theme.radii.medium)
                        .stroke(theme.colors.surfaceStroke, lineWidth: 1)
                }
                .padding(.horizontal, 3.0)
            }
            if codeCount == 4 {
                Spacer().frame(height: 1.0)
            }
        }
        .padding()
    }
    
    func codeInputView(index: Int, input: Binding<String>) -> some View {
        TextField("", text: input)
            .textContentType(.oneTimeCode)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(theme.fonts.title)
            .fontWeight(.semibold)
            .focused($focusedField, equals: index)
            .onChange(of: input.wrappedValue) { oldValue, newValue in
                if newValue.count == codeCount {
                    self.enteredCode = newValue

                    let splitValue = newValue.map { String($0) }
                    self.codeInputOne = splitValue[0]
                    self.codeInputTwo = splitValue[1]
                    self.codeInputThree = splitValue[2]
                    self.codeInputFour = splitValue[3]
                    if codeCount > 4 {
                        self.codeInputFive = splitValue[4]
                        self.codeInputSix = splitValue[5]
                    }
                    focusedField = nil
                } else {
                    input.wrappedValue = String(newValue.suffix(1))
                    if index != codeCount - 1 {
                        focusedField = index + 1
                    } else {
                        focusedField = nil
                    }
                }
                self.updateMainCodeInput()
            }
    }
    
    func updateMainCodeInput() {
        self.enteredCode = codeInputOne + codeInputTwo + codeInputThree + codeInputFour + codeInputFive + codeInputSix
        self.codeInput = enteredCode.count == codeCount
    }
    
    func replace(myString: String, _ index: Int, _ newChar: Character) -> String {
        var chars = Array(myString) // gets an array of characters
        if index >= 0 && index < chars.count {
            chars[index] = newChar
            return String(chars)
        }
        return myString
    }

}

#Preview {
    SecurePMVerificationView(type: .phone,
                             onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []),
                             continueToNextStep: .constant(false),
                             returnToPreviousStep: .constant(false))
}

#Preview("Dark") {
    SecurePMVerificationView(type: .phone,
                             onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []),
                             continueToNextStep: .constant(false),
                             returnToPreviousStep: .constant(false))
        .preferredColorScheme(.dark)
}
