//
//  SecurePMVerificationView.swift
//  Frame-iOS
//

import SwiftUI
import UIKit
import Frame

/// 3D Secure is deliberately absent: an issuer code must never pass through the app, so that
/// challenge is presented in a web view by `FrameThreeDSecureChallengePresenter`.
enum CodeVerificationType {
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
    
    private var displayPhoneNumber: String {
        let dial = onboardingContainerViewModel.phoneCountry.dialCode
        // Keep PhoneNumberKit formatting (e.g. "(200) 100-1695") so grouping spaces remain.
        let formatted = onboardingContainerViewModel.authPhoneNumber.trimmingCharacters(in: .whitespaces)
        if formatted.isEmpty {
            return dial
        }
        return "\(dial) \(formatted)"
    }

    private var otpSubtitle: AttributedString {
        var prefix = AttributedString("We texted a 6-digit code to ")
        var phone = AttributedString(displayPhoneNumber)
        phone.font = theme.fonts.bodySmall.bold()
        phone.foregroundColor = UIColor(theme.colors.textPrimary)
        prefix.append(phone)
        return prefix
    }

    /// Matches the gap between "Resend code" and "Change phone number".
    private let otpActionSpacing: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading) {
            PageHeaderView(headerTitle: "Enter your verification code") {
                switch type {
                case .proveOtp:
                    onboardingContainerViewModel.cancelProveOTP()
                case .phone:
                    self.returnToPreviousStep = true
                }
            }
            .onAppear {
                if type == .phone {
                    AccountEventEmitter.emit(name: .phoneCodeEntryStarted, screen: .phoneVerification)
                }
            }
            Text(otpSubtitle)
                .font(theme.fonts.bodySmall)
                .foregroundStyle(theme.colors.textSecondary)
                .padding(.horizontal)
            codeContainerStack
            VStack(alignment: .leading, spacing: otpActionSpacing) {
                Text("Your code expires in 10 minutes")
                    .font(theme.fonts.caption)
                    .foregroundStyle(theme.colors.textSecondary)

                Button("Resend code") {
                    Task {
                        let dob = DateOfBirthFormatter.format(
                            year: onboardingContainerViewModel.authBirthYear,
                            month: onboardingContainerViewModel.authBirthMonth,
                            day: onboardingContainerViewModel.authBirthDay
                        )
                        let phoneNumber = onboardingContainerViewModel.phoneCountry.dialCode
                            + onboardingContainerViewModel.authPhoneNumber.replacingOccurrences(of: " ", with: "")
                        await onboardingContainerViewModel.sendOTPVerification(
                            phoneNumber: phoneNumber,
                            dateOfBirth: dob
                        )
                        clearEnteredCode()
                    }
                }
                .font(theme.fonts.bodySmall)
                .foregroundStyle(theme.colors.textPrimary)
                .disabled(onboardingContainerViewModel.isPerformingAction)

                Button("Change phone number") {
                    switch type {
                    case .proveOtp:
                        onboardingContainerViewModel.cancelProveOTP()
                    case .phone:
                        self.returnToPreviousStep = true
                    }
                }
                .font(theme.fonts.bodySmall)
                .foregroundStyle(theme.colors.textPrimary)

                ContinueButton(enabled: $codeInput,
                               isLoading: .constant(onboardingContainerViewModel.isPerformingAction),
                               includeOuterPadding: false) {
                    Task {
                        switch type {
                        case .phone:
                            if await onboardingContainerViewModel.confirmTwilioOTP(code: enteredCode) {
                                self.continueToNextStep = true
                            } else {
                                clearEnteredCode()
                            }
                        case .proveOtp:
                            onboardingContainerViewModel.submitProveOTP(enteredCode)
                        }
                    }
                }
                // Slightly more room under the text links before the primary button.
                .padding(.top, 6 - otpActionSpacing)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 16)
            Spacer()
        }
        .onChange(of: type) { _, _ in
            clearEnteredCode()
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
    
    /// Empties every digit box and returns focus to the first one, so a rejected code can be
    /// retyped without the applicant having to clear six fields by hand.
    func clearEnteredCode() {
        codeInputOne = ""
        codeInputTwo = ""
        codeInputThree = ""
        codeInputFour = ""
        codeInputFive = ""
        codeInputSix = ""
        updateMainCodeInput()
        focusedField = 0
    }

    func updateMainCodeInput() {
        self.enteredCode = codeInputOne + codeInputTwo + codeInputThree + codeInputFour + codeInputFive + codeInputSix
        self.codeInput = enteredCode.count == codeCount
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
