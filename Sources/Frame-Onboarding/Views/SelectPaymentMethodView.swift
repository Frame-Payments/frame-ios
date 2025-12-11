//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 11/19/25.
//

import SwiftUI
import EvervaultInputs
import Frame_iOS

struct SelectPaymentMethodView: View {
    @StateObject var paymentMethodViewModel = PaymentMethodViewModel()
    @State private var canCustomerContinue: Bool = false
    
    let customerId: String
    
    let examplePaymentMethod = FrameObjects.PaymentMethod(id: "method_123", type: .card, object: "payment_method", created: 0, updated: 0, livemode: true, card: FrameObjects.PaymentCard(brand: "amex", expirationMonth: "08", expirationYear: "29", currency: "usd", lastFourDigits: "1111"))
    let examplePaymentMethod2 = FrameObjects.PaymentMethod(id: "method_1234", type: .card, object: "payment_method", created: 0, updated: 0, livemode: true, card: FrameObjects.PaymentCard(brand: "visa", expirationMonth: "01", expirationYear: "26", currency: "usd", lastFourDigits: "0000"))
    
    init(customerId: String) {
        self.customerId = customerId
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            addPaymentMethodView
            Divider()
            listPaymentMethodsView
            Spacer()
        }
        .onAppear {
            Task {
                await paymentMethodViewModel.loadCustomerPaymentMethods(customerId: customerId)
            }
        }
    }
    
    var addPaymentMethodView: some View {
        Group {
            Text("Add New Payment Method")
                .bold()
                .padding(.leading)
            PaymentCardInput(cardData: $paymentMethodViewModel.cardData)
                .paymentCardInputStyle(EncryptedPaymentCardInput())
            billingAddressDetails
            Button {
                Task {
                    await paymentMethodViewModel.addNewPaymentMethod(customerId: customerId)
                }
            } label: {
                RoundedRectangle(cornerRadius: 10.0)
                    .fill(.black.opacity(paymentMethodViewModel.checkIfCustomerCanContinue() ? 1.0 : 0.3))
                    .overlay {
                        Text("Continue")
                            .bold()
                            .foregroundColor(.white)
                    }
            }
            .disabled(!paymentMethodViewModel.checkIfCustomerCanContinue())
            .frame(height: 50.0)
            .padding()

        }
    }
    
    @ViewBuilder
    var billingAddressDetails: some View {
        Text("Billing Address")
            .bold()
            .font(.subheadline)
            .foregroundColor(.gray)
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
    
    var listPaymentMethodsView: some View {
        Group {
            Text("Select Existing Payment Method")
                .bold()
                .padding()
            ScrollView {
                paymentMethodView(paymentMethod: examplePaymentMethod) //**WARNING** REMOVE AFTER TESTING
                paymentMethodView(paymentMethod: examplePaymentMethod2) //**WARNING** REMOVE AFTER TESTING
                ForEach(paymentMethodViewModel.paymentMethods) { paymentMethod in
                    paymentMethodView(paymentMethod: paymentMethod)
                }
            }
        }
    }
    

    func paymentMethodView(paymentMethod: FrameObjects.PaymentMethod) -> some View {
        HStack {
            Image(paymentMethod.card?.brand ?? "", bundle: FrameResources.module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100.0, height: 40.0)
            Spacer()
            VStack {
                Text("Last 4 Digits")
                    .font(.subheadline)
                Text("****\(paymentMethod.card?.lastFourDigits ?? "")")
                    .bold()
            }
            Spacer()
            VStack {
                Text("Expiration Date")
                    .font(.subheadline)
                Text("\(paymentMethod.card?.expirationMonth ?? "")/\(paymentMethod.card?.expirationYear ?? "")")
                    .bold()
            }
            .padding(.trailing)
        }
        .frame(maxWidth: .infinity, minHeight: 70.0)
        
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 2)
        )
        .padding(.horizontal)
        .onTapGesture {
            //TODO: Continue to 3DS card verification
        }
    }
}

#Preview {
    SelectPaymentMethodView(customerId: "cus_123")
}
