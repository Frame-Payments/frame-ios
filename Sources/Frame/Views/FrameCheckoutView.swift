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

    let accountId: String?
    let paymentAmount: Int
    let merchantId: String
    let addressMode: FrameAddressMode

    var checkoutCallback: (_ success: Bool, _ transferId: String?) -> ()

    public init(accountId: String?,
                paymentAmount: Int,
                merchantId: String? = nil,
                addressMode: FrameAddressMode = .required,
                checkoutCallback: @escaping (_ success: Bool, _ transferId: String?) -> ()) {
        self.accountId = accountId
        self.paymentAmount = paymentAmount
        self.merchantId = merchantId ?? "merchant.com.app"
        self.addressMode = addressMode
        self.checkoutCallback = checkoutCallback
        
        _checkoutViewModel = StateObject(wrappedValue: FrameCheckoutViewModel(
            accountId: accountId,
            amount: paymentAmount,
            merchantId: merchantId ?? "merchant.com.app",
            addressMode: addressMode
        ))
    }

    public var body: some View {
        VStack(alignment: .leading) {
            topHeaderBar
            Divider()
            ScrollView {
                if !merchantId.isEmpty {
                    applePayButton
                }
                if checkoutViewModel.accountPaymentOptions != nil {
                    existingPaymentCardScroll
                        .padding([.leading, .bottom])
                }
                customerInformation
                    .padding(.bottom)
                cardInformation
                    .padding(.bottom)
                if addressMode != .hidden {
                    regionInformation
                }
                saveCardToggle
                if let checkoutError = checkoutViewModel.checkoutError {
                    Text(checkoutError)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.colors.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
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
                            owner: .account(accountId ?? ""),
                            merchantId: merchantId,
                            addCheckoutDivider: true) { result in
            if case .success(.charge(let transferId)) = result {
                checkoutCallback(true, transferId)
                dismiss()
            } else if case .failure(let failure) = result {
                checkoutCallback(false, nil)
                dismiss()
            }
        }
        .padding(.horizontal)
    }

    var existingPaymentCardScroll: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(checkoutViewModel.accountPaymentOptions ?? []) { option in
                    paymentCard(option: option)
                }
            }
        }
    }

    func paymentCard(option: FrameObjects.PaymentMethod) -> some View {
        RoundedRectangle(cornerRadius: theme.radii.medium)
            .fill(theme.colors.surface)
            .stroke(checkoutViewModel.selectedAccountPaymentOption == option ? theme.colors.textPrimary : theme.colors.surfaceStroke)
            .frame(width: 110.0, height: 55.0)
            .overlay {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        if let image = UIImage(named: "CreditCardIcon", in: Bundle.module, with: nil) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                        Spacer()
                    }
                    Text("\(option.card?.brand ?? "") \(option.card?.lastFourDigits ?? "")")
                        .font(theme.fonts.label)
                        .fontWeight(.semibold)
                }
                .frame(height: 50.0)
                .padding(.horizontal)
            }
            .onTapGesture {
                checkoutViewModel.selectedAccountPaymentOption = option
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
        Text("Customer Address")
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
                checkoutViewModel.checkoutError = nil
                do {
                    let transfer = try await checkoutViewModel.checkoutWithSelectedPaymentMethod(saveMethod: saveCardForPayments)
                    if let transfer {
                        self.checkoutCallback(true, transfer.id)
                    }
                } catch {
                    checkoutViewModel.checkoutError = (error as? NetworkingError).map(describe) ?? error.localizedDescription
                }
            }
        }
    }

    private func describe(_ error: NetworkingError) -> String {
        switch error {
        case .noData: return "Server returned no data."
        case .invalidURL: return "Invalid request URL."
        case .decodingFailed: return "Could not parse server response."
        case .serverError(let statusCode, let description):
            return description.isEmpty ? "Server error (HTTP \(statusCode))." : description
        case .unknownError: return "Something went wrong. Please try again."
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
    FrameCheckoutView(accountId: "", paymentAmount: 15000) { _,_  in }
}

#Preview("Dark") {
    FrameCheckoutView(accountId: "", paymentAmount: 15000) { _,_  in }
        .preferredColorScheme(.dark)
}
