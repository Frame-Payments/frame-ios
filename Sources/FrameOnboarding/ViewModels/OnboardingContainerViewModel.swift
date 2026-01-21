//
//  OnboardingContainerViewModel.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/6/26.
//

import Foundation
import Frame
import EvervaultInputs

@MainActor
class OnboardingContainerViewModel: ObservableObject {
    @Published var onboardingSession: OnboardingSession?
    
    // Payment Method
    @Published var cardData = PaymentCardData()
    @Published var bankAccount = FrameObjects.BankAccount()
    @Published var selectedPaymentMethod: FrameObjects.PaymentMethod?
    @Published var selectedPayoutMethod: FrameObjects.PaymentMethod?
    @Published var createdBillingAddress = FrameObjects.BillingAddress(country: AvailableCountry.defaultCountry.alpha2Code, postalCode: "")
    @Published var paymentMethods: [FrameObjects.PaymentMethod] = []
    @Published var payoutMethods: [FrameObjects.PaymentMethod] = []
    @Published var paymentMethodVerification: ThreeDSecureVerification?
    @Published var customerIdentity: FrameObjects.CustomerIdentity?
    @Published var filesToUpload: [FileUpload] = []
    
    @Published var createdCustomerIdentity = CustomerIdentityRequest.CreateCustomerIdentityRequest(firstName: "", lastName: "", dateOfBirth: "", email: "", phoneNumber: "", ssn: "",
                                                                                                   address: FrameObjects.BillingAddress(postalCode: ""))
    
    let customerId: String
    let components: SessionComponents
    
    init(customerId: String, components: SessionComponents) {
        self.customerId = customerId
        self.components = components
    }
    
    // Load existing customer object
    func checkExistingCustomer() async {
        do {
            let (customer, _) = try await CustomersAPI.getCustomerWith(customerId: customerId)
            if let customer {
                let nameComponents = customer.name.components(separatedBy: " ")
                let address = customer.shippingAddress ?? customer.billingAddress ?? FrameObjects.BillingAddress(country: AvailableCountry.defaultCountry.alpha2Code, postalCode: "")
                self.createdCustomerIdentity = CustomerIdentityRequest.CreateCustomerIdentityRequest(firstName: nameComponents.first ?? "",
                                                                                                     lastName: nameComponents.last ?? "",
                                                                                                     dateOfBirth: customer.dateOfBirth ?? "",
                                                                                                     email: customer.email ?? "",
                                                                                                     phoneNumber: customer.phone ?? "",
                                                                                                     ssn: "",
                                                                                                     address: address)
                
            }
        } catch let error {
            print(error)
        }
    }
    
    func updateExistingCustomer() async {
        do {
            let request = CustomerRequest.UpdateCustomerRequest(billingAddress: nil,
                                                                shippingAddress: createdCustomerIdentity.address,
                                                                name: createdCustomerIdentity.firstName + " " + createdCustomerIdentity.lastName,
                                                                phone: createdCustomerIdentity.phoneNumber,
                                                                email: createdCustomerIdentity.email,
                                                                ssn: createdCustomerIdentity.ssn,
                                                                dateOfBirth: createdCustomerIdentity.dateOfBirth)
            let (_, _) = try await CustomersAPI.updateCustomerWith(customerId: customerId, request: request)
        } catch let error {
            print(error)
        }
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
        guard onboardingSession == nil else { return }
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
                self.paymentMethods = methods.filter({ $0.card != nil })
                self.payoutMethods = methods.filter({ $0.ach != nil })
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
                
                self.clearAccountDetails()
            }
        } catch let error {
            print(error)
        }
    }
    
    // Add new payout method to customer object
    func addNewPayoutMethod() async {
        do {
            let request = PaymentMethodRequest.CreateACHPaymentMethodRequest(accountType: bankAccount.accountType ?? .checking,
                                                                             accountNumber: bankAccount.accountNumber ?? "",
                                                                             routingNumber: bankAccount.routingNumber ?? "",
                                                                             customer: customerId,
                                                                             billing: createdBillingAddress)
            let (payoutMethod, _) = try await PaymentMethodsAPI.createACHPaymentMethod(request: request)
            
            if let payoutMethod {
                self.selectedPayoutMethod = payoutMethod
                self.payoutMethods.append(payoutMethod)
                
                self.clearAccountDetails()
            }
        } catch let error {
            print(error)
        }
    }
    
    func updatePayoutMethod() async {
        guard let sessionId = onboardingSession?.id, let payoutMethodId = selectedPayoutMethod?.id else { return }
        let request = SessionRequests.UpdatePayoutMethodRequest(payoutMethodId: payoutMethodId)
        
        do {
            let (session, _) = try await SessionsAPI.updatePayoutMethod(sessionId: sessionId, request: request)
            if let session {
                self.onboardingSession = session
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
            let (verification, verificationError, _) = try await ThreeDSecureVerificationsAPI.create3DSecureVerification(request: request)
            if let verification {
                paymentMethodVerification = verification
            } else if let verificationError, let verificationId = verificationError.error.existingIntentId {
                await retrieve3DSChallenge(verificationId: verificationId)
            }
        } catch let error {
            print(error)
        }
    }
    
    func retrieve3DSChallenge(verificationId: String) async {
        do {
            let (verification, _) = try await ThreeDSecureVerificationsAPI.retrieve3DSecureVerification(verificationId: verificationId)
            if let verification {
                paymentMethodVerification = verification
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
    
    func createCustomerIdentity() async {
        do {
            let (identity, _) = try await CustomerIdentityAPI.createCustomerIdentity(request: createdCustomerIdentity)
            if let identity {
                self.customerIdentity = identity
            }
        } catch let error {
            print(error)
        }
    }
    
    // Upload ID and selfie documents
    func uploadIdentificationDocuments() async {
        guard filesToUpload.count == 3, let customerIdentityId = customerIdentity?.id else { return }
        do {
            let (identity, _) = try await CustomerIdentityAPI.uploadIdentityDocuments(customerIdentityId: customerIdentityId, identityImages: filesToUpload)
            if let identity {
                self.customerIdentity = identity
            }
        } catch let error {
            print(error)
        }
    }
    
    func checkIfCustomerCanContinueWithPersonalInformation() -> Bool {
        guard !createdCustomerIdentity.firstName.isEmpty, !createdCustomerIdentity.lastName.isEmpty, !createdCustomerIdentity.email.isEmpty,
                !createdCustomerIdentity.phoneNumber.isEmpty, !createdCustomerIdentity.ssn.isEmpty, !createdCustomerIdentity.dateOfBirth.isEmpty else { return false }
        guard createdCustomerIdentity.address.addressLine1 != nil, createdCustomerIdentity.address.city != nil, createdCustomerIdentity.address.state != nil, !createdCustomerIdentity.address.postalCode.isEmpty else { return false }
        return true
    }
    
    func checkIfCustomerCanContinueWithPaymentMethod() -> Bool {
        guard createdBillingAddress.addressLine1 != nil, createdBillingAddress.city != nil, createdBillingAddress.state != nil, !createdBillingAddress.postalCode.isEmpty else { return false }
        guard cardData.isValid else { return false }
        return true
    }
    
    func checkIfCustomerCanContinueWithPayoutMethod() -> Bool {
        guard createdBillingAddress.addressLine1 != nil, createdBillingAddress.city != nil, createdBillingAddress.state != nil, !createdBillingAddress.postalCode.isEmpty else { return false }
        guard bankAccount.accountNumber != nil, bankAccount.routingNumber != nil, bankAccount.bankName != nil else { return false }
        return true
    }
    
    func checkIfCustomerCanContinueWithDocs() -> Bool {
        guard filesToUpload.contains(where: { $0.fieldName == .front }) else { return false }
        guard filesToUpload.contains(where: { $0.fieldName == .back }) else { return false }
        guard filesToUpload.contains(where: { $0.fieldName == .selfie }) else { return false }
        return true
    }
    
    func clearAccountDetails() {
        self.cardData = PaymentCardData()
        self.bankAccount = FrameObjects.BankAccount()
        self.createdBillingAddress = FrameObjects.BillingAddress(country: AvailableCountry.defaultCountry.alpha2Code, postalCode: "")
    }
}
