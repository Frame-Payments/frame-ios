//
//  FramePayoutView.swift
//  Frame-iOS
//

import Frame
import SwiftUI

/// An amount-and-bank sheet for paying out to a saved ACH account.
///
/// Present this view modally. The keypad is capped at `availableAmount`. Continue asks the
/// host to create the payout and returns that transfer id. Dismissing this screen returns
/// `.cancelled`. Closing the bank picker returns here.
///
/// `POST /v2/transfers` does not accept `onb_sess_` or `chk_sess_` for a payout. A checkout
/// session can only create a payment, and it strips `destination`. There is no payout session
/// type. The host creates the transfer on its server with `sk_` and returns the id:
///
/// ```json
/// {
///   "amount": { "value": 5000, "currency": "usd" },
///   "source": { "account_id": "acc_…" },
///   "destination": { "payment_method_id": "pm_…" }
/// }
/// ```
///
/// The API treats account → payment method as a payout. Omit `sonar_session_id`; the API
/// rejects it on payouts. Do not mint `sk_` inside the SDK.
///
/// The elected primary bank is prefilled when `GET /v1/accounts/:id` includes
/// `payout_payment_method_id`. An onboarding session omits that field unless legacy client
/// PII is enabled. A single saved bank is selected either way.
public struct FramePayoutView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.frameTheme) private var theme
    @StateObject private var viewModel: FramePayoutViewModel

    let accountId: String
    let clientSecret: String
    let createPayout: (Int, String) async -> String?
    var onResult: (FrameResult) -> Void

    @State private var showPayoutMethods = false
    @State private var didFinish = false

    /// Creates a payout view for the given account.
    ///
    /// - Parameters:
    ///   - accountId: The Frame account the payout is drawn from (`source.account_id`).
    ///   - availableAmount: Withdrawable balance in cents. The keypad ignores anything higher.
    ///   - clientSecret: Onboarding-session token (`onb_sess_…`) used to list ACH methods and
    ///     open the existing add-bank flow. Not used to create the transfer.
    ///   - createPayout: Host creates `POST /v2/transfers` for these cents and this bank, then
    ///     returns the transfer id. Return `nil` to leave the screen up.
    ///   - onResult: Closure called exactly once with a ``FrameResult``. `.completed` carries
    ///     the transfer id from `createPayout`.
    public init(
        accountId: String,
        availableAmount: Int,
        clientSecret: String,
        createPayout: @escaping (Int, String) async -> String?,
        onResult: @escaping (FrameResult) -> Void
    ) {
        self.accountId = accountId
        self.clientSecret = clientSecret
        self.createPayout = createPayout
        self.onResult = onResult
        _viewModel = StateObject(wrappedValue: FramePayoutViewModel(availableAmount: availableAmount))
    }

    /// The amount screen, which pushes ``FrameSelectPayoutMethodView`` to pick or add a bank.
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                PageHeaderView(useCloseButton: true, headerTitle: "Payout") {
                    dismiss()
                }
                amountDisplay
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                destinationRow
                    .padding(.bottom, theme.spacing.sectionGap)
                    .allowsHitTesting(!viewModel.isCreating && !viewModel.isLoadingMethods)
                quickAmountsRow
                FrameAmountKeypad(cents: $viewModel.typedCents, maxAmount: viewModel.availableAmount)
                    .padding(.horizontal)
                    .allowsHitTesting(!viewModel.isCreating)
                ContinueButton(
                    buttonText: "Payout \(viewModel.amountText)",
                    enabled: .constant(viewModel.canConfirm),
                    isLoading: $viewModel.isCreating,
                    buttonAction: submit
                )
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showPayoutMethods) {
                FrameSelectPayoutMethodView(
                    clientSecret: clientSecret,
                    accountId: accountId
                ) { result in
                    if case .completed(let id) = result {
                        viewModel.selectElected(id)
                    }
                    showPayoutMethods = false
                    viewModel.isLoadingMethods = true
                    Task { await loadMethods() }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .refreshesSonarSession(accountId: accountId)
        .frameToastOverlay()
        .onAppear {
            Task { await loadMethods() }
        }
        .onDisappear {
            // On the NavigationStack, so pushing the bank picker does not fire this. Sheet dismiss does.
            if !didFinish {
                didFinish = true
                onResult(.cancelled)
            }
        }
    }

    var amountDisplay: some View {
        VStack(spacing: theme.spacing.sectionGap) {
            Text(viewModel.amountText)
                .font(theme.fonts.depositAmount)
                .foregroundColor(theme.colors.textPrimary)
                .frame(maxWidth: .infinity)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
            Text("Available \(viewModel.availableText)")
                .font(theme.fonts.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(.horizontal)
    }

    var quickAmountsRow: some View {
        HStack(spacing: theme.spacing.sectionGap) {
            ForEach(FramePayoutViewModel.quickAmounts, id: \.self) { cents in
                quickAmountButton(cents)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, theme.spacing.sectionGap)
        .allowsHitTesting(!viewModel.isCreating)
    }

    @ViewBuilder
    var destinationRow: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sectionGap) {
            Text("Pay out to")
                .font(theme.fonts.headline)
                .foregroundColor(theme.colors.textSecondary)
                .padding(.horizontal)
            if !viewModel.didLoadMethods {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 56)
            } else if let method = viewModel.selectedPaymentMethod {
                FramePaymentMethodRow(paymentMethod: method, isSelected: true) {
                    showPayoutMethods = true
                }
                .padding(.horizontal)
            } else if viewModel.payoutMethods.isEmpty {
                MethodOptionRow(iconName: "connect-bank-account-icon", title: "Connect a bank account") {
                    showPayoutMethods = true
                }
                .padding(.horizontal)
            } else {
                MethodOptionRow(iconName: "connect-bank-account-icon", title: "Choose a bank account") {
                    showPayoutMethods = true
                }
                .padding(.horizontal)
            }
        }
    }

    func quickAmountButton(_ cents: Int) -> some View {
        let available = viewModel.isQuickAmountAvailable(cents)
        let selected = viewModel.typedCents == cents
        let fill: Color = {
            if !available { return theme.colors.disabledButton }
            if selected { return theme.colors.primaryButton }
            return theme.colors.surface
        }()
        let textColor: Color = {
            if !available { return theme.colors.disabledButtonText }
            if selected { return theme.colors.primaryButtonText }
            return theme.colors.textPrimary
        }()
        let stroke: Color = {
            if !available { return theme.colors.disabledButtonStroke }
            if selected { return theme.colors.primaryButton }
            return theme.colors.surfaceStroke
        }()
        return Button {
            viewModel.applyQuickAmount(cents)
        } label: {
            Text("$\(cents / 100)")
                .font(theme.fonts.button)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(fill, in: RoundedRectangle(cornerRadius: theme.radii.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.medium)
                        .strokeBorder(stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!available || viewModel.isCreating)
        .accessibilityLabel("Payout $\(cents / 100)")
    }

    private func loadMethods() async {
        // Hold the session only for this read. Leaving it up rewrites the host's secret-key create into onb_sess_.
        viewModel.isLoadingMethods = true
        FrameNetworking.shared.beginOnboardingSession(clientSecret: clientSecret)
        defer {
            FrameNetworking.shared.endOnboardingSession()
            viewModel.isLoadingMethods = false
        }
        do {
            let (response, listError) = try await PaymentMethodsAPI.getPaymentMethodsWithAccount(
                accountId: accountId,
                clientSecret: clientSecret
            )
            let account = (try? await AccountsAPI.getAccountWith(accountId: accountId))?.0
            guard !didFinish else { return }
            if let listError {
                FrameToastCenter.shared.show(listError.toastMessage())
            }
            viewModel.applyLoadedMethods(response?.data ?? [], primaryId: account?.payoutPaymentMethodId)
        } catch {
            guard !didFinish else { return }
            viewModel.applyLoadedMethods([], primaryId: nil)
            let message = (error as? NetworkingError)?.toastMessage() ?? "Error: Something went wrong. Please try again."
            FrameToastCenter.shared.show(message)
        }
    }

    private func submit() {
        guard viewModel.canConfirm, !viewModel.isCreating, let methodId = viewModel.selectedPaymentMethod?.id else { return }
        let cents = viewModel.typedCents
        viewModel.isCreating = true
        Task {
            // Drop any onboarding session first. While one is active, secret-key calls leave as onb_sess_.
            FrameNetworking.shared.endOnboardingSession()
            let transferId = await createPayout(cents, methodId)
            viewModel.isCreating = false
            guard !didFinish else { return }
            guard let transferId, !transferId.isEmpty else {
                FrameToastCenter.shared.show("Could not send this payout. Please try again.")
                return
            }
            didFinish = true
            onResult(.completed(id: transferId))
            dismiss()
        }
    }
}

#Preview {
    FramePayoutView(
        accountId: "",
        availableAmount: 5_000,
        clientSecret: "onb_sess_preview",
        createPayout: { _, _ in nil }
    ) { _ in }
}

#Preview("Dark") {
    FramePayoutView(
        accountId: "",
        availableAmount: 5_000,
        clientSecret: "onb_sess_preview",
        createPayout: { _, _ in nil }
    ) { _ in }
    .preferredColorScheme(.dark)
}
