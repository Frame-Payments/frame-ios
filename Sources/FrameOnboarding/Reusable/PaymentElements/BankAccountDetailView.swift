//
//  BankAccountDetailView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import Frame

/// A SwiftUI view that renders routing-number and account-number input fields for bank account collection.
///
/// Embed this view inside an onboarding or payment flow to let the user enter their bank account
/// details. Validation state is managed externally by a ``BankAccountViewModel``.
public struct BankAccountDetailView: View {
    @Environment(\.frameTheme) private var theme
    @ObservedObject var viewModel: BankAccountViewModel

    @State private var showHeaderText: Bool

    /// Creates a bank account detail view.
    /// - Parameters:
    ///   - viewModel: The view model that holds and validates the bank account input.
    ///   - showHeaderText: When `true` (the default), a "Bank Account Details" heading is rendered above the input fields.
    ///   - applyHorizontalPadding: When `true` (the default), applies horizontal insets. Pass `false` when the
    ///     parent already provides leading/trailing padding so edges stay aligned with siblings.
    public init(viewModel: BankAccountViewModel,
                showHeaderText: Bool = true,
                applyHorizontalPadding: Bool = true) {
        self.viewModel = viewModel
        self._showHeaderText = State(initialValue: showHeaderText)
        self.applyHorizontalPadding = applyHorizontalPadding
    }

    private let applyHorizontalPadding: Bool

    /// The content and layout of the view.
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.formBlock) {
            if showHeaderText {
                Text("Bank Account Details")
                    .bold()
                    .font(theme.fonts.label)
                    .padding(.horizontal, applyHorizontalPadding ? nil : 0)
            }
            ValidatedTextField(prompt: "Routing Number",
                               text: $viewModel.account.routingNumber.orEmpty,
                               error: viewModel.errorBinding(.routing),
                               keyboardType: .numberPad,
                               characterLimit: 9,
                               inlineError: true)
            .padding(.horizontal, applyHorizontalPadding ? nil : 0)
            ValidatedTextField(prompt: "Account Number",
                               text: $viewModel.account.accountNumber.orEmpty,
                               error: viewModel.errorBinding(.account),
                               keyboardType: .numberPad,
                               characterLimit: 17,
                               inlineError: true)
            .padding(.horizontal, applyHorizontalPadding ? nil : 0)
        }
    }
}

#Preview {
    @Previewable @StateObject var vm = BankAccountViewModel()
    VStack {
        BankAccountDetailView(viewModel: vm)
        Button("Validate") { _ = vm.validate() }
    }
}

#Preview("Dark") {
    @Previewable @StateObject var vm = BankAccountViewModel()
    VStack {
        BankAccountDetailView(viewModel: vm)
        Button("Validate") { _ = vm.validate() }
    }
    .preferredColorScheme(.dark)
}
