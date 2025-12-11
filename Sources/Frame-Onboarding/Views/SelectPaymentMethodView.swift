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
    
    let examplePaymentMethod = FrameObjects.PaymentMethod(id: "method_123", type: .card, object: "payment_method", created: 0, updated: 0, livemode: true, card: FrameObjects.PaymentCard(brand: "mastercard", expirationMonth: "08", expirationYear: "29", currency: "usd", lastFourDigits: "1111"))
    let examplePaymentMethod2 = FrameObjects.PaymentMethod(id: "method_1234", type: .card, object: "payment_method", created: 0, updated: 0, livemode: true, card: FrameObjects.PaymentCard(brand: "visa", expirationMonth: "01", expirationYear: "26", currency: "usd", lastFourDigits: "0000"))
    
    init(customerId: String) {
        self.customerId = customerId
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            listPaymentMethodsView
            Spacer()
        }
        .onAppear {
            Task {
                await paymentMethodViewModel.loadCustomerPaymentMethods(customerId: customerId)
            }
        }
    }
    
    var listPaymentMethodsView: some View {
        Group {
            HStack {
                Spacer()
                Text("Select A Payment Method")
                    .bold()
                    .padding()
                Spacer()
            }
            Text("Choose a saved payment method or add a new one to continue")
                .fontWeight(.light)
                .font(.system(size: 14.0))
                .padding(.horizontal)
            ScrollView {
                headerScrollTitles(name: "Saved Payment Methods")
                paymentMethodView(paymentMethod: examplePaymentMethod) //**WARNING** REMOVE AFTER TESTING
                paymentMethodView(paymentMethod: examplePaymentMethod2) //**WARNING** REMOVE AFTER TESTING
                ForEach(paymentMethodViewModel.paymentMethods) { paymentMethod in
                    paymentMethodView(paymentMethod: paymentMethod)
                }
                headerScrollTitles(name: "Add Payment Method")
                addPaymentMethodRow
            }
        }
    }
    
    func headerScrollTitles(name: String) -> some View {
        HStack {
            Text(name)
                .bold()
                .font(.system(size: 14.0))
                .padding(.horizontal)
                .padding(.vertical, 8.0)
            Spacer()
        }
    }
    
    var addPaymentMethodRow: some View {
        HStack {
            Image("emptycard", bundle: FrameResources.module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48.0, height: 32.0)
                .padding(.horizontal)
            Text("Debit/Credit Card")
                .bold()
                .font(.system(size: 14.0))
            Spacer()
            Image("right-chevron", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .onTapGesture {
            //TODO: Continue to 3DS card verification
        }
    }
    
    func paymentMethodView(paymentMethod: FrameObjects.PaymentMethod) -> some View {
        HStack {
            Image(paymentMethod.card?.brand ?? "", bundle: FrameResources.module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48.0, height: 32.0)
                .padding(.horizontal)
            VStack(alignment: .leading) {
                Text("•••• \(paymentMethod.card?.lastFourDigits ?? "")")
                    .bold()
                    .font(.system(size: 14.0))
                    .padding(.bottom, 1.0)
                Text("Exp. \(paymentMethod.card?.expirationMonth ?? "")/\(paymentMethod.card?.expirationYear ?? "")")
                    .font(.system(size: 12.0))
            }
            Spacer()
            Image(paymentMethodViewModel.selectedPaymentMethod == paymentMethod ? "filled-selection" : "empty-selection", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .onTapGesture {
            paymentMethodViewModel.selectedPaymentMethod = paymentMethod
            //TODO: Continue to 3DS card verification
        }
    }
}

#Preview {
    SelectPaymentMethodView(customerId: "cus_123")
}
