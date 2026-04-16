//
//  ApplePayAPI.swift
//  Frame-iOS
//
//  Created by Frame Payments on 4/2/25.

import Foundation
import PassKit

private struct PKPaymentDataJSON: Decodable {
    let version: String
    let data: String
    let signature: String
    let header: PKPaymentDataHeaderJSON

    struct PKPaymentDataHeaderJSON: Decodable {
        let ephemeralPublicKey: String
        let publicKeyHash: String
        let transactionId: String
    }
}

// MARK: - ApplePayAPI

public class ApplePayAPI {

    public static func createPaymentMethodWithCustomerId(
        from payment: PKPayment,
        customerId: String? = nil
    ) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?) {
        let request = try await buildAttestedRequest(from: payment, customerId: customerId, accountId: nil)
        let endpoint = PaymentMethodEndpoints.createPaymentMethod
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, usePublishableKey: true)
        if let data, let decoded = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return (decoded, error)
        }
        return (nil, error)
    }

    public static func createPaymentMethodWithAccountId(
        from payment: PKPayment,
        accountId: String? = nil
    ) async throws -> (FrameObjects.PaymentMethod?, NetworkingError?) {
        let request = try await buildAttestedRequest(from: payment, customerId: nil, accountId: accountId)
        let endpoint = PaymentMethodEndpoints.createPaymentMethod
        let requestBody = try? FrameNetworking.shared.jsonEncoder.encode(request)

        let (data, error) = try await FrameNetworking.shared.performDataTask(endpoint: endpoint, requestBody: requestBody, usePublishableKey: true)
        if let data, let decoded = try? FrameNetworking.shared.jsonDecoder.decode(FrameObjects.PaymentMethod.self, from: data) {
            return (decoded, error)
        }
        return (nil, error)
    }

    // MARK: - Request builder

    static func buildRequest(
        from payment: PKPayment,
        customerId: String?,
        accountId: String?,
        deviceKeyId: String? = nil,
        deviceAssertion: String? = nil,
        deviceClientData: String? = nil
    ) throws -> ApplePayRequests.CreateApplePayPaymentMethodRequest {
        // Decode the encrypted payment data JSON from PKPaymentToken
        let paymentDataJSON = try decodePaymentData(payment.token.paymentData)

        let header = ApplePayRequests.ApplePayPaymentDataHeader(
            ephemeralPublicKey: paymentDataJSON.header.ephemeralPublicKey,
            publicKeyHash: paymentDataJSON.header.publicKeyHash,
            transactionId: paymentDataJSON.header.transactionId
        )

        let paymentData = ApplePayRequests.ApplePayPaymentData(
            version: paymentDataJSON.version,
            data: paymentDataJSON.data,
            signature: paymentDataJSON.signature,
            header: header
        )

        let paymentMethod = ApplePayRequests.ApplePayPaymentMethod(
            displayName: payment.token.paymentMethod.displayName ?? "",
            network: payment.token.paymentMethod.network?.rawValue ?? "",
            type: paymentMethodTypeString(payment.token.paymentMethod.type)
        )

        let billingContact = buildBillingContact(payment.billingContact)

        let tokenDetails = ApplePayRequests.ApplePayTokenDetails(
            token: ApplePayRequests.ApplePayToken(
                paymentData: paymentData,
                paymentMethod: paymentMethod,
                transactionIdentifier: payment.token.transactionIdentifier
            ),
            billingContact: billingContact
        )

        let applePayDetails = ApplePayRequests.ApplePayDetails(
            requestId: UUID().uuidString,
            payerName: payment.billingContact?.name.map { formatName($0) },
            payerEmail: payment.billingContact?.emailAddress,
            details: tokenDetails,
            deviceKeyId: deviceKeyId,
            deviceAssertion: deviceAssertion,
            deviceClientData: deviceClientData
        )

        let wallet = ApplePayRequests.ApplePayWallet(applePay: applePayDetails)

        return ApplePayRequests.CreateApplePayPaymentMethodRequest(
            wallet: wallet,
            customer: customerId,
            account: accountId
        )
    }

    // MARK: - Device Attestation

    /// Generates a device assertion and builds the request with attestation data.
    /// The device must be attested before calling this method.
    static func buildAttestedRequest(
        from payment: PKPayment,
        customerId: String?,
        accountId: String?
    ) async throws -> ApplePayRequests.CreateApplePayPaymentMethodRequest {
        let assertion = try await DeviceAttestationManager.shared.generateAssertionForPayment(
            paymentData: payment.token.paymentData
        )

        return try buildRequest(
            from: payment,
            customerId: customerId,
            accountId: accountId,
            deviceKeyId: assertion.keyId,
            deviceAssertion: assertion.assertion,
            deviceClientData: assertion.clientData
        )
    }

    // MARK: - Helpers

    private static func decodePaymentData(_ data: Data) throws -> PKPaymentDataJSON {
        do {
            return try JSONDecoder().decode(PKPaymentDataJSON.self, from: data)
        } catch {
            throw NetworkingError.decodingFailed
        }
    }

    private static func paymentMethodTypeString(_ type: PKPaymentMethodType) -> String {
        switch type {
        case .credit: return "credit"
        case .debit: return "debit"
        case .prepaid: return "prepaid"
        case .store: return "store"
        default: return "unknown"
        }
    }

    private static func buildBillingContact(_ contact: PKContact?) -> ApplePayRequests.ApplePayBillingContact? {
        guard let contact else { return nil }
        let postalAddress = contact.postalAddress
        return ApplePayRequests.ApplePayBillingContact(
            addressLines: postalAddress.map { [$0.street].filter { !$0.isEmpty } },
            locality: postalAddress?.city,
            administrativeArea: postalAddress?.state,
            postalCode: postalAddress?.postalCode,
            countryCode: postalAddress?.isoCountryCode
        )
    }

    private static func formatName(_ name: PersonNameComponents) -> String {
        [name.givenName, name.familyName].compactMap { $0 }.joined(separator: " ")
    }
}
