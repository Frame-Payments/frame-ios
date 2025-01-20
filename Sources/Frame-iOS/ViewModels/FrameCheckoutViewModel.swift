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
    
    var customerId: String?
    var amount: Int = 0
    
    func loadCustomerPaymentMethods(customerId: String?, amount: Int) async {
        self.amount = amount
        
        guard let customerId else { return }
        self.customerId = customerId
        
        self.customerPaymentOptions = try? await PaymentMethodsAPI.getPaymentMethodsWithCustomer(customerId: customerId)
    }
    
    //TODO: Integrate for Apple Pay and Google Pay
    func payWithApplePay() { }
    func payWithGooglePay() { }
    
    func checkoutWithSelectedPaymentMethod(saveMethod: Bool) async throws -> FrameObjects.ChargeIntent? {
        guard amount != 0 else { return nil }
        var paymentMethod: FrameObjects.PaymentMethod?
        
        if selectedCustomerPaymentOption == nil {
            guard customerZipCode.count == 5 else { return nil }
            paymentMethod = try? await createPaymentMethod()
        } else {
            paymentMethod = selectedCustomerPaymentOption
        }
        guard paymentMethod != nil else { return nil }
        
        //TODO: What should the description be? - Dev should be able to set this someone when using component.
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
        
        // Create Charge Intent, return this on completion.
        let chargeIntent = try? await ChargeIntentsAPI.createChargeIntent(request: request)
        return chargeIntent
        // Show API error for charge intent, and why it failed.
    }
    
    func createPaymentMethod() async throws -> FrameObjects.PaymentMethod?  {
        guard !customerCountry.isEmpty, !customerZipCode.isEmpty, cardData.isPotentiallyValid else { return nil }
        
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
