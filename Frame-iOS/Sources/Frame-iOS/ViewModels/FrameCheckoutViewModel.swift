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
    
    @Published var selectedCustomerPaymentOption: FrameObjects.PaymentMethod?
    
    var customerId: String = ""
    var amount: Int = 0
    
    func loadCustomerPaymentMethods(customerId: String, amount: Int) async {
        self.customerId = customerId
        self.amount = amount
        self.customerPaymentOptions = try? await PaymentMethodsAPI().getPaymentMethodsWithCustomer(customerId: customerId)
    }
    
    func payWithApplePay() { }
    func payWithGooglePay() { }
    
    func checkoutWithSelectedPaymentMethod(saveMethod: Bool) async {
        var paymentMethod: FrameObjects.PaymentMethod?
        
        if selectedCustomerPaymentOption == nil {
            // Validate Card Info
            guard validateCardInformation() else { return }
            
            // Create Payment Method
            paymentMethod = try? await createPaymentMethod()
        } else {
            paymentMethod = selectedCustomerPaymentOption
        }
        
        //TODO: When do we need to support other currencies?
        //TODO: What should the description be?
        //TODO: Should we load the customer to get their email?
        //TODO: Do we need both payment method data and payment method?
        let request = ChargeIntentsRequests.CreateChargeIntentRequest(amount: amount,
                                                                      currency: "USD",
                                                                      customer: customerId,
                                                                      description: "",
                                                                      paymentMethod: paymentMethod?.id,
                                                                      confirm: true,
                                                                      receiptEmail: nil,
                                                                      authorizationMode: .automatic,
                                                                      customerData: nil,
                                                                      paymentMethodData: nil)
        
        // Create Charge Intent
        let chargeIntent = try? await ChargeIntentsAPI().createChargeIntent(request: request)
        
        // Save Payment Method
        if saveMethod, let id = paymentMethod?.id {
            let attachmentRequest = PaymentMethodRequest.AttachPaymentMethodRequest(customer: customerId)
            _ = try? await PaymentMethodsAPI().attachPaymentMethodWith(paymentMethodId: id, request: attachmentRequest)
        }
    }
    
    func validateCardInformation() -> Bool {
        guard cardNumber.count == 16 else { return false }
        guard cardExpiration.count == 5 else { return false }
        guard cardCVCNumber.count == 3 else { return false }
        guard customerZipCode.count == 5 else { return false }
        return true
    }
    
    func createPaymentMethod() async throws -> FrameObjects.PaymentMethod?  {
        //TODO: Where do we get card type?
        //TODO: Do we need the full address for the payment card?
        let billingAddress = FrameObjects.BillingAddress(city: nil,
                                                  country: customerCountry,
                                                  state: nil,
                                                  postalCode: customerZipCode,
                                                  addressLine1: nil,
                                                  addressLine2: nil)
        let request = PaymentMethodRequest.CreatePaymentMethodRequest(type: "",
                                                                      cardNumber: cardNumber,
                                                                      expMonth: cardExpiration.prefix(2).description,
                                                                      expYear: cardExpiration.suffix(2).description,
                                                                      cvc: cardCVCNumber,
                                                                      customer: customerId,
                                                                      billing: billingAddress)
        return try? await PaymentMethodsAPI().createPaymentMethod(request: request)
    }
    
    func createCustomerBeforeCheckout() { }
}
