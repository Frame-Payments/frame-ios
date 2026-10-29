//
//  ContentViewModel.swift
//  FrameExample-iOS
//
//  Created by Frame Payments on 1/17/25.
//  Copyright © 2025 Frame Payments. All rights reserved.
//

import Foundation
import Frame

class ContentViewModel: ObservableObject, @unchecked Sendable {
    /// The onboarding-session token (`onb_sess_…`) minted for the demo flow, if any.
    @Published var onboardingClientSecret: String?
    
    // Replace with your Apple Pay merchant ID registered in your entitlements
    let applePayMerchantId: String = "merchant.com.yourapp"
    // Replace with an accountID from your dashboard.
    var accountId: String = "ENTER_AN_ACCOUNT_ID"
    
    init() {
        // Unit tests launch this app as their host. Skip setup so it doesn't hit the network mid-run.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        // The SDK is publishable-key first: pass your publishable key (pk_) here. Secret keys
        // grant full merchant privileges and must not ship in an app binary — serve sk_ from your
        // backend. This example sets a secret key only to mint session tokens without a backend;
        // production apps should omit it.
        FrameNetworking.shared.initialize(publishableKey: "ENTER_PUBLISHABLE_KEY_HERE",
                                          secretKey: "ENTER_SECRET_KEY_HERE",
                                          accountId: accountId == "ENTER_AN_ACCOUNT_ID" ? nil : accountId,
//                                          theme: FrameTheme(
//                                              colors: .init(primaryButton: .purple, error: .orange),
//                                              fonts: .init(title: .custom("Avenir-Black", size: 28)),
//                                              radii: .init(medium: 16)
//                                          ),
                                          applePayMerchantId: applePayMerchantId,
                                          debugMode: true)
    }

    // MARK: Onboarding session (demo / testing only)

    /// Mints an onboarding-session token (`onb_sess_…`) for the given account so the example app can
    /// exercise the onboarding flow end-to-end. Returns the token, or `nil` when minting failed.
    ///
    /// - Important: This mint exists only because the example app has no backend. Production apps
    ///   mint `POST /v1/onboarding_sessions` on their server with `sk_` and pass the client secret in.
    ///   Creating a session authenticates with your secret key, which must never ship in an app binary.
    /// - Parameters:
    ///   - accountId: The existing Frame account to onboard.
    ///   - publish: When `true` (default), stores the token for the individual demo sheets.
    ///     Business onboarding passes `false` so it keeps its own token.
    /// - Returns: The `onb_sess_…` token, or `nil` if the request failed.
    func mintOnboardingClientSecret(accountId: String, publish: Bool = true) async -> String? {
        let request = OnboardingSessionRequest.CreateOnboardingSessionRequest(
            accountId: accountId,
            steps: [.idVerification, .geoCompliance, .paymentMethod]
        )
        do {
            let (session, error) = try await OnboardingSessionsAPI.createOnboardingSession(request: request)
            if let clientSecret = session?.clientSecret, !clientSecret.isEmpty {
                if publish {
                    await MainActor.run { self.onboardingClientSecret = clientSecret }
                }
                return clientSecret
            } else {
                print("⚠️ Frame example: failed to mint onboarding session token. Error: \(String(describing: error))")
                return nil
            }
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
    
    /// Mints a checkout client secret (`chk_sess_…`) so the example can load a name, email, and
    /// saved cards. Returns the token, or `nil` when minting failed.
    ///
    /// - Important: This mint exists only because the example app has no backend. Production apps
    ///   mint `POST /v1/checkout_sessions` on their server with `sk_` and pass the client secret in.
    /// - Parameter accountId: The account checkout will charge.
    /// - Returns: The checkout token and its expiry, or `nil` if the request failed.
    func mintCheckoutClientSecret(
        accountId: String,
        amountCents: Int? = nil,
        currency: String = "usd"
    ) async -> FrameCheckoutClientSecret? {
        guard !accountId.isEmpty else { return nil }
        do {
            let amount = amountCents.map { FrameObjects.TransferV2Money(value: $0, currency: currency) }
            let (session, error) = try await CheckoutSessionsAPI.createCheckoutSession(accountId: accountId, amount: amount)
            if let clientSecret = session?.clientSecret, !clientSecret.isEmpty, let expiresAt = session?.expiresAt {
                return FrameCheckoutClientSecret(
                    clientSecret: clientSecret,
                    expiresAt: Date(timeIntervalSince1970: TimeInterval(expiresAt)),
                    amountCents: session?.amount?.value ?? amountCents,
                    amountCurrency: session?.amount?.currency ?? (amountCents == nil ? nil : currency)
                )
            }
            print("⚠️ Frame example: failed to mint checkout client secret. Error: \(String(describing: error))")
            return nil
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    /// Creates a payout with the example's secret key and returns the transfer id.
    ///
    /// - Important: Production apps do this on their server. `POST /v2/transfers` does not
    ///   accept `onb_sess_` or `chk_sess_` for a payout, and there is no payout session type.
    ///   Source is the account. Destination is the selected bank. The API infers `type: payout`.
    func createExamplePayout(accountId: String, amountCents: Int, paymentMethodId: String) async -> String? {
        guard !accountId.isEmpty, amountCents > 0, !paymentMethodId.isEmpty else { return nil }
        let request = TransferV2Requests.CreateTransferRequest(
            amount: .init(value: amountCents, currency: "usd"),
            source: .init(accountId: accountId),
            destination: .init(paymentMethodId: paymentMethodId)
        )
        do {
            let (transfer, error) = try await TransfersV2API.createTransfer(request: request, accountId: accountId)
            if let error {
                print("⚠️ Frame example: payout create failed. Error: \(error.toastMessage())")
                return nil
            }
            return transfer?.id
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    func createEmptyIndividualAccount(capabilities: [FrameObjects.Capabilities]) async -> String? {
        // Note: callers (e.g. sendOTPVerification) already hold the action guard. Don't double-guard.
        do {
            let individualAccount = AccountRequest.CreateIndividualAccount(name: FrameObjects.AccountNameInfo(firstName: "", lastName: ""),
                                                                           email: "newaccount@gmail.com",
                                                                           phone: FrameObjects.AccountPhoneNumber(number: "", countryCode: ""),
                                                                           address: nil,
                                                                           birthdate: nil,
                                                                           ssn: nil)
            let profile = AccountRequest.CreateAccountProfile(business: nil, individual: individualAccount)
            let request = AccountRequest.CreateAccountRequest(accountType: .individual, profile: profile, capabilities: capabilities)
            let (account, _) = try await AccountsAPI.createAccount(request: request)
            guard let account else { return nil }
            return account.id
        } catch let error {
            print(error)
            return nil
        }
    }

    /// Creates a business account with `sk_` so the example can open business onboarding.
    /// The hosted flow requires an existing business account; it does not create one.
    func createEmptyBusinessAccount(capabilities: [FrameObjects.Capabilities]) async -> (accountId: String?, errorMessage: String?) {
        do {
            let suffix = String(UUID().uuidString.prefix(8)).lowercased()
            let business = AccountRequest.CreateBusinessAccount(
                legalBusinessName: "Example Business",
                businessType: "private_corporation",
                email: "business-\(suffix)@example.com"
            )
            let profile = AccountRequest.CreateAccountProfile(business: business, individual: nil)
            let request = AccountRequest.CreateAccountRequest(accountType: .business, profile: profile, capabilities: capabilities)
            let (account, error) = try await AccountsAPI.createAccount(request: request)
            if let error {
                let message = error.toastMessage()
                print("⚠️ Frame example: failed to create business account. Error: \(message)")
                return (nil, message)
            }
            guard let accountId = account?.id else {
                return (nil, "Could not create a business account.")
            }
            return (accountId, nil)
        } catch {
            print(error)
            return (nil, error.localizedDescription)
        }
    }
}
