//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/19/25.
//

import SwiftUI
import Frame

enum IdentificationTypes: String, CaseIterable, Identifiable {
    case driversLicense = "Driver's License"
    case stateId = "State ID"
    case militaryId = "Military ID"
    case passport = "Passport"
    
    var id: String {
        return self.rawValue
    }
}

struct UserIdentificationView: View {
    enum IdentificationSelection: String, CaseIterable {
        case id
        case country
        case countryCode
    }
    
    enum UserIdentificationSteps: String, CaseIterable {
        case phoneAuth
        case verifyPhone
        case information
//        case inputs - Country input currently not in use.
    }
    
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel
    @StateObject private var personalAddressVM: BillingAddressViewModel
    @StateObject private var customerInfoVM: CustomerInformationViewModel

    @State private var identitySteps: UserIdentificationSteps = .phoneAuth
    @State private var selectedCountry: AvailableCountry = .defaultCountry
    @State private var showCountryPicker: Bool = false
    @State private var selectedIdType: IdentificationTypes = .driversLicense
    @State private var showIDPicker: Bool = false
    @State private var showPhoneCountryPicker: Bool = false
    @State private var isSendingOTP: Bool = false
    
    @State private var returnToPhoneNumberEntry: Bool = false
    @State private var continueToCustomerInfoStep: Bool = false
    
    @Binding var continueToNextStep: Bool
    @Binding var returnToPreviousStep: Bool

    let idTypes = IdentificationTypes.allCases

    init(onboardingContainerViewModel: OnboardingContainerViewModel,
         continueToNextStep: Binding<Bool>,
         returnToPreviousStep: Binding<Bool>) {
        self._onboardingContainerViewModel = StateObject(wrappedValue: onboardingContainerViewModel)
        self._continueToNextStep = continueToNextStep
        self._returnToPreviousStep = returnToPreviousStep
        self._personalAddressVM = StateObject(wrappedValue: BillingAddressViewModel(
            address: onboardingContainerViewModel.createdCustomerIdentity.address,
            mode: .international
        ))
        self._customerInfoVM = StateObject(wrappedValue: CustomerInformationViewModel(
            identity: onboardingContainerViewModel.createdCustomerIdentity,
            phoneCountry: onboardingContainerViewModel.phoneCountry
        ))
    }
    
    var body: some View {
        VStack {
            switch identitySteps {
            case .phoneAuth:
                authenticationView
            case .verifyPhone:
                SecurePMVerificationView(type: .phone,
                                         onboardingContainerViewModel: onboardingContainerViewModel,
                                         continueToNextStep: $continueToCustomerInfoStep,
                                         returnToPreviousStep: $returnToPhoneNumberEntry)
            case .information:
                customerInformationView
//            case .inputs:
//                verifyIdentityView
            }
        }
        .onChange(of: returnToPhoneNumberEntry, { oldValue, newValue in
            if returnToPhoneNumberEntry {
                self.identitySteps = .phoneAuth
                self.returnToPhoneNumberEntry = false
            }
        })
        .onChange(of: continueToCustomerInfoStep, { oldValue, newValue in
            if continueToCustomerInfoStep {
                self.identitySteps = .information
            }
        })
        .onChange(of: onboardingContainerViewModel.createdCustomerIdentity) { _, newValue in
            // Propagate async-hydrated identity (e.g. from checkExistingAccount) into the element VMs.
            customerInfoVM.identity = newValue
            personalAddressVM.address = newValue.address
        }
        .onChange(of: onboardingContainerViewModel.phoneCountry) { _, newValue in
            customerInfoVM.phoneCountry = newValue
        }
        .sheet(isPresented: $showIDPicker) {
            Picker(IdentificationSelection.id.rawValue, selection: $selectedIdType) {
                ForEach(IdentificationTypes.allCases, id: \.self) { id in
                    Text(id.rawValue)
                }
            }
            .pickerStyle(.wheel)
            .presentationDetents([.height(200.0)])
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(
                selectedCountry: $selectedCountry,
                isPresented: $showCountryPicker
            )
            .presentationDetents([.fraction(0.3)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPhoneCountryPicker) {
            PhoneCountryPickerSheet(
                selected: $onboardingContainerViewModel.phoneCountry,
                isPresented: $showPhoneCountryPicker
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { onboardingContainerViewModel.showProveOTPEntry },
            set: { if !$0 { onboardingContainerViewModel.cancelProveOTP() } }
        )) {
            SecurePMVerificationView(type: .proveOtp,
                                    onboardingContainerViewModel: onboardingContainerViewModel,
                                    continueToNextStep: .constant(false),
                                    returnToPreviousStep: .constant(false))
        }
    }
    
    var authenticationView: some View {
        VStack(alignment: .leading) {
            PageHeaderView(headerTitle: onboardingContainerViewModel.requiredCapabilities.contains(.kycPrefill) ? "Enter Your Phone Number & DOB" : "Enter Your Phone Number") {
                self.returnToPreviousStep.toggle()
            }
            .onAppear {
                if onboardingContainerViewModel.requiredCapabilities.contains(.geoCompliance) &&
                    onboardingContainerViewModel.termsOfServiceToken == nil {
                    Task {
                        await onboardingContainerViewModel.generateTermsOfServiceToken()
                    }
                }
            }
            Text("We’ll send you a code — it helps us keep your account secure.")
                .font(.system(size: 14.0))
                .foregroundColor(FrameColors.secondaryTextColor)
                .padding(.horizontal, 20.0)
                .padding(.bottom, 20.0)
            HStack {
                Text("Phone Number")
                    .fontWeight(.semibold)
                    .font(.system(size: 14.0))
                Spacer()
                if let phoneError = onboardingContainerViewModel.errorBinding(.authPhone).wrappedValue {
                    Text(phoneError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            HStack(alignment: .top, spacing: 0) {
                Button {
                    self.showPhoneCountryPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(onboardingContainerViewModel.phoneCountry.flag)
                        Text(onboardingContainerViewModel.phoneCountry.dialCode)
                            .fontWeight(.medium)
                            .font(.system(size: 14.0))
                            .foregroundColor(.primary)
                        Image("down-chevron", bundle: FrameResources.module)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .frame(width: 110.0)
                .padding([.horizontal, .bottom])

                RoundedRectangle(cornerRadius: 10.0)
                    .fill(.white)
                    .stroke(.gray.opacity(0.3))
                    .frame(maxHeight: 56.0)
                    .overlay {
                        PhoneNumberTextField(prompt: "Enter your phone number",
                                             text: $onboardingContainerViewModel.authPhoneNumber,
                                             error: onboardingContainerViewModel.errorBinding(.authPhone),
                                             regionCode: onboardingContainerViewModel.phoneCountry.alpha2,
                                             compactError: true)
                    }
            }
            .padding(.trailing)
            .padding(.leading, 5.0)
            if onboardingContainerViewModel.requiredCapabilities.contains(.kycPrefill) {
                HStack {
                    Text("Date of Birth")
                        .fontWeight(.semibold)
                        .font(.system(size: 14.0))
                    Spacer()
                    if let dobError = firstDateOfBirthError() {
                        Text(dobError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                RoundedRectangle(cornerRadius: 10.0)
                    .fill(.white)
                    .stroke(.gray.opacity(0.3))
                    .overlay {
                        HStack {
                            ValidatedTextField(prompt: "Month",
                                               text: $onboardingContainerViewModel.authBirthMonth,
                                               error: onboardingContainerViewModel.errorBinding(.authBirthMonth),
                                               keyboardType: .numberPad,
                                               characterLimit: 2,
                                               compactError: true)
                            Divider()
                            ValidatedTextField(prompt: "Day",
                                               text: $onboardingContainerViewModel.authBirthDay,
                                               error: onboardingContainerViewModel.errorBinding(.authBirthDay),
                                               keyboardType: .numberPad,
                                               characterLimit: 2,
                                               compactError: true)
                            Divider()
                            ValidatedTextField(prompt: "Year",
                                               text: $onboardingContainerViewModel.authBirthYear,
                                               error: onboardingContainerViewModel.errorBinding(.authBirthYear),
                                               keyboardType: .numberPad,
                                               characterLimit: 4,
                                               compactError: true)
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 55.0)
            }
            Spacer()
            if onboardingContainerViewModel.requiredCapabilities.contains(.geoCompliance) {
                TermsOfServiceView(padded: false)
                    .padding(.horizontal)
            }
            ContinueButton(enabled: .constant(!isSendingOTP)) {
                guard onboardingContainerViewModel.validateAllPhoneAuth() else { return }
                Task {
                    isSendingOTP = true
                    let dob = DateOfBirthFormatter.format(
                        year: onboardingContainerViewModel.authBirthYear,
                        month: onboardingContainerViewModel.authBirthMonth,
                        day: onboardingContainerViewModel.authBirthDay
                    )
                    await onboardingContainerViewModel.sendOTPVerification(phoneNumber: onboardingContainerViewModel.authPhoneNumber,
                                                                          dateOfBirth: dob)
                    isSendingOTP = false
                    if onboardingContainerViewModel.proveUserInfo != nil {
                        self.identitySteps = .information
                    } else if onboardingContainerViewModel.pendingTwilioVerificationId != nil {
                        self.identitySteps = .verifyPhone
                    }
                }
            }
            .padding(.bottom)
        }
    }

    var customerInformationView: some View {
        VStack(alignment: .leading) {
            PageHeaderView(headerTitle: "Personal Information") {
                self.identitySteps = .phoneAuth
            }
            ScrollView {
                CustomerInformationView(viewModel: customerInfoVM)
                BillingAddressDetailView(viewModel: personalAddressVM,
                                         headerTitle: "Current Address")
                KeyboardSpacing()
            }
            Spacer()
            ContinueButton(enabled: .constant(true)) {
                let infoOK = customerInfoVM.validate()
                let addressOK = personalAddressVM.validate()
                guard infoOK, addressOK else { return }
                onboardingContainerViewModel.createdCustomerIdentity = customerInfoVM.identity
                onboardingContainerViewModel.createdCustomerIdentity.address = personalAddressVM.address
                onboardingContainerViewModel.phoneCountry = customerInfoVM.phoneCountry
                Task {
                    if onboardingContainerViewModel.accountId == nil {
                        await onboardingContainerViewModel.createIndividualAccount()
                    } else {
                        await onboardingContainerViewModel.updateExistingIndividualAccount()
                    }
                    self.continueToNextStep.toggle()
                }
            }
            .padding(.bottom)
        }
    }
    
    private func firstDateOfBirthError() -> String? {
        return onboardingContainerViewModel.errorBinding(.authBirthMonth).wrappedValue
            ?? onboardingContainerViewModel.errorBinding(.authBirthDay).wrappedValue
            ?? onboardingContainerViewModel.errorBinding(.authBirthYear).wrappedValue
    }

    @ViewBuilder
    func dropdownSelectionBox(titleName: String, selection: IdentificationSelection, dropdownText: String) -> some View {
        VStack(alignment: .leading) {
            if titleName != "" {
                Text(titleName)
                    .padding([.horizontal])
                    .fontWeight(.semibold)
                    .font(.system(size: 13.0))
            }
            HStack {
                Text(dropdownText)
                    .fontWeight(.medium)
                    .font(.system(size: 14.0))
                    .frame(minWidth: 18.0)
                    .padding(.leading)
                Spacer()
                Image("down-chevron", bundle: FrameResources.module)
                    .padding(.trailing)
            }
            .frame(maxWidth: .infinity, minHeight: 56.0)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding([.horizontal, .bottom])
            .onTapGesture {
                switch selection {
                case .id:
                    self.showIDPicker.toggle()
                case .country:
                    self.showCountryPicker.toggle()
                case .countryCode:
                    return
                }
            }
        }
    }
}

#Preview {
    UserIdentificationView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: [.kycPrefill]), continueToNextStep: .constant(false), returnToPreviousStep: .constant(false))
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
