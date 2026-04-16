//
//  FrameApplePayViewModel.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/2/25.
//

import Foundation
import PassKit

@MainActor
public class FrameApplePayViewModel: NSObject, ObservableObject {

    public enum PaymentMethodOwner {
        case customer(String)
        case account(String)
    }

    // MARK: - Published state

    @Published var isProcessing: Bool = false

    let amount: Int
    let currency: String
    let owner: PaymentMethodOwner
    let merchantId: String

    var completion: ((Result<FrameObjects.ChargeIntent, Error>) -> Void)?

    public init(amount: Int,
         currency: String,
         owner: PaymentMethodOwner,
         merchantId: String,
         completion: ((Result<FrameObjects.ChargeIntent, Error>) -> Void)? = nil) {
        self.amount = amount
        self.currency = currency
        self.owner = owner
        self.merchantId = merchantId
        self.completion = completion
    }

    /// Returns true if the device can make Apple Pay payments with at least one of the supported networks.
    static func canMakePayments() -> Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
    }

    /// Presents the Apple Pay sheet. Device attestation must have already
    /// completed at SDK init — the button is hidden until that succeeds.
    func presentApplePay() {
        guard !isProcessing else { return }
        isProcessing = true

        Task {
            defer { isProcessing = false }

            let request = buildPaymentRequest()
            let controller = PKPaymentAuthorizationController(paymentRequest: request)
            controller.delegate = self
            await controller.present()
        }
    }

    private static let supportedNetworks: [PKPaymentNetwork] = [
        .visa, .masterCard, .amex, .discover, .JCB
    ]

    private func buildPaymentRequest() -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantId
        request.supportedNetworks = Self.supportedNetworks
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US"
        request.currencyCode = currency.uppercased()
        request.requiredBillingContactFields = [.postalAddress, .name, .emailAddress]
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(
                label: "Total",
                amount: NSDecimalNumber(value: Double(amount) / 100.0)
            )
        ]
        return request
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension FrameApplePayViewModel: PKPaymentAuthorizationControllerDelegate {

    /// Called when the user authorizes payment. Uses the async overload available on iOS 16+.
    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment
    ) async -> PKPaymentAuthorizationResult {
        isProcessing = true
        defer { isProcessing = false }

        do {
            // 1. Create a Frame PaymentMethod from the Apple Pay token
            let (paymentMethod, methodError): (FrameObjects.PaymentMethod?, NetworkingError?)
            switch owner {
            case .customer(let customerId):
                (paymentMethod, methodError) = try await ApplePayAPI.createPaymentMethodWithCustomerId(
                    from: payment,
                    customerId: customerId
                )
            case .account(let accountId):
                (paymentMethod, methodError) = try await ApplePayAPI.createPaymentMethodWithAccountId(
                    from: payment,
                    accountId: accountId
                )
            }
            guard let paymentMethodId = paymentMethod?.id else {
                completion?(.failure(methodError ?? NetworkingError.unknownError))
                return PKPaymentAuthorizationResult(status: .failure, errors: nil)
            }

            // 2. Create and confirm a ChargeIntent with the payment method
            let request: ChargeIntentsRequests.CreateChargeIntentRequest
            switch owner {
            case .customer(let customerId):
                request = ChargeIntentsRequests.CreateChargeIntentRequest(
                    amount: amount,
                    currency: currency,
                    customer: customerId,
                    paymentMethod: paymentMethodId,
                    confirm: true,
                    authorizationMode: .automatic
                )
            case .account(let accountId):
                request = ChargeIntentsRequests.CreateChargeIntentRequest(
                    amount: amount,
                    currency: currency,
                    account: accountId,
                    paymentMethod: paymentMethodId,
                    confirm: true,
                    authorizationMode: .automatic
                )
            }
            let (chargeIntent, chargeError) = try await ChargeIntentsAPI.createChargeIntent(request: request)

            if let chargeIntent {
                completion?(.success(chargeIntent))
                return PKPaymentAuthorizationResult(status: .success, errors: nil)
            } else {
                completion?(.failure(chargeError ?? NetworkingError.unknownError))
                return PKPaymentAuthorizationResult(status: .failure, errors: nil)
            }
        } catch {
            completion?(.failure(error))
            return PKPaymentAuthorizationResult(status: .failure, errors: nil)
        }
    }

    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
}
