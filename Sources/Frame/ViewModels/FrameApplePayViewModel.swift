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

    /// Drives whether the Apple Pay sheet completes by creating a charge (`.charge`)
    /// or only attaches the wallet card to the customer/account (`.addToOwner`).
    public enum FrameApplePayMode {
        case charge(amount: Int, currency: String)
        case addToOwner
    }

    /// Result delivered to the host app's completion handler.
    ///
    /// `.charge` carries the id of the resulting resource:
    /// - `.customer(...)` owner produces a `ChargeIntent` id
    /// - `.account(...)` owner produces a `Transfer` id
    /// Callers infer the resource type from the owner they passed in.
    ///
    /// `.paymentMethod` carries a persisted wallet PaymentMethod for use in AddPaymentMethod flows.
    public enum FrameApplePayResult {
        case charge(id: String)
        case paymentMethod(FrameObjects.PaymentMethod)
    }

    // MARK: - Published state

    @Published var isProcessing: Bool = false

    let mode: FrameApplePayMode
    let owner: PaymentMethodOwner

    var completion: ((Result<FrameApplePayResult, Error>) -> Void)?

    public init(mode: FrameApplePayMode,
                owner: PaymentMethodOwner,
                completion: ((Result<FrameApplePayResult, Error>) -> Void)? = nil) {
        self.mode = mode
        self.owner = owner
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
        request.merchantIdentifier = FrameNetworking.shared.applePayMerchantId ?? ""
        request.supportedNetworks = Self.supportedNetworks
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US"
        request.requiredBillingContactFields = [.postalAddress, .name, .emailAddress]

        switch mode {
        case .charge(let amount, let currency):
            request.currencyCode = currency.uppercased()
            request.paymentSummaryItems = [
                PKPaymentSummaryItem(
                    label: "Total",
                    amount: NSDecimalNumber(value: Double(amount) / 100.0)
                )
            ]
        case .addToOwner:
            // Wallet-only mode: present a $0 pending summary item so Apple's sheet still
            // satisfies the UX requirement of a labeled total without charging the user.
            request.currencyCode = "USD"
            request.paymentSummaryItems = [
                PKPaymentSummaryItem(
                    label: "Card Verification",
                    amount: .zero,
                    type: .pending
                )
            ]
        }
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
            guard let paymentMethod else {
                completion?(.failure(methodError ?? NetworkingError.unknownError))
                return PKPaymentAuthorizationResult(status: .failure, errors: nil)
            }
            let paymentMethodId = paymentMethod.id

            switch mode {
            case .addToOwner:
                completion?(.success(.paymentMethod(paymentMethod)))
                return PKPaymentAuthorizationResult(status: .success, errors: nil)

            case .charge(let amount, let currency):
                // 2. Create the charge. Customer owners use the legacy ChargeIntent flow;
                // account owners use the account-scoped Transfer flow. Both deliver an id
                // back to the caller, who knows which resource type to expect based on
                // the owner they passed in.
                switch owner {
                case .customer(let customerId):
                    let request = ChargeIntentsRequests.CreateChargeIntentRequest(
                        amount: amount,
                        currency: currency,
                        customer: customerId,
                        paymentMethod: paymentMethodId,
                        confirm: true,
                        authorizationMode: .automatic
                    )
                    let (chargeIntent, chargeError) = try await ChargeIntentsAPI.createChargeIntent(request: request)

                    if let chargeIntent {
                        completion?(.success(.charge(id: chargeIntent.id)))
                        return PKPaymentAuthorizationResult(status: .success, errors: nil)
                    } else {
                        completion?(.failure(chargeError ?? NetworkingError.unknownError))
                        return PKPaymentAuthorizationResult(status: .failure, errors: nil)
                    }

                case .account(let accountId):
                    let request = TransferRequests.CreateTransferRequest(
                        amount: amount,
                        accountId: accountId,
                        currency: currency,
                        sourcePaymentMethodId: paymentMethodId
                    )
                    let (transfer, transferError) = try await TransfersAPI.createTransfer(request: request)

                    if let transfer {
                        completion?(.success(.charge(id: transfer.id)))
                        return PKPaymentAuthorizationResult(status: .success, errors: nil)
                    } else {
                        completion?(.failure(transferError ?? NetworkingError.unknownError))
                        return PKPaymentAuthorizationResult(status: .failure, errors: nil)
                    }
                }
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
