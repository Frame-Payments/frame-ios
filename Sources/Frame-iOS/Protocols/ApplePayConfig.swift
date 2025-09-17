//
//  ApplePayConfig.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/11/25.
//

import Foundation
import PassKit

public struct ApplePayConfig: Sendable {
    public let merchantIdentifier: String
    public let countryCode: String
    public let currencyCode: String
    public let supportedNetworks: [PKPaymentNetwork]
    public let merchantCapabilities: PKMerchantCapability

    public init(
        merchantIdentifier: String,
        countryCode: String,
        currencyCode: String,
        supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex, .discover],
        merchantCapabilities: PKMerchantCapability = [.threeDSecure, .debit, .credit]
    ) {
        self.merchantIdentifier = merchantIdentifier
        self.countryCode = countryCode
        self.currencyCode = currencyCode
        self.supportedNetworks = supportedNetworks
        self.merchantCapabilities = merchantCapabilities
    }
}

public protocol ApplePaySummaryProviding: AnyObject {
    func paymentSummaryItems() -> [PKPaymentSummaryItem]
    func shippingMethods() -> [PKShippingMethod]
}

// Reusable/Basic Summary Provider
final class ApplePayCartProvider: ApplePaySummaryProviding {
    let subtotal: PKPaymentSummaryItem
    let tax: PKPaymentSummaryItem
    let total: PKPaymentSummaryItem
    
    init(subtotal: PKPaymentSummaryItem, tax: PKPaymentSummaryItem, total: PKPaymentSummaryItem) {
        self.subtotal = subtotal
        self.tax = tax
        self.total = total
    }
    
    func paymentSummaryItems() -> [PKPaymentSummaryItem] {
        return [subtotal, tax, total]
    }

    func shippingMethods() -> [PKShippingMethod] { [] }
}

public enum ApplePayResult {
    case success(token: PKPaymentToken)
    case cancelled
    case failed(error: Error)
}
