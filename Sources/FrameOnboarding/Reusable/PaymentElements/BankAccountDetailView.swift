//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI

public struct BankAccountDetailView: View {
    @Binding var routingNumber: String
    @Binding var accountNumber: String
    
    @State var headerFont: Font = Font.subheadline
    
    public var body: some View {
        VStack(alignment: .leading) {
            Text("Bank Account Details")
                .bold()
                .font(headerFont)
                .padding([.horizontal, .top])
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
    BankAccountDetailView(routingNumber: .constant(""), accountNumber: .constant(""))
}
