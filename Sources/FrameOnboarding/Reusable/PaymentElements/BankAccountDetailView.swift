//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import Frame

struct BankAccountDetailView: View {
    @ObservedObject var viewModel: OnboardingContainerViewModel
    @Binding var routingNumber: String
    @Binding var accountNumber: String

    @State var headerFont: Font = Font.subheadline
    @State var showHeaderText: Bool = true

    init(viewModel: OnboardingContainerViewModel,
         routingNumber: Binding<String>,
         accountNumber: Binding<String>,
         showHeaderText: Bool = true) {
        self.viewModel = viewModel
        self._routingNumber = routingNumber
        self._accountNumber = accountNumber
        self._showHeaderText = State(initialValue: showHeaderText)
    }

    var body: some View {
        VStack(alignment: .leading) {
            if showHeaderText {
                Text("Bank Account Details")
                    .bold()
                    .font(headerFont)
                    .padding([.horizontal, .top])
            }
            RoundedRectangle(cornerRadius: 10.0)
                .fill(.white)
                .stroke(.gray.opacity(0.3))
                .frame(height: 100.0)
                .overlay {
                    VStack(spacing: 0) {
                        ValidatedTextField(prompt: "Routing Number",
                                           text: $routingNumber,
                                           error: viewModel.errorBinding(.payoutRouting),
                                           keyboardType: .numberPad,
                                           characterLimit: 9)
                        Divider()
                        ValidatedTextField(prompt: "Account Number",
                                           text: $accountNumber,
                                           error: viewModel.errorBinding(.payoutAccountNumber),
                                           keyboardType: .numberPad,
                                           characterLimit: 17)
                    }
                }
                .padding(.horizontal)
        }
    }
}
