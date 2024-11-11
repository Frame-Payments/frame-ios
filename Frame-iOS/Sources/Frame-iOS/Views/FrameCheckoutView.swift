//
//  FrameCheckoutView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/27/24.
//

import SwiftUI

struct FrameCheckoutView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var checkoutViewModel: FrameCheckoutViewModel = FrameCheckoutViewModel()
    @State var useBlackButtons: Bool = true
    
    let customerId: String
    
    var body: some View {
        VStack(alignment: .leading) {
            topHeaderBar
            Divider()
            paymentButtons
            paymentDivider
            cardInformation
                .padding(.bottom)
            regionInformation
            checkoutButton
            Spacer()
        }
        .task {
            await checkoutViewModel.loadCustomerPaymentMethods(customerId: customerId)
        }
    }
    
    var topHeaderBar: some View {
        HStack {
            Text("Checkout")
                .font(.headline)
                .padding(.horizontal)
            Spacer()
            Button {
                self.dismiss()
            } label: {
                if let image = UIImage(named: "BlackCircleCloseButton",
                                       in: Bundle.module, with: nil) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    var paymentDivider: some View {
        HStack(spacing: 7.0) {
            Rectangle().fill(.gray.opacity(0.3))
                .frame(height: 1)
            Text("Or")
            Rectangle().fill(.gray.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    var paymentButtons: some View {
        FramePaymentButton(blackButton: useBlackButtons, paymentOption: .apple) {
            // TODO: Apple Action
        }
        FramePaymentButton(blackButton: useBlackButtons, paymentOption: .google) {
            // TODO: Google Action
        }
    }
    
    @ViewBuilder
    var cardInformation: some View {
        Text("Card Information")
            .font(.headline)
            .foregroundColor(.gray)
            .padding(.horizontal)
        PaymentCardInfoInput(inputCardNumber: $checkoutViewModel.cardNumber,
                             inputExpirationDate: $checkoutViewModel.cardExpiration,
                             inputCVC: $checkoutViewModel.cardCVCNumber)
    }
    
    @ViewBuilder
    var regionInformation: some View {
        Text("Country Or Region")
            .font(.headline)
            .foregroundColor(.gray)
            .padding(.horizontal)
        RoundedRectangle(cornerRadius: 10.0)
            .fill(.white)
            .stroke(.gray.opacity(0.3))
            .frame(height: 99.0)
            .overlay {
                VStack(spacing: 0) {
                    Button {
                        //TODO: Change Country Drawer
                    } label: {
                        HStack {
                            Text(checkoutViewModel.customerCountry)
                                .font(.headline)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding()
                    }
                    Divider()
                    TextField("",
                              text: $checkoutViewModel.customerZipCode.max(5),
                              prompt: Text("Zip Code"))
                    .frame(height: 49.0)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
        HStack(spacing: 0) {
            Button {
                // TODO: Toggle Save Button
            } label: {
                RoundedRectangle(cornerRadius: 5.0)
                    .fill(.white)
                    .stroke(.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
            }
            Text("Save this card for future payments")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            Spacer()
        }
        .padding()
    }
    
    var checkoutButton: some View {
        Button {
            checkoutViewModel.checkoutWithSelectedPaymentMethod()
        } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(.black)
                .frame(height: 50.0)
                .overlay {
                    Text("Pay $0")
                        .font(.headline)
                        .foregroundColor(.white)
                }
        }
        .padding(.horizontal)
    }
}

#Preview {
    FrameCheckoutView(customerId: "")
}
