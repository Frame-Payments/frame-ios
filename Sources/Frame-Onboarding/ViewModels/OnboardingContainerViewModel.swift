//
//  OnboardingContainerViewModel.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/6/26.
//

import Foundation
import Frame_iOS
import EvervaultInputs

@MainActor
class OnboardingContainerViewModel: ObservableObject {
    @Published var onboardingSession: OnboardingSession?
    
    // Payment Method
    @Published var cardData = PaymentCardData()
    @Published var selectedPaymentMethod: FrameObjects.PaymentMethod?
    @Published var createdBillingAddress = FrameObjects.BillingAddress(country: AvailableCountry.defaultCountry.alpha2Code, postalCode: "")
    @Published var paymentMethods: [FrameObjects.PaymentMethod] = []
    @Published var paymentMethodVerification: ThreeDSecureVerification?
    
    let customerId: String
    let components: SessionComponents
    
    init(customerId: String, components: SessionComponents) {
        self.customerId = customerId
        self.components = components
    }
    
    // Check for existing onboarding session for Customer
    func checkExistingOnboardingSession() async {
        do {
            let (sessionResponse, _) = try await SessionsAPI.getOnboardingSessionWithCustomer(customerId: customerId)
            if let session = sessionResponse?.data?.first {
                self.onboardingSession = session
                
                //TODO: Determine which step to skip to based off the existing onboarding session.
            }
        } catch let error {
            print(error)
        }
    }
    
    // Create new onboarding session with Identification types
    func createOnboardingSession(selectedIdType: IdentificationTypes, selectedCountry: AvailableCountry) async {
        let metadata = SessionMetadata(appVersion: "1.0",
                                       deviceId: "",
                                       documentCountry: selectedCountry.displayName,
                                       documentType: selectedIdType.rawValue)
        let request = SessionRequests.CreateOnboardingSession(customerId: customerId,
                                                              metadata: metadata,
                                                              components: components)
        do {
            let (sessionResponse, _) = try await SessionsAPI.createOnboardingSession(request: request)
            if let sessionResponse {
//                DispatchQueue.main.async {
//                    self.onboardingSession = sessionResponse
//                }
                
                self.onboardingSession = sessionResponse
            }
        } catch let error {
            print(error)
        }
    }
    
    // Load existing Payment Methods for customer
    func loadExistingPaymentMethods() async {
        do {
            let (paymentMethodResponse, _) = try await PaymentMethodsAPI.getPaymentMethodsWithCustomer(customerId: customerId)
            if let methods = paymentMethodResponse?.data {
                self.paymentMethods = methods
            }
        } catch let error {
            print(error)
        }
    }
    
    // Add new payment method to customer object
    func addNewPaymentMethod() async {
        do {
            let request = PaymentMethodRequest.CreateCardPaymentMethodRequest(cardNumber: cardData.card.number,
                                                                              expMonth: cardData.card.expMonth,
                                                                              expYear: cardData.card.expYear,
                                                                              cvc: cardData.card.cvc,
                                                                              customer: customerId,
                                                                              billing: createdBillingAddress)
            let (paymentMethod, _) = try await PaymentMethodsAPI.createCardPaymentMethod(request: request, encryptData: false)
            
            if let paymentMethod {
                self.selectedPaymentMethod = paymentMethod
                self.paymentMethods.append(paymentMethod)
            }
        } catch let error {
            print(error)
        }
    }
    
    // Start 3DS process with select payment method
    func start3DSecureProcess() async {
        guard let paymentMethodId = selectedPaymentMethod?.id else { return }
        let request = ThreeDSecureRequests.CreateThreeDSecureVerification(paymentMethodId: paymentMethodId)
        do {
            let (verification, _) = try await ThreeDSecureVerificationsAPI.create3DSecureVerification(request: request)
            if let verification {
                paymentMethodVerification = verification
            }
        } catch let error {
            print(error)
        }
    }
    
    // Verify 3DS process with code
    func verify3DSChallenge(verificationCode: String) async {
        let confirmationRequest = ThreeDSecureRequests.ConfirmThreeDSecureVerification(code: verificationCode)
        do {
            let (verification, _) =  try await ThreeDSecureVerificationsAPI.confirm3DSecureVerification(verificationId: paymentMethodVerification?.id ?? "",
                                                                                                        request: confirmationRequest)
            if let verification {
                self.paymentMethodVerification = verification
            }
        } catch let error {
            print(error)
        }
    }
    
    // Resend 3DS code to customer
    func resend3DSChallenge() async {
        do {
            let (verification, _) = try await ThreeDSecureVerificationsAPI.resend3DSecureVerification(verificationId: paymentMethodVerification?.id ?? "")
            if let verification {
                self.paymentMethodVerification = verification
            }
        } catch let error {
            print(error)
        }
    }
    
    // Upload ID and selfie documents
    func uploadIdentificationDocuments() async {}
    
    func checkIfCustomerCanContinueWithPaymentMethod() -> Bool {
        guard createdBillingAddress.addressLine1 != nil, createdBillingAddress.city != nil, createdBillingAddress.state != nil, !createdBillingAddress.postalCode.isEmpty else { return false }
        guard cardData.isValid else { return false }
        return true
    }
}
