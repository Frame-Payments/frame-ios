//
//  OfficePicksFlowView.swift
//  FrameExample-iOS
//
//  Demo prediction-market shell that showcases Frame KYC + deposit in dark mode.
//

import SwiftUI
import Frame
import FrameOnboarding

/// End-to-end “Office Picks” playground flow: intro → fake markets → KYC → deposit.
struct OfficePicksFlowView: View {
    @ObservedObject var viewModel: ContentViewModel
    let requiredCapabilities: [FrameObjects.Capabilities]

    @Environment(\.dismiss) private var dismiss

    @State private var step: Step = .intro
    @State private var isPreparingDeposit = false
    @State private var showOnboardingSheet = false
    @State private var showDepositSheet = false
    @State private var openDepositAfterOnboarding = false
    @State private var onboardingClientSecret: String?
    @State private var selectedCategory: MarketCategory = .all

    private enum Step {
        case intro
        case markets
    }

    var body: some View {
        ZStack {
            OfficePicksTheme.background.ignoresSafeArea()

            switch step {
            case .intro:
                OfficePicksIntroView {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        step = .markets
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            case .markets:
                OfficePicksMarketsView(
                    selectedCategory: $selectedCategory,
                    isPreparingDeposit: isPreparingDeposit,
                    onClose: { dismiss() },
                    onDeposit: { startDepositFlow() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .preferredColorScheme(.dark)
        .frameToastOverlay()
        .sheet(isPresented: $showOnboardingSheet, onDismiss: {
            // Wait until KYC is fully dismissed before presenting deposit.
            guard openDepositAfterOnboarding else { return }
            openDepositAfterOnboarding = false
            showDepositSheet = true
        }) {
            if let clientSecret = onboardingClientSecret {
                OnboardingContainerView(
                    clientSecret: clientSecret,
                    accountId: viewModel.accountId == "ENTER_AN_ACCOUNT_ID" ? nil : viewModel.accountId,
                    requiredCapabilities: requiredCapabilities
                ) { result in
                    switch result {
                    case .completed(let id):
                        viewModel.accountId = id
                        openDepositAfterOnboarding = true
                    case .finishedUnverified(let id, let outcome):
                        viewModel.accountId = id
                        openDepositAfterOnboarding = false
                        FrameToastCenter.shared.show("KYC finished unverified (\(outcome)). Deposit skipped.")
                    case .cancelled:
                        openDepositAfterOnboarding = false
                        FrameToastCenter.shared.show("Onboarding cancelled.")
                    case .failed(let error):
                        openDepositAfterOnboarding = false
                        FrameToastCenter.shared.show(error.localizedDescription)
                    }
                }
                .preferredColorScheme(.dark)
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showDepositSheet) {
            FrameDepositView(
                accountId: viewModel.accountId,
                mintCheckoutSession: { cents in
                    await viewModel.mintCheckoutClientSecret(accountId: viewModel.accountId, amountCents: cents)
                },
                onResult: { result in
                    switch result {
                    case .completed(let id):
                        FrameToastCenter.shared.show("Deposit completed: \(id)")
                    case .cancelled:
                        FrameToastCenter.shared.show("Deposit cancelled.")
                    case .failed(let error):
                        FrameToastCenter.shared.show(error.localizedDescription)
                    case .finishedUnverified(_, let outcome):
                        FrameToastCenter.shared.show("Deposit finished unverified: \(outcome)")
                    }
                }
            )
            .preferredColorScheme(.dark)
            .presentationDragIndicator(.visible)
        }
    }

    private func startDepositFlow() {
        guard !isPreparingDeposit else { return }
        isPreparingDeposit = true
        Task {
            defer { await MainActor.run { isPreparingDeposit = false } }

            let accountId: String
            if !viewModel.accountId.isEmpty && viewModel.accountId != "ENTER_AN_ACCOUNT_ID" {
                accountId = viewModel.accountId
            } else {
                guard let created = await viewModel.createEmptyIndividualAccount(capabilities: requiredCapabilities) else {
                    await MainActor.run { FrameToastCenter.shared.show("Could not create an account for KYC.") }
                    return
                }
                accountId = created
                await MainActor.run { viewModel.accountId = created }
            }

            // Fresh onboarding session for this demo path (do not clobber the playground sheets).
            guard let secret = await viewModel.mintOnboardingClientSecret(accountId: accountId, publish: false) else {
                await MainActor.run { FrameToastCenter.shared.show("Could not mint an onboarding client secret.") }
                return
            }

            await MainActor.run {
                onboardingClientSecret = secret
                showOnboardingSheet = true
            }
        }
    }
}

// MARK: - Intro

private struct OfficePicksIntroView: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 48)

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    OfficePicksTheme.accent.opacity(0.35),
                                    OfficePicksTheme.accent.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(OfficePicksTheme.accent)
                        .padding(28)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(OfficePicksTheme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .stroke(OfficePicksTheme.border, lineWidth: 1)
                                )
                        )
                }

                Text("Office Picks")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(-0.5)

                Text("Trade your takes on everyday office chaos — PRs, coffee runs, standups, and more.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(OfficePicksTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: onGetStarted) {
                Text("Get Started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(OfficePicksTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            Text("Demo markets · Frame KYC & deposit showcase")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(OfficePicksTheme.tertiaryText)
                .padding(.bottom, 28)
        }
    }
}

// MARK: - Markets

private struct OfficePicksMarketsView: View {
    @Binding var selectedCategory: MarketCategory
    let isPreparingDeposit: Bool
    let onClose: () -> Void
    let onDeposit: () -> Void

    private var filteredMarkets: [OfficePickMarket] {
        OfficePickMarket.samples.filter { selectedCategory == .all || $0.category == selectedCategory }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            categoryBar
                .padding(.top, 8)
                .padding(.bottom, 4)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(filteredMarkets) { market in
                        OfficePicksMarketCard(market: market)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }

            Spacer(minLength: 0)
        }
        .safeAreaInset(edge: .bottom) {
            depositBar
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Office Picks")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Trending office markets")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(OfficePicksTheme.secondaryText)
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(OfficePicksTheme.secondaryText)
                    .frame(width: 32, height: 32)
                    .background(OfficePicksTheme.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(OfficePicksTheme.border, lineWidth: 1))
            }
            .accessibilityLabel("Close Office Picks")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MarketCategory.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selectedCategory == category ? .black : OfficePicksTheme.secondaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? OfficePicksTheme.accent : OfficePicksTheme.card)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(selectedCategory == category ? Color.clear : OfficePicksTheme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var depositBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [OfficePicksTheme.background.opacity(0), OfficePicksTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)

            Button(action: onDeposit) {
                HStack(spacing: 10) {
                    if isPreparingDeposit {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Deposit Funds")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(OfficePicksTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(isPreparingDeposit)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .background(OfficePicksTheme.background)
        }
    }
}

// MARK: - Market card (Kalshi / Polymarket inspired)

private struct OfficePicksMarketCard: View {
    let market: OfficePickMarket
    @State private var flashSide: TradeSide?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(market.category.title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(OfficePicksTheme.accent)

                Spacer()

                Text(market.volumeLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(OfficePicksTheme.tertiaryText)
            }

            Text(market.question)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: 12) {
                MiniSparkline(points: market.sparkline, tint: market.yesCents >= 50 ? OfficePicksTheme.yes : OfficePicksTheme.no)
                    .frame(height: 36)
                    .frame(maxWidth: .infinity)

                Text("\(market.yesCents)¢")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            HStack(spacing: 10) {
                TradeButton(
                    title: "Yes",
                    cents: market.yesCents,
                    color: OfficePicksTheme.yes,
                    isFlashed: flashSide == .yes
                ) {
                    flash(.yes)
                }

                TradeButton(
                    title: "No",
                    cents: market.noCents,
                    color: OfficePicksTheme.no,
                    isFlashed: flashSide == .no
                ) {
                    flash(.no)
                }
            }
        }
        .padding(16)
        .background(OfficePicksTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(OfficePicksTheme.border, lineWidth: 1)
        )
    }

    private func flash(_ side: TradeSide) {
        withAnimation(.easeOut(duration: 0.12)) { flashSide = side }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeIn(duration: 0.2)) { flashSide = nil }
        }
    }
}

private enum TradeSide {
    case yes, no
}

private struct TradeButton: View {
    let title: String
    let cents: Int
    let color: Color
    let isFlashed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text("\(cents)¢")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(color.opacity(isFlashed ? 0.28 : 0.14))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
            .scaleEffect(isFlashed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
    }
}

private struct MiniSparkline: View {
    let points: [CGFloat]
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let values = points.isEmpty ? [0.5, 0.5] : points
            let minV = values.min() ?? 0
            let maxV = values.max() ?? 1
            let span = max(maxV - minV, 0.08)

            Path { path in
                for (index, value) in values.enumerated() {
                    let x = geo.size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                    let y = geo.size.height * (1 - (value - minV) / span)
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - Models & theme

private enum MarketCategory: String, CaseIterable, Identifiable {
    case all
    case shipping
    case culture
    case rituals
    case chaos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .shipping: return "Shipping"
        case .culture: return "Culture"
        case .rituals: return "Rituals"
        case .chaos: return "Chaos"
        }
    }
}

private struct OfficePickMarket: Identifiable {
    let id: String
    let category: MarketCategory
    let question: String
    let yesCents: Int
    let volumeLabel: String
    let sparkline: [CGFloat]

    var noCents: Int { max(1, 100 - yesCents) }

    static let samples: [OfficePickMarket] = [
        OfficePickMarket(
            id: "prs",
            category: .shipping,
            question: "How many PRs will ship today? (≥ 5)",
            yesCents: 62,
            volumeLabel: "$12.4k Vol",
            sparkline: [0.42, 0.45, 0.48, 0.51, 0.49, 0.55, 0.58, 0.61, 0.59, 0.62]
        ),
        OfficePickMarket(
            id: "coffee",
            category: .rituals,
            question: "How much coffee will we drink? (≥ 12 cups)",
            yesCents: 71,
            volumeLabel: "$8.1k Vol",
            sparkline: [0.55, 0.58, 0.62, 0.60, 0.66, 0.68, 0.70, 0.69, 0.72, 0.71]
        ),
        OfficePickMarket(
            id: "standup",
            category: .rituals,
            question: "Will standup start on time?",
            yesCents: 28,
            volumeLabel: "$5.6k Vol",
            sparkline: [0.48, 0.44, 0.40, 0.37, 0.35, 0.32, 0.30, 0.29, 0.27, 0.28]
        ),
        OfficePickMarket(
            id: "pizza",
            category: .culture,
            question: "Will the pizza arrive before 12:30?",
            yesCents: 54,
            volumeLabel: "$3.9k Vol",
            sparkline: [0.50, 0.52, 0.49, 0.53, 0.55, 0.51, 0.56, 0.54, 0.57, 0.54]
        ),
        OfficePickMarket(
            id: "ci",
            category: .shipping,
            question: "Will CI be green by end of day?",
            yesCents: 47,
            volumeLabel: "$15.2k Vol",
            sparkline: [0.60, 0.57, 0.55, 0.52, 0.50, 0.48, 0.46, 0.49, 0.45, 0.47]
        ),
        OfficePickMarket(
            id: "mute",
            category: .chaos,
            question: "Will someone forget to unmute on the all-hands?",
            yesCents: 81,
            volumeLabel: "$9.7k Vol",
            sparkline: [0.70, 0.72, 0.74, 0.73, 0.76, 0.78, 0.79, 0.80, 0.82, 0.81]
        ),
        OfficePickMarket(
            id: "slack",
            category: .chaos,
            question: "How many Slack threads go off-topic? (≥ 3)",
            yesCents: 66,
            volumeLabel: "$4.2k Vol",
            sparkline: [0.58, 0.60, 0.59, 0.63, 0.64, 0.62, 0.65, 0.67, 0.66, 0.66]
        ),
        OfficePickMarket(
            id: "design",
            category: .culture,
            question: "Will the design review finish under an hour?",
            yesCents: 39,
            volumeLabel: "$6.8k Vol",
            sparkline: [0.45, 0.44, 0.42, 0.41, 0.40, 0.38, 0.39, 0.37, 0.40, 0.39]
        ),
        OfficePickMarket(
            id: "snacks",
            category: .rituals,
            question: "Will the snack fridge be restocked today?",
            yesCents: 44,
            volumeLabel: "$2.1k Vol",
            sparkline: [0.52, 0.50, 0.49, 0.47, 0.46, 0.45, 0.43, 0.44, 0.42, 0.44]
        )
    ]
}

private enum OfficePicksTheme {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let card = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let border = Color.white.opacity(0.08)
    static let secondaryText = Color.white.opacity(0.62)
    static let tertiaryText = Color.white.opacity(0.42)
    /// Sharp mint accent — distinct from Kalshi green Yes buttons.
    static let accent = Color(red: 0.55, green: 0.96, blue: 0.72)
    static let yes = Color(red: 0.20, green: 0.84, blue: 0.50)
    static let no = Color(red: 0.96, green: 0.35, blue: 0.40)
}

#Preview("Office Picks") {
    OfficePicksFlowView(
        viewModel: ContentViewModel(),
        requiredCapabilities: [.kycPrefill, .geoCompliance, .ageVerification]
    )
}
