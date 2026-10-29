//
//  FrameDepositView.swift
//  Frame-iOS
//

import SwiftUI

/// An amount-entry sheet that pushes ``FrameCheckoutView`` once the host mints a checkout session.
///
/// Present this view modally. The keypad collects an amount in cents. Continue asks the host to
/// mint a `chk_sess_` for that exact amount, then pushes checkout. `.completed(id:)` is the
/// Transfer id checkout creates. Dismissing this screen returns `.cancelled`. Backing out of
/// checkout returns here and does not finish the deposit flow.
public struct FrameDepositView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.frameTheme) private var theme
    @StateObject private var viewModel: FrameDepositViewModel

    let accountId: String
    let addressMode: FrameAddressMode
    let mintCheckoutSession: (Int) async -> FrameCheckoutClientSecret?
    var onResult: (FrameResult) -> Void

    @State private var continueToCheckout = false
    @State private var checkoutSecret: FrameCheckoutClientSecret?
    @State private var checkoutAmount = 0
    @State private var didFinish = false

    /// Creates a deposit view for the given account.
    ///
    /// - Parameters:
    ///   - accountId: The Frame account identifier that will receive the deposit.
    ///   - minAmount: Optional minimum in cents. Continue stays disabled below it.
    ///   - maxAmount: Optional maximum in cents. The keypad ignores digits that would exceed it.
    ///   - addressMode: Controls billing-address field visibility on the checkout screen. Defaults to `.required`.
    ///   - mintCheckoutSession: Host mints `POST /v1/checkout_sessions` for the typed cents. `chk_sess_` locks that amount; the SDK must not mint with `sk_`.
    ///   - onResult: Closure called exactly once with a ``FrameResult`` when the flow finishes or this screen is cancelled.
    public init(
        accountId: String,
        minAmount: Int? = nil,
        maxAmount: Int? = nil,
        addressMode: FrameAddressMode = .required,
        mintCheckoutSession: @escaping (Int) async -> FrameCheckoutClientSecret?,
        onResult: @escaping (FrameResult) -> Void
    ) {
        self.accountId = accountId
        self.addressMode = addressMode
        self.mintCheckoutSession = mintCheckoutSession
        self.onResult = onResult
        _viewModel = StateObject(wrappedValue: FrameDepositViewModel(
            minAmount: minAmount,
            maxAmount: maxAmount
        ))
    }

    /// The amount screen, which pushes ``FrameCheckoutView`` after the host mints a session.
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                topHeaderBar
                Divider()
                amountDisplay
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                quickAmountsRow
                FrameAmountKeypad(cents: $viewModel.typedCents, maxAmount: viewModel.maxAmount)
                    .padding(.horizontal)
                    .allowsHitTesting(!viewModel.isMinting)
                ContinueButton(
                    buttonText: "Continue",
                    enabled: .constant(viewModel.isAmountInRange),
                    isLoading: $viewModel.isMinting,
                    buttonAction: mintAndContinue
                )
            }
            .navigationDestination(isPresented: $continueToCheckout) {
                if let checkoutSecret {
                    FrameCheckoutView(
                        accountId: accountId,
                        paymentAmount: checkoutAmount,
                        addressMode: addressMode,
                        checkoutClientSecret: checkoutSecret
                    ) { result in
                        switch result {
                        case .completed(let transferId):
                            didFinish = true
                            onResult(.completed(id: transferId))
                            dismiss()
                        case .failed(let error):
                            didFinish = true
                            onResult(.failed(error))
                            dismiss()
                        case .cancelled:
                            continueToCheckout = false
                        case .finishedUnverified(let id, let outcome):
                            didFinish = true
                            onResult(.finishedUnverified(id: id, outcome: outcome))
                            dismiss()
                        }
                    }
                    .toolbar(.hidden)
                }
            }
        }
        .refreshesSonarSession(accountId: accountId)
        .frameToastOverlay()
        .onDisappear {
            if !didFinish {
                didFinish = true
                onResult(.cancelled)
            }
        }
    }

    var topHeaderBar: some View {
        HStack {
            Text("Deposit")
                .font(theme.fonts.headline)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            Spacer()
            Button {
                dismiss()
            } label: {
                if let image = UIImage(named: "BlackCircleCloseButton",
                                       in: FrameResources.module, with: nil) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.top)
    }

    var amountDisplay: some View {
        VStack(spacing: theme.spacing.sectionGap) {
            Text(CurrencyFormatter.shared.convertCentsToCurrencyString(viewModel.typedCents))
                .font(theme.fonts.depositAmount)
                .foregroundColor(theme.colors.textPrimary)
                .frame(maxWidth: .infinity)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
            if let amountCaption {
                Text(amountCaption)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }

    var quickAmountsRow: some View {
        HStack(spacing: theme.spacing.sectionGap) {
            ForEach(FrameDepositViewModel.quickAmounts, id: \.self) { cents in
                quickAmountButton(cents)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, theme.spacing.sectionGap)
        .allowsHitTesting(!viewModel.isMinting)
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
        .disabled(!available || viewModel.isMinting)
        .accessibilityLabel("Deposit $\(cents / 100)")
    }

    private var amountCaption: String? {
        let format = { (cents: Int) in CurrencyFormatter.shared.convertCentsToCurrencyString(cents) }
        switch (viewModel.minAmount, viewModel.maxAmount) {
        case let (min?, max?):
            return "Minimum \(format(min)) · Maximum \(format(max))"
        case let (min?, nil):
            return "Minimum \(format(min))"
        case let (nil, max?):
            return "Maximum \(format(max))"
        case (nil, nil):
            return nil
        }
    }

    private func mintAndContinue() {
        let cents = viewModel.typedCents
        guard viewModel.isAmountInRange, !viewModel.isMinting else { return }
        viewModel.isMinting = true
        Task {
            let secret = await mintCheckoutSession(cents)
            viewModel.isMinting = false
            guard !didFinish else { return }
            guard let secret, secret.amountCents == cents else {
                FrameToastCenter.shared.show("Could not start checkout. Please try again.")
                return
            }
            checkoutAmount = cents
            checkoutSecret = secret
            continueToCheckout = true
        }
    }
}

#Preview {
    FrameDepositView(accountId: "", mintCheckoutSession: { _ in nil }) { _ in }
}

#Preview("Dark") {
    FrameDepositView(accountId: "", mintCheckoutSession: { _ in nil }) { _ in }
        .preferredColorScheme(.dark)
}
