//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI

public struct BankAccountDetailView: View {
    @Binding public var routingNumber: String
    @Binding public var accountNumber: String
    
    @State public var headerFont: Font = Font.subheadline
    @State public var showHeaderText: Bool = true
    
    public var body: some View {
        VStack(alignment: .leading) {
            if showHeaderText {
                Text("Bank Account Details")
                    .bold()
                    .font(headerFont)
                    .padding([.horizontal, .top])
            }
            RoundedRectangle(cornerRadius: 10.0)
                .fill(.white)
                .stroke(.gray.opacity(0.3))
                .frame(height: 100.0)
                .overlay {
                    VStack(spacing: 0) {
                        ReusableFormTextField(prompt: "Routing Number", text: $routingNumber, showDivider: true)
                        ReusableFormTextField(prompt: "Account Number", text: $accountNumber, showDivider: false, keyboardType: .numberPad)
                    }
                }
                .padding(.horizontal)
        }
    }
}

#Preview {
    VStack {
        BankAccountDetailView(routingNumber: .constant(""), accountNumber: .constant(""))
        BankAccountDetailView(routingNumber: .constant(""), accountNumber: .constant(""), showHeaderText: false)
    }
}
