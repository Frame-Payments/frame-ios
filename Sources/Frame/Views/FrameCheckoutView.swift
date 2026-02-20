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
    @StateObject var checkoutViewModel: FrameCheckoutViewModel = FrameCheckoutViewModel()
    
    @State private var rotationAngle = 0.0
    @State var showLoadingState: Bool = false
    @State var useBlackButtons: Bool = true
    @State var saveCardForPayments: Bool = false
    @State private var isShowingPicker = false
    
    let customerId: String?
    let paymentAmount: Int
    
    var colors: [Color] = [Color.white, Color.white.opacity(0.3)]
    
    var checkoutCallback: (FrameObjects.ChargeIntent) -> ()
    
    public init(customerId: String?, paymentAmount: Int, checkoutCallback: @escaping (FrameObjects.ChargeIntent) -> ()) {
        self.customerId = customerId
        self.paymentAmount = paymentAmount
        self.checkoutCallback = checkoutCallback
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            topHeaderBar
            Divider()
            ScrollView {
//                paymentButtons - Hiding Apple & Google Pay buttons until we add the implementation
//                paymentDivider
                if checkoutViewModel.customerPaymentOptions != nil {
                    existingPaymentCardScroll
                        .padding([.leading, .bottom])
                }
                customerInformation
                    .padding(.bottom)
                cardInformation
                    .padding(.bottom)
                regionInformation
                checkoutButton
                Spacer()
            }
        }
        .task {
            await checkoutViewModel.loadCustomerPaymentMethods(customerId: customerId, amount: paymentAmount)
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
    
    var paymentDivider: some View {
        HStack(spacing: 10.0) {
            Rectangle().fill(.gray.opacity(0.3))
                .frame(height: 1)
            Text("Or")
            Rectangle().fill(.gray.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    var paymentButtons: some View {
        FramePaymentButton(blackButton: useBlackButtons, paymentOption: .apple) {
            checkoutViewModel.payWithApplePay()
        }
        FramePaymentButton(blackButton: useBlackButtons, paymentOption: .google) {
            checkoutViewModel.payWithGooglePay()
        }
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
    }
    
    @ViewBuilder
    var customerInformation: some View {
        Text("Customer Information")
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.headline)
            .foregroundColor(.gray)
            .padding(.horizontal)
        RoundedRectangle(cornerRadius: 10.0)
            .fill(.white)
            .stroke(.gray.opacity(0.3))
            .frame(height: 99.0)
            .overlay {
                VStack(spacing: 0) {
                    TextField("",
                              text: $checkoutViewModel.customerName,
                              prompt: Text("Customer Name"))
                    .frame(height: 49.0)
                    .padding(.horizontal)
                    Divider()
                    TextField("",
                              text: $checkoutViewModel.customerEmail,
                              prompt: Text("Customer Email"))
                    .frame(height: 49.0)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
    }
    
    @ViewBuilder
    var regionInformation: some View {
        Text("Customer Address")
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.headline)
            .foregroundColor(.gray)
            .padding(.horizontal)
        RoundedRectangle(cornerRadius: 10.0)
            .fill(.white)
            .stroke(.gray.opacity(0.3))
            .frame(height: 245.0)
            .overlay {
                VStack(spacing: 0) {
                    TextField("",
                              text: $checkoutViewModel.customerAddressLine1,
                              prompt: Text("Address Line 1"))
                    .frame(height: 49.0)
                    .padding(.horizontal)
                    Divider()
                    TextField("",
                              text: $checkoutViewModel.customerAddressLine2,
                              prompt: Text("Address Line 2"))
                    .frame(height: 49.0)
                    .padding(.horizontal)
                    Divider()
                    HStack {
                        TextField("",
                                  text: $checkoutViewModel.customerCity,
                                  prompt: Text("City"))
                        .frame(height: 49.0)
                        .padding(.horizontal)
                        TextField("",
                                  text: $checkoutViewModel.customerState,
                                  prompt: Text("State"))
                        .frame(height: 49.0)
                        .padding(.horizontal)
                    }
                    .frame(height: 49.0)
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
                    TextField("",
                              text: $checkoutViewModel.customerZipCode.max(5),
                              prompt: Text("Zip Code"))
                    .frame(height: 49.0)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
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
        Button {
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
                .fill(.black)
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
        .disabled(showLoadingState)
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
}

#Preview {
    FrameCheckoutView(customerId: "", paymentAmount: 15000) { _ in }
}
