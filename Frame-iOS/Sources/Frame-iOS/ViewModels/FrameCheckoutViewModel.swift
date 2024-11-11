//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/8/24.
//

import Foundation

@MainActor
class FrameCheckoutViewModel: ObservableObject {
    @Published var customerPaymentOptions: [FrameObjects.PaymentMethod]?
    
    @Published var cardNumber: String = ""
    @Published var cardExpiration: String = ""
    @Published var cardCVCNumber: String = ""
    @Published var customerCountry: String = "United States"
    @Published var customerZipCode: String = ""
    
    @Published var saveCustomerInfo: Bool = false
    
    func loadCustomerPaymentMethods(customerId: String) async {
        self.customerPaymentOptions = try? await PaymentMethodsAPI().getPaymentMethodsWithCustomer(customerId: customerId)
    }
    
    func payWithApplePay() { }
    func payWithGooglePay() { }
    func checkoutWithSelectedPaymentMethod() { }
    func validateCardInformation() { }
    func createCustomerBeforeCheckout() { }
}
