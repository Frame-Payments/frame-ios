//
//  FrameCheckoutView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/27/24.
//

import SwiftUI
import EvervaultInputs

public struct FrameCheckoutView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.frameTheme) private var theme
    @StateObject var checkoutViewModel: FrameCheckoutViewModel

    @State var useBlackButtons: Bool = true
    @State var saveCardForPayments: Bool = false
    @State private var isShowingPicker = false
    @State private var didFinish = false

    let accountId: String
    let paymentAmount: Int
    let addressMode: FrameAddressMode

    var onResult: (FrameResult) -> Void

    public init(accountId: String,
                paymentAmount: Int,
                addressMode: FrameAddressMode = .required,
                onResult: @escaping (FrameResult) -> Void) {
        self.accountId = accountId
        self.paymentAmount = paymentAmount
        self.addressMode = addressMode
        self.onResult = onResult

        _checkoutViewModel = StateObject(wrappedValue: FrameCheckoutViewModel(
            accountId: accountId,
            amount: paymentAmount,
            addressMode: addressMode
        ))
    }

    /// True when the host has configured an Apple Pay merchant identifier at SDK init time.
    /// Drives whether the Apple Pay row is rendered at the top of the sheet.
    private var applePayConfigured: Bool {
        !(FrameNetworking.shared.applePayMerchantId ?? "").isEmpty
    }

    public var body: some View {
        VStack(alignment: .leading) {
            topHeaderBar
            Divider()
            ScrollView {
                if applePayConfigured {
                    applePayButton
                }
                paymentMethodList
                    .padding(.top)
                    .padding(.bottom)
                customerInformation
                    .padding(.bottom)
                if checkoutViewModel.didLoadAccountPaymentMethods,
                   checkoutViewModel.selectedAccountPaymentOption == nil {
                    cardInformation
                        .padding(.bottom)
                    if addressMode != .hidden {
                        regionInformation
                    }
                    saveCardToggle
                }
                checkoutButton
                Spacer()
            }
        }
        .task {
            await checkoutViewModel.loadAccountDetails()
        }
        .sheet(isPresented: $isShowingPicker) {
            CountryPickerSheet(
                selectedCountry: $checkoutViewModel.customerCountry,
                isPresented: $isShowingPicker
            )
            .presentationDetents([.fraction(0.3)])
            .presentationDragIndicator(.visible)
        }
        .frameToastOverlay()
        .onDisappear {
            // The sheet's swipe-down / close-button dismissal lands here without going through
            // the pay button. Emit `.cancelled` so the host's promise resolves instead of
            // hanging waiting for a completion that won't come.
            if !didFinish {
                didFinish = true
                onResult(.cancelled)
            }
        }
    }

    var topHeaderBar: some View {
        HStack {
            Text("Checkout")
                .font(theme.fonts.headline)
                .padding(.horizontal)
            Spacer()
            Button {
                self.dismiss()
            } label: {
                if let image = UIImage(named: "BlackCircleCloseButton",
                                       in: Bundle.module, with: nil) {
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

    @ViewBuilder
    var applePayButton: some View {
        FrameApplePayButton(mode: .charge(amount: paymentAmount, currency: "usd"),
                            owner: .account(accountId),
                            addCheckoutDivider: true) { result in
            switch result {
            case .success(.charge(let transferId)):
                didFinish = true
                onResult(.completed(id: transferId))
                dismiss()
            case .success(.paymentMethod):
                break // not produced in `.charge` mode
            case .failure(let error):
                // Surface the failure as a toast and keep the checkout open so the user can
                // retry Apple Pay or fall through to card entry. Closing the modal here would
                // strand the user mid-flow for what's often a transient transport error or a
                // missing-config case the host can correct without restarting checkout.
                // Prefer the server's `error_details.message` for server errors; fall back to a
                // generic message for transport errors and any other Error subtype.
                let message = (error as? NetworkingError)?.toastMessage()
                    ?? "Error: Apple Pay could not complete. Please try again or use a card."
                FrameToastCenter.shared.show(message)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    var paymentMethodList: some View {
        VStack(spacing: 8) {
            ForEach(checkoutViewModel.accountPaymentOptions ?? []) { option in
                savedPaymentRow(option: option)
            }
            enterNewPaymentRow
        }
        .padding(.horizontal)
    }

    func savedPaymentRow(option: FrameObjects.PaymentMethod) -> some View {
        let isSelected = checkoutViewModel.selectedAccountPaymentOption == option
        let isACH = option.type == .ach
        let iconName = isACH ? "bank-icon" : (option.card?.brand ?? "emptycard")
        let primaryText = isACH
            ? "•••• \(option.ach?.lastFour ?? "")"
            : "•••• \(option.card?.lastFourDigits ?? "")"
        let secondaryText = isACH
            ? "\((option.ach?.accountType?.rawValue ?? "").capitalized) Account"
            : "Exp. \(option.card?.expirationMonth ?? "")/\(option.card?.expirationYear ?? "")"
        return HStack {
            Image(iconName, bundle: Bundle.module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48.0, height: 32.0)
                .padding(.horizontal)
            VStack(alignment: .leading) {
                Text(primaryText)
                    .bold()
                    .font(theme.fonts.bodySmall)
                    .padding(.bottom, 1.0)
                Text(secondaryText)
                    .font(theme.fonts.caption)
            }
            Spacer()
            Image(isSelected ? "filled-selection" : "empty-selection", bundle: Bundle.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .stroke(isSelected ? theme.colors.textPrimary : theme.colors.surfaceStroke, lineWidth: 1)
        )
        .onTapGesture {
            checkoutViewModel.selectedAccountPaymentOption = option
            checkoutViewModel.clearNewCardFieldErrors()
        }
    }

    var enterNewPaymentRow: some View {
        let isSelected = checkoutViewModel.selectedAccountPaymentOption == nil
        return HStack {
            Image("emptycard", bundle: Bundle.module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48.0, height: 32.0)
                .padding(.horizontal)
            Text("Enter New Payment Method")
                .bold()
                .font(theme.fonts.bodySmall)
            Spacer()
            Image(isSelected ? "filled-selection" : "empty-selection", bundle: Bundle.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 64.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .stroke(isSelected ? theme.colors.textPrimary : theme.colors.surfaceStroke, lineWidth: 1)
        )
        .onTapGesture {
            checkoutViewModel.selectedAccountPaymentOption = nil
        }
    }

    @ViewBuilder
    var cardInformation: some View {
        Text("Card Information")
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(theme.fonts.headline)
            .foregroundColor(theme.colors.textSecondary)
            .padding(.horizontal)
        // Evervault Card Input
        PaymentCardInput(cardData: $checkoutViewModel.cardData)
            .paymentCardInputStyle(EncryptedPaymentCardInput())
            .onChange(of: checkoutViewModel.cardData.isPotentiallyValid) { _ in
                checkoutViewModel.clearError(.card)
            }
        if let cardError = checkoutViewModel.fieldErrors[.card] {
            Text(cardError)
                .font(theme.fonts.caption)
                .foregroundColor(theme.colors.error)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        }
    }

    @ViewBuilder
    var customerInformation: some View {
        Text("Customer Information")
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(theme.fonts.headline)
            .foregroundColor(theme.colors.textSecondary)
            .padding(.horizontal)
        VStack(spacing: 0) {
            ValidatedTextField(prompt: "Customer Name",
                               text: $checkoutViewModel.customerName,
                               error: errorBinding(.name))
            Divider()
            ValidatedTextField(prompt: "Customer Email",
                               text: $checkoutViewModel.customerEmail,
                               error: errorBinding(.email),
                               keyboardType: .emailAddress)
        }
        .background(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .fill(theme.colors.surface)
                .stroke(theme.colors.surfaceStroke)
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    var regionInformation: some View {
        Text("Billing Address")
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(theme.fonts.headline)
            .foregroundColor(theme.colors.textSecondary)
            .padding(.horizontal)
        VStack(spacing: 0) {
            ValidatedTextField(prompt: "Address Line 1",
                               text: $checkoutViewModel.customerAddressLine1,
                               error: errorBinding(.addressLine1))
            Divider()
            ValidatedTextField(prompt: "Address Line 2",
                               text: $checkoutViewModel.customerAddressLine2,
                               error: .constant(nil))
            Divider()
            HStack(spacing: 0) {
                ValidatedTextField(prompt: "City",
                                   text: $checkoutViewModel.customerCity,
                                   error: errorBinding(.city))
                ValidatedTextField(prompt: "State",
                                   text: $checkoutViewModel.customerState,
                                   error: errorBinding(.state),
                                   characterLimit: 2)
            }
            Divider()
            HStack {
                Button {
                    self.isShowingPicker = true
                } label: {
                    Text(checkoutViewModel.customerCountry.displayName)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(theme.fonts.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(.horizontal)
                }

                if let image = UIImage(named: "BlackDownArrow", in: Bundle.module, with: nil) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20.0)
                        .padding()
                }
            }
            .frame(height: 49.0)
            Divider()
            ValidatedTextField(prompt: "Zip Code",
                               text: $checkoutViewModel.customerZipCode,
                               error: errorBinding(.zip),
                               keyboardType: .numberPad,
                               characterLimit: 5)
        }
        .background(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .fill(theme.colors.surface)
                .stroke(theme.colors.surfaceStroke)
        )
        .padding(.horizontal)
    }

    var saveCardToggle: some View {
        HStack(spacing: 0) {
            Toggle(isOn: $saveCardForPayments) {
                Text("Save this card for future payments")
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .toggleStyle(iOSCheckboxToggleStyle())
            Spacer()
        }
        .padding()
    }

    var checkoutButton: some View {
        ContinueButton(
            buttonText: "Pay \(CurrencyFormatter.shared.convertCentsToCurrencyString(paymentAmount))",
            enabled: .constant(checkoutViewModel.hasUsablePaymentInput),
            isLoading: .constant(checkoutViewModel.isPerformingAction)
        ) {
            Task {
                do {
                    let transfer = try await checkoutViewModel.checkoutWithSelectedPaymentMethod(saveMethod: saveCardForPayments)
                    if let transfer {
                        didFinish = true
                        onResult(.completed(id: transfer.id))
                        dismiss()
                    }
                } catch {
                    // Every error — server validation (card declined, "Card submitted is not a
                    // test card", insufficient funds), transport, decode — surfaces as a toast.
                    // Modal stays open so the user can fix the input and retry.
                    let message = (error as? NetworkingError)?.toastMessage()
                        ?? "Error: Something went wrong. Please try again."
                    FrameToastCenter.shared.show(message)
                }
            }
        }
    }

    private func errorBinding(_ field: FrameCheckoutViewModel.CheckoutField) -> Binding<String?> {
        Binding(
            get: { checkoutViewModel.fieldErrors[field] },
            set: { newValue in
                if newValue == nil {
                    checkoutViewModel.fieldErrors[field] = nil
                } else {
                    checkoutViewModel.fieldErrors[field] = newValue
                }
            }
        )
    }
}

#Preview {
    FrameCheckoutView(accountId: "", paymentAmount: 15000) { _ in }
}

#Preview("Dark") {
    FrameCheckoutView(accountId: "", paymentAmount: 15000) { _ in }
        .preferredColorScheme(.dark)
}
