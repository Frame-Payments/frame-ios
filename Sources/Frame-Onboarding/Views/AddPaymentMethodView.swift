//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 12/11/25.
//

import SwiftUI
import EvervaultInputs
import Frame_iOS

struct AddPaymentMethodView: View {
    @StateObject var paymentMethodViewModel = PaymentMethodViewModel()
    @State private var canCustomerContinue: Bool = false
    
    let customerId: String
    
    init(customerId: String) {
        self.customerId = customerId
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            addPaymentMethodView
            Spacer()
        }
        .onChange(of: paymentMethodViewModel.cardData) { oldValue, newValue in
            self.canCustomerContinue = paymentMethodViewModel.checkIfCustomerCanContinue()
        }
        .onChange(of: paymentMethodViewModel.createdBillingAddress) { oldValue, newValue in
            self.canCustomerContinue = paymentMethodViewModel.checkIfCustomerCanContinue()
        }
    }
    
    var addPaymentMethodView: some View {
        Group {
            HStack(alignment: .center) {
                Spacer()
                Text("Add New Payment Method")
                    .bold()
                Spacer()
            }
            .padding(.bottom)
            Text("Card Details")
                .bold()
                .font(.subheadline)
                .padding([.horizontal, .top])
            PaymentCardInput(cardData: $paymentMethodViewModel.cardData)
                .paymentCardInputStyle(EncryptedPaymentCardInput())
            billingAddressDetails
            ContinueButton(enabled: $canCustomerContinue) {
                Task {
                    await paymentMethodViewModel.addNewPaymentMethod(customerId: customerId)
                }
            }
        }
    }
    
    @ViewBuilder
    var billingAddressDetails: some View {
        Text("Billing Address")
            .bold()
            .font(.subheadline)
            .padding([.horizontal, .top])
        RoundedRectangle(cornerRadius: 10.0)
            .fill(.white)
            .stroke(.gray.opacity(0.3))
            .frame(height: 200.0)
            .overlay {
                VStack(spacing: 0) {
                    TextField("",
                              text: $paymentMethodViewModel.createdBillingAddress.addressLine1.orEmpty,
                              prompt: Text("Address Line 1"))
                    .frame(height: 49.0)
                    .padding(.horizontal)
                    Divider()
                    TextField("",
                              text: $paymentMethodViewModel.createdBillingAddress.addressLine2.orEmpty,
                              prompt: Text("Address Line 2"))
                    .frame(height: 49.0)
                    .padding(.horizontal)
                    Divider()
                    HStack {
                        TextField("",
                                  text: $paymentMethodViewModel.createdBillingAddress.city.orEmpty,
                                  prompt: Text("City"))
                        .frame(height: 49.0)
                        .padding(.horizontal)
                        TextField("",
                                  text: $paymentMethodViewModel.createdBillingAddress.state.orEmpty,
                                  prompt: Text("State"))
                        .frame(height: 49.0)
                        .padding(.horizontal)
                    }
                    .frame(height: 49.0)
                    Divider()
                    TextField("",
                              text: $paymentMethodViewModel.createdBillingAddress.postalCode,
                              prompt: Text("Zip Code"))
                    .frame(height: 49.0)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
    }
}

#Preview {
    AddPaymentMethodView(customerId: "cus_123")
}
