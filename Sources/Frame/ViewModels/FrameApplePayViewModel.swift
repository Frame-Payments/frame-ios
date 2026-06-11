//
//  FrameApplePayViewModel.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/2/25.
//

import Foundation
import PassKit

/// View-model that drives the Apple Pay sheet and processes the resulting payment
/// or payment-method attachment on behalf of the host app.
///
/// Instantiate this object with the desired ``FrameApplePayMode`` and
/// ``PaymentMethodOwner``, then pass it to `FrameApplePayButton` (or call
/// `presentApplePay()` directly) to begin the flow. Results are delivered via
/// the `completion` closure.
@MainActor
public class FrameApplePayViewModel: NSObject, ObservableObject {

    /// Identifies the entity that will own the resulting payment method.
    public enum PaymentMethodOwner {
        /// A Frame customer, identified by their customer ID string.
        case customer(String)
        /// A Frame connected account, identified by their account ID string.
        case account(String)
    }

    /// Drives whether the Apple Pay sheet completes by creating a charge (`.charge`)
    /// or only attaches the wallet card to the customer/account (`.addToOwner`).
    public enum FrameApplePayMode {
        /// Charge the given `amount` (in the currency's smallest unit) in the specified `currency`.
        case charge(amount: Int, currency: String)
        /// Attach the Apple Pay wallet card to the owner without charging it.
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
        /// A charge was created successfully; `id` is the ChargeIntent or Transfer identifier.
        case charge(id: String)
        /// A payment method was saved successfully without charging the owner.
        case paymentMethod(FrameObjects.PaymentMethod)
    }

    // MARK: - Published state

    /// Indicates whether an Apple Pay authorization or network request is in progress.
    @Published var isProcessing: Bool = false

    /// The mode that determines whether the sheet charges the user or only saves their card.
    let mode: FrameApplePayMode

    /// The customer or account that will own the resulting payment method or charge.
    let owner: PaymentMethodOwner

    /// Optional closure called with the final success or failure result after the Apple Pay flow completes.
    var completion: ((Result<FrameApplePayResult, Error>) -> Void)?

    /// Creates a new `FrameApplePayViewModel`.
    ///
    /// - Parameters:
    ///   - mode: Controls whether the sheet creates a charge or only attaches the wallet card.
    ///   - owner: The customer or account that will own the resulting resource.
    ///   - completion: Called on the main actor with the success or failure result after the flow ends.
    public init(mode: FrameApplePayMode,
                owner: PaymentMethodOwner,
                completion: ((Result<FrameApplePayResult, Error>) -> Void)? = nil) {
        self.mode = mode
        self.owner = owner
        self.completion = completion
    }

    /// Checks whether the device is capable of making Apple Pay payments on a supported network.
    ///
    /// - Returns: `true` if the device can make payments using at least one of the SDK's supported networks; `false` otherwise.
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

    /// The card networks accepted by this SDK's Apple Pay integration.
    private static let supportedNetworks: [PKPaymentNetwork] = [
        .visa, .masterCard, .amex, .discover, .JCB
    ]

    /// Constructs a `PKPaymentRequest` populated from the current `mode` and SDK merchant configuration.
    ///
    /// - Returns: A fully configured `PKPaymentRequest` ready to be passed to `PKPaymentAuthorizationController`.
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
                if methodError?.isAssertionRejection == true {
                    DeviceAttestationManager.shared.resetAttestation()
                }
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

    /// Dismisses the Apple Pay sheet after the flow completes or is cancelled.
    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
}
