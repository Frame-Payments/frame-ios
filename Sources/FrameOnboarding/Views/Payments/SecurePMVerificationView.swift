//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/19/25.
//

import SwiftUI

struct SecurePMVerificationView: View {
    @Environment(\.dismiss) var dismiss
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
    
    var body: some View {
        VStack {
            PageHeaderView(headerTitle: "Verify Your Card") {
                self.returnToPreviousStep = true
            }
            Text("We've sent a security code to your bank registered phone number ending in *")
                .fontWeight(.light)
                .font(.system(size: 14.0))
                .padding(.horizontal)
            codeContainerStack
            ContinueButton(enabled: $codeInput) {
//                Task {
//                    await onboardingContainerViewModel.verify3DSChallenge(verificationCode: enteredCode)
//                }
                self.continueToNextStep = true
            }
            Button {
                Task {
                    await onboardingContainerViewModel.resend3DSChallenge()
                    self.codeResent = true
                }
            } label: {
                Text("Resend Code")
                    .bold()
                    .foregroundColor(.black)
            }
            .disabled(codeResent)

            Spacer()
        }
    }
    
    var codeContainerStack: some View {
        HStack {
            ForEach(0..<6, id: \.self) { index in
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
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                }
                .padding(.horizontal, 3.0)
            }
        }
        .padding()
    }
    
    func codeInputView(index: Int, input: Binding<String>) -> some View {
        TextField("", text: input)
            .textContentType(.oneTimeCode)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 20.0))
            .fontWeight(.semibold)
            .focused($focusedField, equals: index)
            .onChange(of: input.wrappedValue) { oldValue, newValue in
                if newValue.count == 6 { // one time code input | TODO: Need to test text code input.
                    self.enteredCode = newValue
                    
                    let splitValue = newValue.components(separatedBy: "")
                    self.codeInputOne = splitValue[0]
                    self.codeInputTwo = splitValue[1]
                    self.codeInputThree = splitValue[2]
                    self.codeInputFour = splitValue[3]
                    self.codeInputFive = splitValue[4]
                    self.codeInputSix = splitValue[5]
                } else {
                    input.wrappedValue = String(newValue.suffix(1))
                    if index != 5 {
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
        self.codeInput = enteredCode.count == 6
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
    SecurePMVerificationView(onboardingContainerViewModel: OnboardingContainerViewModel(customerId: ""),
                             continueToNextStep: .constant(false),
                             returnToPreviousStep: .constant(false))
}
