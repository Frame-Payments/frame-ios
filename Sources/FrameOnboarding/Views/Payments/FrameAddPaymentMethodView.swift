//
//  FrameAddPaymentMethodView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/9/26.
//

import SwiftUI
import Frame

/// A standalone "add a payment method" screen that can be presented outside the onboarding flow.
///
/// Use this when a merchant wants to prompt an existing user to add a card at an arbitrary point in
/// their app, rather than as a step inside ``OnboardingContainerView``. The screen presents the same
/// card, billing-address, and Apple Pay inputs used during onboarding.
///
/// ```swift
/// .sheet(isPresented: $showAddCard) {
///     FrameAddPaymentMethodView(clientSecret: secret, accountId: accountId) { result in
///         if case .completed(let id) = result { /* refresh payment methods */ }
///     }
/// }
/// ```
public struct FrameAddPaymentMethodView: View {
    @StateObject private var viewModel: OnboardingContainerViewModel
    private let onResult: (FrameResult) -> Void
    private let onboardingClientSecret: String?

    /// Guards against emitting `.cancelled` on dismiss when a method was already added.
    @State private var didFinish: Bool = false

    /// Creates a standalone add-payment-method screen.
    ///
    /// - Parameters:
    ///   - clientSecret: The onboarding-session token (`onb_sess_…`) minted by your server
    ///     (`POST /v1/onboarding_sessions`) and handed to your app. While this screen is presented
    ///     every request authenticates with this token, scoping it to a single account. Pass `nil`
    ///     only for legacy integrations that still authenticate with a secret key.
    ///   - accountId: The Frame account ID the new payment method is attached to.
    ///   - onResult: Closure called with a ``FrameResult`` when the screen finishes or is cancelled.
    public init(clientSecret: String? = nil,
                accountId: String,
                onResult: @escaping (FrameResult) -> Void = { _ in }) {
        self.onboardingClientSecret = clientSecret
        self.onResult = onResult
        self._viewModel = StateObject(wrappedValue: OnboardingContainerViewModel(accountId: accountId,
                                                                                 requiredCapabilities: []))
    }

    /// The wrapped onboarding add-payment-method screen, bound to a session and result callback.
    public var body: some View {
        // Present standalone only — ``OnboardingContainerView`` already applies these two.
        AddPaymentMethodView(onboardingContainerViewModel: viewModel,
                             onlyAddressVerification: false)
            .keyboardDoneToolbar()
            .frameToastOverlay()
            .refreshesSonarSession(accountId: viewModel.accountId)
            .onAppear {
                if let onboardingClientSecret {
                    FrameNetworking.shared.beginOnboardingSession(clientSecret: onboardingClientSecret)
                }
            }
            .onChange(of: viewModel.selectedPaymentMethod?.id) { _, newValue in
                guard let newValue, !didFinish else { return }
                didFinish = true
                onResult(.completed(id: newValue))
            }
            .onDisappear {
                // The Apple Pay sheet covering this view fires .onDisappear without the user
                // dismissing us; it runs inside beginAction()/endAction(), so this distinguishes them.
                guard !viewModel.isPerformingAction else { return }

                // Only clear a session this view began, so we don't wipe another flow's.
                if onboardingClientSecret != nil {
                    FrameNetworking.shared.endOnboardingSession()
                }
                if !didFinish {
                    didFinish = true
                    onResult(.cancelled)
                }
            }
    }
}

#Preview {
    FrameAddPaymentMethodView(accountId: "")
}
