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
    @Published var onboardingFlow: [OnboardingFlow] = []
    @Published var progressiveSteps: [OnboardingFlow] = []
    @Published var currentStep: OnboardingFlow = .personalInformation
    @Published var requiredCapabilities: [FrameObjects.Capabilities]
    
    @Published var cardData = PaymentCardData()
    @Published var bankAccount = FrameObjects.BankAccount(accountType: .checking)
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
    @Published var termsOfServiceToken: String?
    
    @Published var proveUserInfo: ProveUserInfo?
    @Published var showProveOTPEntry: Bool = false
    @Published var pendingTwilioVerificationId: String?
    @Published var pendingTwilioVerificationAccountId: String?
    
    private var proveOTPContinuation: CheckedContinuation<String?, Never>?
    
    @Published var createdCustomerIdentity = CustomerIdentityRequest.CreateCustomerIdentityRequest(firstName: "", lastName: "", dateOfBirth: "", email: "", phoneNumber: "",
                                                                                                   ssn: "", address: FrameObjects.BillingAddress(postalCode: ""))
    
    var accountId: String?
    let formatter = ISO8601DateFormatter()
    
    init(accountId: String?, requiredCapabilities: [FrameObjects.Capabilities]) {
        self.accountId = accountId
        self.requiredCapabilities = requiredCapabilities
    }
    
    // Load existing account object to show on account page.
    func checkExistingAccount(updateCapabilies: Bool = false) async {
        guard let accountId else { return }
        do {
            let (account, _) = try await AccountsAPI.getAccountWith(accountId: accountId)
            guard let profile = account?.profile?.individual else { return }
            let profileAddress = FrameObjects.BillingAddress(city: profile.address?.city, country: profile.address?.country,
                                                             state: profile.address?.state, postalCode: profile.address?.postalCode ?? "",
                                                             addressLine1: profile.address?.addressLine1, addressLine2: profile.address?.addressLine2)
            self.createdCustomerIdentity = CustomerIdentityRequest.CreateCustomerIdentityRequest(firstName: profile.name?.firstName ?? profile.firstName ?? "",
                                                                                                 lastName: profile.name?.lastName ?? profile.lastName ?? "",
                                                                                                 dateOfBirth: profile.birthdate ?? "",
                                                                                                 email: profile.email ?? "",
                                                                                                 phoneNumber: profile.phone?.number ?? profile.phoneNumber ?? "",
                                                                                                 ssn: profile.ssnLastFour ?? "",
                                                                                                 address: profileAddress)
            
            guard updateCapabilies else { return }
            if let capabilities = account?.capabilities {
                let accountCapabilities = capabilities.compactMap({ FrameObjects.Capabilities(rawValue: $0.name) })
                if Set(accountCapabilities).isSuperset(of: Set(requiredCapabilities)) {
                    // Check what needs to be completed
                    self.updateCapabilitiesBasedOnCompletion(accountCapabilities: capabilities)
                } else {
                    // Update capabilities to match what is required by merchant
                    let request = CapabilityRequest.RequestCapabilitiesRequest(capabilities: requiredCapabilities)
                    let (capabilities, _) = try await CapabilitiesAPI.requestCapabilities(accountId: accountId, request: request)
                    // Then recheck account.
                    await self.checkExistingAccount()
                }
            }
        } catch let error {
            print(error)
        }
    }
    
    func updateCapabilitiesBasedOnCompletion(accountCapabilities: [FrameObjects.Capability]) {
        // Check to see which capabilites are completed, skip any that are not needed.
        accountCapabilities.forEach { capability in
            let requiredCapability = FrameObjects.Capabilities(rawValue: capability.name)
            if capability.currentlyDue?.isEmpty == true {
                self.requiredCapabilities.removeAll(where: { $0 == requiredCapability })
            }
        }
        self.updateOnboardingFlow()
    }
    
    func updateOnboardingFlow() {
        let onboardingSet = Set(requiredCapabilities.map { $0.onboardingStep })
        var onboardingArray = Array(onboardingSet).sorted(by: { $0.rawValue < $1.rawValue })
        onboardingArray.append(.verificationSubmitted)
        
        self.onboardingFlow = onboardingArray
        self.currentStep = onboardingArray.first ?? .personalInformation
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
                                                                           birthdate: createdCustomerIdentity.dateOfBirth,
                                                                           ssn: createdCustomerIdentity.ssn)
            let termsOfService = FrameObjects.AccountTermsOfService(token: termsOfServiceToken, ipAddress: SiftManager.getIPAddress(), acceptedAt: formatter.string(from: Date()))
            let profile = AccountRequest.CreateAccountProfile(business: nil, individual: individualAccount)
            let request = AccountRequest.CreateAccountRequest(accountType: .individual, termsOfService: termsOfService, profile: profile, capabilities: requiredCapabilities)
            let (account, _) = try await AccountsAPI.createAccount(request: request)
            
            guard let account else { return }
            self.accountId = account.id
        } catch let error {
            print(error)
        }
    }
    
    func createEmptyIndividualAccount(phoneNumber: String, dateOfBirth: String) async {
        do {
            let individualAccount = AccountRequest.CreateIndividualAccount(name: FrameObjects.AccountNameInfo(firstName: "", lastName: ""),
                                                                           email: "",
                                                                           phone: FrameObjects.AccountPhoneNumber(number: phoneNumber, countryCode: "+1"),
                                                                           address: nil, birthdate: dateOfBirth, ssn: nil)
            let profile = AccountRequest.CreateAccountProfile(business: nil, individual: individualAccount)
            let termsOfService = FrameObjects.AccountTermsOfService(token: termsOfServiceToken, ipAddress: SiftManager.getIPAddress(), acceptedAt:formatter.string(from: Date()))
            let request = AccountRequest.CreateAccountRequest(accountType: .individual, termsOfService: termsOfService, profile: profile, capabilities: requiredCapabilities)
            let (account, _) = try await AccountsAPI.createAccount(request: request)
            
            guard let account else { return }
            self.accountId = account.id
            return
        } catch let error {
            print(error)
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
                                                                           phoneNumber: createdCustomerIdentity.phoneNumber,
                                                                           phoneCountryCode: "+1",
                                                                           address: createdCustomerIdentity.address,
                                                                           birthdate: createdCustomerIdentity.dateOfBirth,
                                                                           ssnLast4: createdCustomerIdentity.ssn)
            let request = AccountRequest.UpdateAccountRequest(profile: AccountRequest.UpdateAccountProfile(business: nil, individual: individualAccount))
            try await AccountsAPI.updateAccountWith(accountId: accountId, request: request)
        } catch let error {
            print(error)
        }
    }

    func generateTermsOfServiceToken() async {
        do {
            let (response, _) = try await TermsOfServiceAPI.createToken()
            self.termsOfServiceToken = response?.token
        } catch let error {
            print(error)
        }
    }

    // Start Phone Verification OTP Flow (Prove or Twilio)
    func sendOTPVerification(phoneNumber: String, dateOfBirth: String) async {
        if accountId == nil {
            await createEmptyIndividualAccount(phoneNumber: phoneNumber, dateOfBirth: dateOfBirth)
        }
        guard let accountId else { return }

        do {
            let (response, _) = try await PhoneOTPVerificationAPI.createVerification(accountId: accountId, phoneNumber: phoneNumber, dateOfBirth: dateOfBirth)
            guard let response else { return }

            if let proveAuthToken = response.proveAuthToken {
                // Prove flow: run SDK, then confirm with verificationId from create response
                let confirmHandler: ProveConfirmHandler = { accountId, verificationId in
                    let (_, networkingError) = try await PhoneOTPVerificationAPI.confirmVerification(accountId: accountId, verificationId: verificationId)
                    if let networkingError { throw networkingError }
                }
                let proveService = ProveAuthService(accountId: accountId, verificationId: response.id, confirmHandler: confirmHandler, otpProvider: { [weak self] in
                    await self?.requestProveOTP()
                })
                _ = try await proveService.authenticateWith(authToken: proveAuthToken)
                self.proveUserInfo = ProveUserInfo(firstName: "", lastName: "")
                await checkExistingAccount()
            } else {
                // Twilio flow: SMS sent, show OTP entry screen
                pendingTwilioVerificationId = response.id
                pendingTwilioVerificationAccountId = accountId
            }
        } catch let error {
            print(error)
        }
    }

    /// Confirm Twilio OTP when user submits code on SecurePMVerificationView (phone type).
    func confirmTwilioOTP(code: String) async {
        guard let accountId = pendingTwilioVerificationAccountId,
              let verificationId = pendingTwilioVerificationId else { return }

        do {
            let (_, networkingError) = try await PhoneOTPVerificationAPI.confirmVerification(accountId: accountId, verificationId: verificationId, code: code)
            if let networkingError { throw networkingError }
            self.proveUserInfo = ProveUserInfo(firstName: "", lastName: "")
            self.pendingTwilioVerificationId = nil
            self.pendingTwilioVerificationAccountId = nil
            await checkExistingAccount()
        } catch let error {
            print(error)
        }
    }
    
    /// Called by otpProvider when Prove needs OTP. Suspends until user submits or cancels.
    func requestProveOTP() async -> String? {
        await withCheckedContinuation { continuation in
            self.proveOTPContinuation = continuation
            self.showProveOTPEntry = true
        }
    }
    
    /// Called when user submits OTP from the Prove OTP sheet.
    func submitProveOTP(_ code: String) {
        proveOTPContinuation?.resume(returning: code)
        proveOTPContinuation = nil
        showProveOTPEntry = false
    }
    
    /// Called when user cancels the Prove OTP sheet.
    func cancelProveOTP() {
        proveOTPContinuation?.resume(returning: nil)
        proveOTPContinuation = nil
        showProveOTPEntry = false
    }
    
    // Load existing Payment Methods for customer
    func loadExistingPaymentMethods() async {
        guard let accountId else { return }
        
        do {
            let (paymentMethodResponse, _) = try await PaymentMethodsAPI.getPaymentMethodsWithAccount(accountId: accountId)
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
                                                                              customer: nil,
                                                                              account: accountId,
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
    
    // Update an existing payment method with a billing address
    func updatePaymentMethod() async {
        guard let paymentMethodId = selectedPayoutMethod?.id else { return }
        
        do {
            let request = PaymentMethodRequest.UpdatePaymentMethodRequest(billing: createdBillingAddress)
            let (paymentMethod, _) = try await PaymentMethodsAPI.updatePaymentMethodWith(paymentMethodId: paymentMethodId, request: request)
            
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
                                                                             customer: nil,
                                                                             account: accountId,
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
    
    func checkIfCustomerCanContinueWithPaymentMethod(onlyAddress: Bool = false) -> Bool {
        guard createdBillingAddress.addressLine1 != nil, createdBillingAddress.city != nil, createdBillingAddress.state != nil, !createdBillingAddress.postalCode.isEmpty else { return false }
        if !onlyAddress {
            guard cardData.isValid else { return false }
        }
        return true
    }
    
    func checkIfCustomerCanContinueWithPayoutMethod() -> Bool {
        guard createdBillingAddress.addressLine1 != nil, createdBillingAddress.city != nil, createdBillingAddress.state != nil, !createdBillingAddress.postalCode.isEmpty else { return false }
        guard bankAccount.accountNumber != nil, bankAccount.routingNumber != nil, bankAccount.accountType != nil else { return false }
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
