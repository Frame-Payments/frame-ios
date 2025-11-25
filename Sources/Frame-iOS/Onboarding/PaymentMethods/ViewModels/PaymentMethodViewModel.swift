//
//  File.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 11/19/25.
//

import Foundation
import EvervaultInputs

@MainActor
class PaymentMethodViewModel: ObservableObject {
    @Published var cardData = PaymentCardData()
    @Published var createdPaymentMethod: FrameObjects.PaymentMethod?
    @Published var createdBillingAddress = FrameObjects.BillingAddress(country: "United States", postalCode: "")
    @Published var paymentMethods: [FrameObjects.PaymentMethod] = []
    
    init() {}
    
    func loadCustomerPaymentMethods(customerId: String) async {
        do {
            let (paymentMethodResponse, _) = try await PaymentMethodsAPI.getPaymentMethodsWithCustomer(customerId: customerId)
            if let methods = paymentMethodResponse?.data {
                self.paymentMethods = methods
            }
        } catch let error {
            print(error)
        }
    }
    
    func addNewPaymentMethod(customerId: String) async {
        do {
            let request = PaymentMethodRequest.CreateCardPaymentMethodRequest(cardNumber: cardData.card.number,
                                                                              expMonth: cardData.card.expMonth,
                                                                              expYear: cardData.card.expYear,
                                                                              cvc: cardData.card.cvc,
                                                                              customer: customerId,
                                                                              billing: nil)
            let (paymentMethod, _) = try await PaymentMethodsAPI.createCardPaymentMethod(request: request, encryptData: false)
            self.createdPaymentMethod = paymentMethod
        } catch let error {
            print(error)
        }
    }
    
    func checkIfCustomerCanContinue() -> Bool {
        guard createdBillingAddress.addressLine1 != nil, createdBillingAddress.city != nil, createdBillingAddress.state != nil, !createdBillingAddress.postalCode.isEmpty else { return false }
        guard cardData.isValid else { return false }
        return true
    }
}
