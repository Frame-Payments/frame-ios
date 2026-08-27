//
//  FrameSelectPayoutMethodView.swift
//  Frame-iOS
//

import SwiftUI
import Frame

/// A standalone "choose the primary payout account" screen that can be presented outside onboarding.
///
/// Lists the account's saved ACH payout methods, lets the applicant add a new one, and elects the
/// chosen method as the account's payout destination. Where ``FrameAddPayoutMethodView`` only adds
/// a bank, this screen also makes it primary.
///
/// ```swift
/// .sheet(isPresented: $showPayoutSettings) {
///     FrameSelectPayoutMethodView(clientSecret: secret, accountId: accountId) { result in
///         if case .completed(let id) = result { /* id is now the primary payout method */ }
///     }
/// }
/// ```
public struct FrameSelectPayoutMethodView: View {
    @StateObject private var viewModel: OnboardingContainerViewModel
    private let onResult: (FrameResult) -> Void
    private let onboardingClientSecret: String?

    /// Guards against emitting `.cancelled` on dismiss once an election has succeeded.
    @State private var didFinish: Bool = false

    /// Creates a standalone select-payout-method screen.
    ///
    /// - Parameters:
    ///   - clientSecret: The onboarding-session token (`onb_sess_…`) minted by your server
    ///     (`POST /v1/onboarding_sessions`). Electing a payout method requires a caller scoped to
    ///     the account, so this token — not a publishable key — authorizes the change. Pass `nil`
    ///     only for legacy integrations that still authenticate with a secret key.
    ///   - accountId: The Frame account ID whose payout method is being set.
    ///   - onResult: Closure called with a ``FrameResult`` when the screen finishes or is cancelled.
    ///     On `.completed` the associated ID is the newly elected payout method.
    public init(clientSecret: String? = nil,
                accountId: String,
                onResult: @escaping (FrameResult) -> Void = { _ in }) {
        self.onboardingClientSecret = clientSecret
        self.onResult = onResult
        self._viewModel = StateObject(wrappedValue: OnboardingContainerViewModel(accountId: accountId,
                                                                                 requiredCapabilities: []))
    }

    /// The wrapped payout-method picker, bound to a session and result callback.
    public var body: some View {
        // Present standalone only — ``OnboardingContainerView`` already applies these two.
        SelectPayoutMethodView(onboardingContainerViewModel: viewModel,
                               continueToNextStep: .constant(false),
                               returnToPreviousStep: .constant(false),
                               onElected: { payoutMethod in
                                   guard !didFinish else { return }
                                   didFinish = true
                                   // End the session here rather than leaving it to .onDisappear: the
                                   // host dismisses on this callback, and if the election's own
                                   // beginAction() is still in flight the isPerformingAction guard
                                   // below skips teardown entirely.
                                   viewModel.endOnboardingSessionIfOwned()
                                   onResult(.completed(id: payoutMethod.id))
                               },
                               // The host owns dismissal, as in ``FrameAddPayoutMethodView``.
                               onClose: {
                                   guard !didFinish else { return }
                                   didFinish = true
                                   viewModel.endOnboardingSessionIfOwned()
                                   onResult(.cancelled)
                               })
            .keyboardDoneToolbar()
            .frameToastOverlay()
            .refreshesSonarSession(accountId: viewModel.accountId)
            .onAppear {
                if let onboardingClientSecret {
                    viewModel.beginOnboardingSession(clientSecret: onboardingClientSecret)
                }
                // Seeds `primaryPayoutMethodId`; onboarding gets this from its container.
                Task { await viewModel.checkExistingAccount() }
            }
            .onDisappear {
                // Plaid Link covering this view fires .onDisappear without the user dismissing us;
                // Plaid runs inside beginAction()/endAction(), so this distinguishes them.
                guard !viewModel.isPerformingAction else { return }

                // Ownership-gated so we clear a session this view began — host-supplied or
                // self-minted by checkExistingAccount() — without wiping another flow's.
                viewModel.endOnboardingSessionIfOwned()
                if !didFinish {
                    didFinish = true
                    onResult(.cancelled)
                }
            }
    }
}

#Preview {
    FrameSelectPayoutMethodView(accountId: "")
}
