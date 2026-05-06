//
//  BankAccountDetailView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import Frame

public struct BankAccountDetailView: View {
    @Environment(\.frameTheme) private var theme
    @ObservedObject var viewModel: BankAccountViewModel

    @State private var showHeaderText: Bool

    public init(viewModel: BankAccountViewModel,
                showHeaderText: Bool = true) {
        self.viewModel = viewModel
        self._showHeaderText = State(initialValue: showHeaderText)
    }

    public var body: some View {
        VStack(alignment: .leading) {
            if showHeaderText {
                Text("Bank Account Details")
                    .bold()
                    .font(theme.fonts.label)
                    .padding([.horizontal, .top])
            }
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .fill(theme.colors.surface)
                .stroke(theme.colors.surfaceStroke)
                .frame(height: 100.0)
                .overlay {
                    VStack(spacing: 0) {
                        ValidatedTextField(prompt: "Routing Number",
                                           text: $viewModel.account.routingNumber.orEmpty,
                                           error: viewModel.errorBinding(.routing),
                                           keyboardType: .numberPad,
                                           characterLimit: 9,
                                           inlineError: true)
                        Divider()
                        ValidatedTextField(prompt: "Account Number",
                                           text: $viewModel.account.accountNumber.orEmpty,
                                           error: viewModel.errorBinding(.account),
                                           keyboardType: .numberPad,
                                           characterLimit: 17,
                                           inlineError: true)
                    }
                }
                .padding(.horizontal)
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
