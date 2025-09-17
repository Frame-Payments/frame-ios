//
//  ApplePayButtonView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/11/25.
//

import Foundation
import SwiftUI
import PassKit

public struct ApplePayButtonView: View {
    private let config: ApplePayConfig
    private weak var provider: ApplePaySummaryProviding?
    private let onResult: (ApplePayResult) -> Void
    private let buttonType: PKPaymentButtonType
    private let buttonStyle: PKPaymentButtonStyle

    public init(
        config: ApplePayConfig,
        provider: ApplePaySummaryProviding,
        buttonType: PKPaymentButtonType = .buy,
        buttonStyle: PKPaymentButtonStyle = .automatic,
        onResult: @escaping (ApplePayResult) -> Void
    ) {
        self.config = config
        self.provider = provider
        self.onResult = onResult
        self.buttonType = buttonType
        self.buttonStyle = buttonStyle
    }

    public var body: some View {
        ApplePayButtonRepresentable(
            config: config,
            provider: provider,
            onResult: onResult,
            buttonType: buttonType,
            buttonStyle: buttonStyle
        )
        .frame(height: 50)
        .accessibilityLabel(Text("Apple Pay"))
    }
}

final class ApplePayCoordinator: NSObject, PKPaymentAuthorizationControllerDelegate {
    let config: ApplePayConfig
    weak var provider: ApplePaySummaryProviding?
    let onResult: (ApplePayResult) -> Void

    init(config: ApplePayConfig,
         provider: ApplePaySummaryProviding?,
         onResult: @escaping (ApplePayResult) -> Void) {
        self.config = config
        self.provider = provider
        self.onResult = onResult
    }

    func start() {
        guard PKPaymentAuthorizationController.canMakePayments(usingNetworks: config.supportedNetworks) else {
            onResult(.failed(error: NSError(domain: "ApplePay", code: 1, userInfo: [NSLocalizedDescriptionKey: "Device not eligible for Apple Pay or no supported cards."])))
            return
        }

        let request = PKPaymentRequest()
        request.merchantIdentifier = config.merchantIdentifier
        request.countryCode = config.countryCode
        request.currencyCode = config.currencyCode
        request.merchantCapabilities = config.merchantCapabilities
        request.supportedNetworks = config.supportedNetworks

        if let provider = provider {
            request.paymentSummaryItems = provider.paymentSummaryItems()
            let shipping = provider.shippingMethods()
            if !shipping.isEmpty {
                request.shippingMethods = shipping
                request.requiredShippingContactFields = [.postalAddress, .name, .emailAddress, .phoneNumber]
            }
        }

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self
        controller.present { presented in
            if !presented {
                self.onResult(.failed(error: NSError(domain: "ApplePay", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to present Apple Pay sheet."])))
            }
        }
    }

    // MARK: - PKPaymentAuthorizationControllerDelegate

    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didAuthorizePayment payment: PKPayment,
                                        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {

        onResult(.success(token: payment.token))
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            self.onResult(.cancelled)
        }
    }
}

struct ApplePayButtonRepresentable: UIViewRepresentable {
    let config: ApplePayConfig
    weak var provider: ApplePaySummaryProviding?
    let onResult: (ApplePayResult) -> Void
    let buttonType: PKPaymentButtonType
    let buttonStyle: PKPaymentButtonStyle

    func makeCoordinator() -> ApplePayCoordinator {
        ApplePayCoordinator(config: config, provider: provider, onResult: onResult)
    }

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: buttonStyle)
        button.addAction(
            UIAction(handler: { _ in
                self.tap()
            }), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    private func tap() {
        makeCoordinator().start()
    }
}
