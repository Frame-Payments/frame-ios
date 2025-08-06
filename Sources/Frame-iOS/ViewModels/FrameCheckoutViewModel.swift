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
    @Published var customerName: String = ""
    @Published var customerEmail: String = ""
    @Published var customerAddressLine1: String = ""
    @Published var customerAddressLine2: String = ""
    @Published var customerCity: String = ""
    @Published var customerState: String = ""
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
        
        let customer = try? await CustomersAPI.getCustomerWith(customerId: customerId)
        self.customerPaymentOptions = customer?.paymentMethods
        self.customerName = customer?.name ?? ""
        self.customerEmail = customer?.email ?? ""
    }
    
    //TODO: Integrate for Apple Pay and Google Pay
    func payWithApplePay() { }
    func payWithGooglePay() { }
    
    func checkoutWithSelectedPaymentMethod(saveMethod: Bool) async throws -> FrameObjects.ChargeIntent? {
        guard amount != 0 else { return nil }
        var paymentMethodId: String?
        
        if selectedCustomerPaymentOption == nil {
            guard customerZipCode.count == 5 else { return nil }
            let customerInfo = try? await createPaymentMethod(customerId: customerId)
            paymentMethodId = customerInfo?.paymentId
            customerId = customerInfo?.customerId
        } else {
            paymentMethodId = selectedCustomerPaymentOption?.id
        }
        guard paymentMethodId != nil else { return nil }
        
        //TODO: Allow developers to pass description here of charge.
        let request = ChargeIntentsRequests.CreateChargeIntentRequest(amount: amount,
                                                                      currency: "usd",
                                                                      customer: customerId,
                                                                      description: "",
                                                                      paymentMethod: paymentMethodId,
                                                                      confirm: true,
                                                                      receiptEmail: nil,
                                                                      authorizationMode: .automatic,
                                                                      customerData: nil,
                                                                      paymentMethodData: nil)
        
        // Create Charge Intent, return this on completion.
        return try? await ChargeIntentsAPI.createChargeIntent(request: request)
        
        //TODO: Show API error for charge intent, and why it failed.
    }
    
    func createPaymentMethod(customerId: String? = nil) async throws -> (paymentId: String?, customerId: String?)  {
        guard !customerCountry.isEmpty, !customerZipCode.isEmpty, cardData.isPotentiallyValid else { return (nil, nil) }
        let billingAddress = FrameObjects.BillingAddress(city: customerCity,
                                                         country: convertCustomerCountry(),
                                                         state: customerState,
                                                         postalCode: customerZipCode,
                                                         addressLine1: customerAddressLine1,
                                                         addressLine2: customerAddressLine2)
        
        var currentCustomerId: String = ""
        if customerId == nil {
            //1. Create the new user to assign the payment method to.
            let customerRequest = CustomerRequest.CreateCustomerRequest(billingAddress: billingAddress, name: customerName, email: customerEmail)
            let customer = try? await CustomersAPI.createCustomer(request: customerRequest)
            currentCustomerId = customer?.id ?? ""
            guard currentCustomerId != "" else { return (nil, nil) }
        } else if let customerId {
            currentCustomerId = customerId
        }
        
        //2. Create the payment method
        let request = PaymentMethodRequest.CreatePaymentMethodRequest(type: "card",
                                                                      cardNumber: cardData.card.number,
                                                                      expMonth: cardData.card.expMonth,
                                                                      expYear: cardData.card.expYear,
                                                                      cvc: cardData.card.cvc,
                                                                      customer: nil,
                                                                      billing: billingAddress)
        let paymentMethod = try? await PaymentMethodsAPI.createPaymentMethod(request: request, encryptData: false)
        guard let paymentMethodId = paymentMethod?.id else { return (nil, nil) }
        
        //3. Attach the new payment method to the customer.
        let attachRequest = PaymentMethodRequest.AttachPaymentMethodRequest(customer: currentCustomerId)
        let method = try? await PaymentMethodsAPI.attachPaymentMethodWith(paymentMethodId: paymentMethodId, request: attachRequest)
        return (method?.id, currentCustomerId)
    }
    
    func convertCustomerCountry() -> String {
        // Will be configured in the future when more countries are supported
//        if customerCountry.localizedCaseInsensitiveContains("united states") {
//            return "US"
//        }
        
        return "US"
    }
}
