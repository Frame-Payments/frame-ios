//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/8/24.
//

import Foundation
import EvervaultInputs

@MainActor
class FrameCheckoutViewModel: ObservableObject {
    @Published var customerPaymentOptions: [FrameObjects.PaymentMethod]?
    @Published var customerCountry: String = "United States"
    @Published var customerZipCode: String = ""
    
    @Published var selectedCustomerPaymentOption: FrameObjects.PaymentMethod?
    @Published var cardData = PaymentCardData()
    
    var customerId: String = ""
    var amount: Int = 0
    
    func loadCustomerPaymentMethods(customerId: String, amount: Int) async {
        self.customerId = customerId
        self.amount = amount
        self.customerPaymentOptions = try? await PaymentMethodsAPI.getPaymentMethodsWithCustomer(customerId: customerId)
    }
    
    //TODO: Integrate for Apple Pay and Google Pay
    func payWithApplePay() { }
    func payWithGooglePay() { }
    
    func checkoutWithSelectedPaymentMethod(saveMethod: Bool) async {
        var paymentMethod: FrameObjects.PaymentMethod?
        
        if selectedCustomerPaymentOption == nil {
            guard customerZipCode.count == 5 else { return }
            
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
        let chargeIntent = try? await ChargeIntentsAPI.createChargeIntent(request: request)
        
        // Save Payment Method
        if saveMethod, let id = paymentMethod?.id {
            let attachmentRequest = PaymentMethodRequest.AttachPaymentMethodRequest(customer: customerId)
            _ = try? await PaymentMethodsAPI.attachPaymentMethodWith(paymentMethodId: id, request: attachmentRequest)
        }
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
        let request = PaymentMethodRequest.CreatePaymentMethodRequest(type: cardData.card.type?.brand ?? "",
                                                                      cardNumber: cardData.card.number,
                                                                      expMonth: cardData.card.expMonth,
                                                                      expYear: cardData.card.expYear,
                                                                      cvc: cardData.card.cvc,
                                                                      customer: customerId,
                                                                      billing: billingAddress)
        return try? await PaymentMethodsAPI.createPaymentMethod(request: request)
    }
}
