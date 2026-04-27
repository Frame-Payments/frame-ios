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
    @StateObject var checkoutViewModel: FrameCheckoutViewModel

    @State private var rotationAngle = 0.0
    @State var showLoadingState: Bool = false
    @State var useBlackButtons: Bool = true
    @State var saveCardForPayments: Bool = false
    @State private var isShowingPicker = false

    let customerId: String?
    let paymentAmount: Int
    let merchantId: String
    let addressMode: FrameAddressMode

    var colors: [Color] = [Color.white, Color.white.opacity(0.3)]

    var checkoutCallback: (FrameObjects.ChargeIntent) -> ()

    public init(customerId: String?,
                paymentAmount: Int,
                merchantId: String = "",
                addressMode: FrameAddressMode = .required,
                checkoutCallback: @escaping (FrameObjects.ChargeIntent) -> ()) {
        self.customerId = customerId
        self.paymentAmount = paymentAmount
        self.merchantId = merchantId
        self.addressMode = addressMode
        self.checkoutCallback = checkoutCallback
        _checkoutViewModel = StateObject(wrappedValue: FrameCheckoutViewModel(
            customerId: customerId,
            amount: paymentAmount,
            merchantId: merchantId,
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
                if checkoutViewModel.customerPaymentOptions != nil {
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
                checkoutButton
                Spacer()
            }
        }
        .task {
            await checkoutViewModel.loadCustomerPaymentMethods()
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
                .font(.headline)
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
        FrameApplePayButton(amount: paymentAmount,
                            owner: .customer(customerId ?? ""),
                            merchantId: merchantId,
                            addCheckoutDivider: true) { result in
            if case .success(let chargeIntent) = result {
                checkoutCallback(chargeIntent)
                dismiss()
            }
        }
        .padding(.horizontal)
    }

    var existingPaymentCardScroll: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(checkoutViewModel.customerPaymentOptions ?? []) { option in
                    paymentCard(option: option)
                }
            }
        }
    }

    func paymentCard(option: FrameObjects.PaymentMethod) -> some View {
        RoundedRectangle(cornerRadius: 10.0)
            .fill(.white)
            .stroke(checkoutViewModel.selectedCustomerPaymentOption == option ? Color.black : Color.gray.opacity(0.3))
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
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(height: 50.0)
                .padding(.horizontal)
            }
            .onTapGesture {
                checkoutViewModel.selectedCustomerPaymentOption = option
            }
    }

    @ViewBuilder
    var cardInformation: some View {
        Text("Card Information")
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.headline)
            .foregroundColor(.gray)
            .padding(.horizontal)
        // Evervault Card Input
        PaymentCardInput(cardData: $checkoutViewModel.cardData)
            .paymentCardInputStyle(EncryptedPaymentCardInput())
            .onChange(of: checkoutViewModel.cardData.isPotentiallyValid) { _ in
                checkoutViewModel.clearError(.card)
            }
        if let cardError = checkoutViewModel.fieldErrors[.card] {
            Text(cardError)
                .font(.caption)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        }
    }

    @ViewBuilder
    var customerInformation: some View {
        Text("Customer Information")
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.headline)
            .foregroundColor(.gray)
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
            RoundedRectangle(cornerRadius: 10.0)
                .fill(.white)
                .stroke(.gray.opacity(0.3))
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    var regionInformation: some View {
        Text("Customer Address")
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.headline)
            .foregroundColor(.gray)
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
                        .font(.headline)
                        .foregroundColor(.black)
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
            RoundedRectangle(cornerRadius: 10.0)
                .fill(.white)
                .stroke(.gray.opacity(0.3))
        )
        .padding(.horizontal)
    }

    var saveCardToggle: some View {
        HStack(spacing: 0) {
            Toggle(isOn: $saveCardForPayments) {
                Text("Save this card for future payments")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .toggleStyle(iOSCheckboxToggleStyle())
            Spacer()
        }
        .padding()
    }

    var checkoutButton: some View {
        let canCheckout = checkoutViewModel.hasUsablePaymentInput
        return Button {
            Task {
                self.showLoadingState = true
                let chargeIntent = try await checkoutViewModel.checkoutWithSelectedPaymentMethod(saveMethod: saveCardForPayments)

                if let chargeIntent {
                    self.checkoutCallback(chargeIntent)
                }
                self.showLoadingState = false
            }
        } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(canCheckout ? .black : Color.gray.opacity(0.4))
                .frame(height: 50.0)
                .overlay {
                    if showLoadingState {
                        HStack(spacing: 10.0) {
                            loadingSpinner
                            Text("Processing...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    } else {
                        Text("Pay \(CurrencyFormatter.shared.convertCentsToCurrencyString(paymentAmount))")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
        }
        .padding(.horizontal)
        .disabled(showLoadingState || !canCheckout)
    }

    var loadingSpinner: some View {
        ZStack(alignment: .center) {
            Circle()
               .stroke(
                   AngularGradient(
                       gradient: Gradient(colors: colors),
                       center: .center,
                       startAngle: .degrees(0),
                       endAngle: .degrees(360)
                   ),
                   style: StrokeStyle(lineWidth: 6, lineCap: .round)
               )
               .frame(width: 25, height: 25)

            Circle()
                .frame(width: 7, height: 7)
                .foregroundColor(Color.white)
                .offset(x: 25/2)
        }
        .rotationEffect(.degrees(rotationAngle))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotationAngle = 360.0
            }
        }
        .onDisappear{
            rotationAngle = 0.0
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
    FrameCheckoutView(customerId: "", paymentAmount: 15000) { _ in }
}
