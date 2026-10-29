//
//  FramePayoutView.swift
//  Frame-iOS
//

import Frame
import SwiftUI

/// An amount-and-bank sheet for paying out to a saved ACH account.
///
/// Present this view modally. The keypad is capped at the payout session amount. Continue
/// creates `POST /v2/transfers` with the session token and returns that transfer id.
/// Dismissing this screen returns `.cancelled`. Closing the bank picker returns here.
///
/// Mint `pyt_sess_` on the host with `POST /v1/payout_sessions` and the withdrawable balance
/// as the amount cap. Do not mint `sk_` inside the SDK. A checkout session can only create a
/// payment; an onboarding session cannot create a transfer.
///
/// The elected primary bank is prefilled from `payout_payment_method_id`. A single saved bank
/// is selected either way.
public struct FramePayoutView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.frameTheme) private var theme
    @StateObject private var viewModel: FramePayoutViewModel

    let accountId: String
    let clientSecret: FramePayoutClientSecret
    var onResult: (FrameResult) -> Void

    @State private var showPayoutMethods = false
    @State private var didFinish = false
    @State private var submitIdempotencyKey: String?
    @State private var submitIdempotencyFingerprint: String?

    /// Creates a payout view for the given account.
    ///
    /// - Parameters:
    ///   - accountId: The Frame account the payout is drawn from (`source.account_id`).
    ///   - clientSecret: Payout-session token (`pyt_sess_…`) from `POST /v1/payout_sessions`.
    ///     Lists banks, opens the add-bank flow, and creates the transfer. The session amount
    ///     is the keypad cap.
    ///   - onResult: Closure called exactly once with a ``FrameResult``. `.completed` carries
    ///     the created transfer id.
    public init(
        accountId: String,
        clientSecret: FramePayoutClientSecret,
        onResult: @escaping (FrameResult) -> Void
    ) {
        self.accountId = accountId
        self.clientSecret = clientSecret
        self.onResult = onResult
        _viewModel = StateObject(wrappedValue: FramePayoutViewModel(availableAmount: clientSecret.amountCents))
    }

    /// The amount screen. The bank picker is a sheet so it is not nested inside this stack.
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeaderView(useCloseButton: true, headerTitle: "Payout") {
                guard !viewModel.isCreating else { return }
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
        .interactiveDismissDisabled(viewModel.isCreating)
        .refreshesSonarSession(accountId: accountId)
        .frameToastOverlay()
        .sheet(isPresented: $showPayoutMethods) {
            FrameSelectPayoutMethodView(
                clientSecret: clientSecret.clientSecret,
                accountId: accountId
            ) { result in
                if case .completed(let id) = result {
                    viewModel.selectElected(id)
                }
                showPayoutMethods = false
                viewModel.isLoadingMethods = true
                Task { await loadMethods() }
            }
        }
        .onAppear {
            Task { await loadMethods() }
        }
        .onDisappear {
            if viewModel.isCreating { return }
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
                    presentBankPicker()
                }
                .padding(.horizontal)
            } else if viewModel.payoutMethods.isEmpty {
                MethodOptionRow(iconName: "connect-bank-account-icon", title: "Connect a bank account") {
                    presentBankPicker()
                }
                .padding(.horizontal)
            } else {
                MethodOptionRow(iconName: "connect-bank-account-icon", title: "Choose a bank account") {
                    presentBankPicker()
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

    private func presentBankPicker() {
        Task {
            _ = await PayoutSessionsAPI.authorizationToken(accountId: accountId, secret: clientSecret)
            showPayoutMethods = true
        }
    }

    private func loadMethods() async {
        viewModel.isLoadingMethods = true
        defer { viewModel.isLoadingMethods = false }
        let (methods, listError) = await PayoutSessionsAPI.loadPaymentMethods(accountId: accountId, secret: clientSecret)
        let (primaryId, _) = await PayoutSessionsAPI.loadAccount(accountId: accountId, secret: clientSecret)
        guard !didFinish else { return }
        if let listError {
            FrameToastCenter.shared.show(listError.toastMessage())
            if viewModel.didLoadMethods { return }
        }
        viewModel.applyLoadedMethods(methods, primaryId: primaryId)
    }

    private func submit() {
        guard viewModel.canConfirm, !viewModel.isCreating, let methodId = viewModel.selectedPaymentMethod?.id else { return }
        let cents = viewModel.typedCents
        let fingerprint = "\(cents)|\(methodId)"
        if submitIdempotencyFingerprint != fingerprint {
            submitIdempotencyKey = UUID().uuidString
            submitIdempotencyFingerprint = fingerprint
        }
        viewModel.isCreating = true
        Task {
            defer { viewModel.isCreating = false }
            guard let token = await PayoutSessionsAPI.authorizationToken(accountId: accountId, secret: clientSecret) else {
                guard !didFinish else { return }
                FrameToastCenter.shared.show("Could not send this payout. Please try again.")
                return
            }
            let request = TransferV2Requests.CreateTransferRequest(
                amount: .init(value: cents, currency: clientSecret.amountCurrency),
                destination: .init(paymentMethodId: methodId)
            )
            do {
                let (transfer, error) = try await TransfersV2API.createTransfer(
                    request: request,
                    idempotencyKey: submitIdempotencyKey,
                    payoutClientSecret: token,
                    accountId: accountId
                )
                if let error {
                    if !didFinish {
                        FrameToastCenter.shared.show(error.toastMessage())
                    }
                    if case .serverError(let statusCode, _) = error,
                       (400..<500).contains(statusCode),
                       ![408, 409, 429].contains(statusCode) {
                        submitIdempotencyKey = nil
                        submitIdempotencyFingerprint = nil
                    }
                    return
                }
                guard let transferId = transfer?.id, !transferId.isEmpty else {
                    if !didFinish {
                        FrameToastCenter.shared.show("Could not send this payout. Please try again.")
                    }
                    return
                }
                didFinish = true
                onResult(.completed(id: transferId))
                dismiss()
            } catch {
                if didFinish { return }
                let message = (error as? NetworkingError)?.toastMessage() ?? "Error: Something went wrong. Please try again."
                FrameToastCenter.shared.show(message)
            }
        }
    }
}

#Preview {
    FramePayoutView(
        accountId: "",
        clientSecret: FramePayoutClientSecret(
            clientSecret: "pyt_sess_preview",
            expiresAt: Date(timeIntervalSinceNow: 1_800),
            amountCents: 5_000
        )
    ) { _ in }
}

#Preview("Dark") {
    FramePayoutView(
        accountId: "",
        clientSecret: FramePayoutClientSecret(
            clientSecret: "pyt_sess_preview",
            expiresAt: Date(timeIntervalSinceNow: 1_800),
            amountCents: 5_000
        )
    ) { _ in }
    .preferredColorScheme(.dark)
}
