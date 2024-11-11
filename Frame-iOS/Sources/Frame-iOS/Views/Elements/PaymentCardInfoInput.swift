//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/11/24.
//

import SwiftUI

struct PaymentCardInfoInput: View {
    @Binding var inputCardNumber: String
    @Binding var inputExpirationDate: String
    @Binding var inputCVC: String
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10.0)
            .fill(.white)
            .stroke(.gray.opacity(0.3))
            .frame(height: 100.0)
            .overlay {
                VStack(spacing: 0) {
                    TextField("", text: $inputCardNumber.max(16), prompt: Text("Card Number"))
                        .keyboardType(.numberPad)
                        .frame(height: 45.0)
                        .padding(.horizontal)
                    Divider()
                    HStack {
                        TextField("", text: $inputExpirationDate.max(5), prompt: Text("MM/YY"))
                            .keyboardType(.numbersAndPunctuation)
                            .padding(.horizontal)
                        Divider()
                        TextField("", text: $inputCVC.max(3), prompt: Text("CVC"))
                            .keyboardType(.numberPad)
                            .padding(.horizontal)
                    }
                    .frame(height: 45.0)
                }
                .frame(height: 91.0)
            }
            .padding(.horizontal)
    }
}

#Preview {
    PaymentCardInfoInput(inputCardNumber: .constant(""),
                         inputExpirationDate: .constant(""),
                         inputCVC: .constant(""))
}
