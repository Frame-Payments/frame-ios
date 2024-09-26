//
//  PaymentMethodsAPI.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 9/26/24.
//

protocol PaymentMethodProtocol {
    func getPaymentMethods(request: PaymentMethodRequest.GetPaymentMethodsRequest?)
    func getPaymentMethodWith(id: String)
    func getPaymentMethodsWithCustomer(id: String, request: PaymentMethodRequest.GetPaymentMethodsRequest?)
    func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest)
    func updatePaymentMethodWith(id: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest)
    func attachPaymentMethodWith(id: String, request: PaymentMethodRequest.AttachPaymentMethodRequest)
    func detachPaymentMethodWith(id: String)
}

// Payments Methods API
class PaymentMethodsAPI: PaymentMethodProtocol {
    func getPaymentMethods(request: PaymentMethodRequest.GetPaymentMethodsRequest?) { }
    
    func getPaymentMethodWith(id: String) { }
    
    func getPaymentMethodsWithCustomer(id: String, request: PaymentMethodRequest.GetPaymentMethodsRequest?) { }
    
    func createPaymentMethod(request: PaymentMethodRequest.CreatePaymentMethodRequest) { }
    
    func updatePaymentMethodWith(id: String, request: PaymentMethodRequest.UpdatePaymentMethodRequest) { }
    
    func attachPaymentMethodWith(id: String, request: PaymentMethodRequest.AttachPaymentMethodRequest) { }
    
    func detachPaymentMethodWith(id: String) { }
}
