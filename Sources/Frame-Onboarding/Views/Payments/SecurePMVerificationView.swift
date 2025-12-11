//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 11/19/25.
//

import SwiftUI

struct SecurePMVerificationView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var codeInput: Bool = false
    @Binding var completedScreen: Bool
    
    var body: some View {
        VStack {
            PageHeaderView(headerTitle: "Verify Your Card") {
                self.dismiss()
            }
            Text("We've sent a security code to your bank registered phone number ending in *")
                .fontWeight(.light)
                .font(.system(size: 14.0))
                .padding(.horizontal)
            ContinueButton(enabled: $codeInput) {
                self.completedScreen = true
            }
            Button {
                //TODO: Prompt the backend to resend the code to the user.
            } label: {
                Text("Resend Code")
                    .bold()
                    .foregroundColor(.black)
            }

            Spacer()
        }
    }
}

#Preview {
    SecurePMVerificationView(completedScreen: .constant(false))
}
