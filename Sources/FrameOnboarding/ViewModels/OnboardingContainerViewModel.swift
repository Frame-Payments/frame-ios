//
//  OnboardingContainerViewModel.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/6/26.
//

import Foundation
import Frame
import EvervaultInputs
import CoreLocation

@MainActor
class OnboardingContainerViewModel: ObservableObject {
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
    @Published var ipAddress: String?
    @Published var userCoordinates: CLLocationCoordinate2D?
    
    @Published var createdCustomerIdentity = CustomerIdentityRequest.CreateCustomerIdentityRequest(firstName: "", lastName: "", dateOfBirth: "", email: "", phoneNumber: "",
                                                                                                   ssn: "", address: FrameObjects.BillingAddress(postalCode: ""))
    
    let requiredCapabilities: [FrameObjects.Capabilities]
    var accountId: String?
    
    init(accountId: String?, requiredCapabilities: [FrameObjects.Capabilities]) {
        self.accountId = accountId
        self.requiredCapabilities = requiredCapabilities
    }
    
    // Load existing account object to show on account page.
    func checkExistingAccount() async {
        guard let accountId else { return }
        do {
            let (account, _) = try await AccountsAPI.getAccountWith(accountId: accountId)
            guard let profile = account?.profile?.individual else { return }
            self.createdCustomerIdentity = CustomerIdentityRequest.CreateCustomerIdentityRequest(firstName: profile.firstName ?? "",
                                                                                                 lastName: profile.lastName ?? "",
                                                                                                 dateOfBirth: profile.birthdate ?? "",
                                                                                                 email: profile.email ?? "",
                                                                                                 phoneNumber: profile.phoneNumber ?? "",
                                                                                                 ssn: profile.ssnLastFour ?? "",
                                                                                                 address: profile.address ?? FrameObjects.BillingAddress(postalCode: ""))
        } catch let error {
            print(error)
        }
    }
    
    // Create new individual account if no ID was previously provided to start onboarding.
    func createIndividualAccount() async {
        do {
            let individualAccount = AccountRequest.CreateIndividualAccount(name: FrameObjects.AccountNameInfo(firstName: createdCustomerIdentity.firstName,
                                                                                                              lastName: createdCustomerIdentity.lastName),
                                                                           email: createdCustomerIdentity.email,
                                                                           phone: FrameObjects.AccountPhoneNumber(number: createdCustomerIdentity.phoneNumber,
                                                                                                                  countryCode: "+1"),
                                                                           address: createdCustomerIdentity.address,
                                                                           dob: createdCustomerIdentity.dateOfBirth,
                                                                           ssn: createdCustomerIdentity.ssn)
            let profile = AccountRequest.CreateAccountProfile(business: nil, individual: individualAccount)
            let request = AccountRequest.CreateAccountRequest(accountType: .individual, profile: profile)
            let (account, _) = try await AccountsAPI.createAccount(request: request)
            
            guard let account else { return }
            self.accountId = account.id
            
            await addCapabilitiesToIndividualAccount()
        } catch let error {
            print(error)
        }
    }
    
    func addCapabilitiesToIndividualAccount() async {
        guard let accountId else { return }
        
        do {
            let request = CapabilityRequest.RequestCapabilitiesRequest(capabilities: requiredCapabilities)
            let (capabilities, _) = try await CapabilitiesAPI.requestCapabilities(accountId: accountId, request: request)
            
            if let capabilities {
                // Use this to find the requirements to show in subsequent screens, where do we pull the steps from?
            }
        } catch let error {
            print (error)
        }
    }
    
    // Create new business account if no ID was previously provided to start onboarding.
    func createNewBusinessAccount() async { }

    // Update individual account if ID was provided at the start of onboarding.
    func updateExistingIndividualAccount() async {
        guard let accountId else { return }
        
        do {
            let individualAccount = AccountRequest.UpdateIndividualAccount(name: FrameObjects.AccountNameInfo(firstName: createdCustomerIdentity.firstName,
                                                                                                              lastName: createdCustomerIdentity.lastName),
                                                                           email: createdCustomerIdentity.email,
                                                                           phone: FrameObjects.AccountPhoneNumber(number: createdCustomerIdentity.phoneNumber,
                                                                                                                  countryCode: "+1"),
                                                                           address: createdCustomerIdentity.address,
                                                                           dob: createdCustomerIdentity.dateOfBirth,
                                                                           ssn: createdCustomerIdentity.ssn)
            let request = AccountRequest.UpdateAccountRequest(profile: AccountRequest.UpdateAccountProfile(business: nil, individual: individualAccount))
            try await AccountsAPI.updateAccountWith(accountId: accountId, request: request)
        } catch let error {
            print(error)
        }
    }
    
    // Load existing Payment Methods for customer
    func loadExistingPaymentMethods() async {
        guard let accountId else { return }
        
        do {
            let (paymentMethodResponse, _) = try await PaymentMethodsAPI.getPaymentMethodsWithCustomer(customerId: accountId)
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
                                                                              customer: accountId,
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
                                                                             customer: accountId,
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
