//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/19/25.
//

import SwiftUI
import UIKit
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

    @Environment(\.frameTheme) private var theme
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel
    @StateObject private var personalAddressVM: BillingAddressViewModel
    @StateObject private var customerInfoVM: CustomerInformationViewModel

    @State private var identitySteps: UserIdentificationSteps = .phoneAuth
    @State private var selectedCountry: AvailableCountry = .defaultCountry
    @State private var showCountryPicker: Bool = false
    @State private var selectedIdType: IdentificationTypes = .driversLicense
    @State private var showIDPicker: Bool = false
    @State private var showPhoneCountryPicker: Bool = false

    @State private var returnToPhoneNumberEntry: Bool = false
    @State private var continueToCustomerInfoStep: Bool = false
    @State private var authBirthDate: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var showAuthBirthDatePicker: Bool = false
    @FocusState private var phoneFieldFocused: Bool

    private var authDobRange: ClosedRange<Date> {
        let min = Calendar.current.date(byAdding: .year, value: -120, to: Date()) ?? Date.distantPast
        return min...Date()
    }
    /// Set by the Prove OTP sheet once it has fallen back to Twilio and the typed code verified.
    @State private var proveSheetVerified: Bool = false
    /// Set when the fallback sheet's back button asks to close it.
    @State private var proveSheetDismissed: Bool = false
    
    @Binding var continueToNextStep: Bool
    @Binding var returnToPreviousStep: Bool
    /// Whether the phone-auth screen can navigate back out of this step (intro or a prior flow step).
    var showsContainerBackButton: Bool

    let idTypes = IdentificationTypes.allCases

    init(onboardingContainerViewModel: OnboardingContainerViewModel,
         continueToNextStep: Binding<Bool>,
         returnToPreviousStep: Binding<Bool>,
         showsContainerBackButton: Bool = true) {
        self._onboardingContainerViewModel = StateObject(wrappedValue: onboardingContainerViewModel)
        self._continueToNextStep = continueToNextStep
        self._returnToPreviousStep = returnToPreviousStep
        self.showsContainerBackButton = showsContainerBackButton
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
            set: { presented in
                guard !presented else { return }
                // After the Twilio fallback the Prove SDK is no longer waiting on anything, so a
                // swipe-down closes the sheet rather than cancelling a continuation that's gone.
                if onboardingContainerViewModel.proveSheetFellBackToTwilio {
                    onboardingContainerViewModel.dismissProveOTPSheet()
                } else {
                    onboardingContainerViewModel.cancelProveOTP()
                }
            }
        )) {
            // Prove can fail while this sheet is up; the fallback keeps it presented and swaps it
            // to Twilio entry so the applicant keeps a code screen instead of watching one vanish.
            SecurePMVerificationView(type: onboardingContainerViewModel.proveSheetFellBackToTwilio ? .phone : .proveOtp,
                                    onboardingContainerViewModel: onboardingContainerViewModel,
                                    continueToNextStep: $proveSheetVerified,
                                    returnToPreviousStep: $proveSheetDismissed)
        }
        .onChange(of: proveSheetDismissed) { _, dismissed in
            // `.phone`'s back button routes through returnToPreviousStep; in the fallback sheet
            // that means "close me", leaving the applicant on the phone form to start over.
            if dismissed {
                onboardingContainerViewModel.dismissProveOTPSheet()
                self.proveSheetDismissed = false
            }
        }
        .onChange(of: proveSheetVerified) { _, verified in
            // The Twilio code entered in the fallback sheet was accepted — close the sheet and
            // continue from the step the phone form would have advanced to.
            if verified {
                onboardingContainerViewModel.dismissProveOTPSheet()
                self.proveSheetVerified = false
                self.identitySteps = .information
            }
        }
    }
    
    var authenticationView: some View {
        VStack(alignment: .leading) {
            PageHeaderView(showsBackButton: showsContainerBackButton,
                           headerTitle: "Verify your phone number with a code") {
                self.returnToPreviousStep.toggle()
            }
            .onAppear {
                if onboardingContainerViewModel.termsOfServiceToken == nil {
                    Task {
                        await onboardingContainerViewModel.generateTermsOfServiceToken()
                    }
                }
                seedAuthBirthDate()
            }
            .onChange(of: authBirthDate) { _, newValue in
                syncAuthBirthDate(newValue)
            }
            Text("We'll text you a 6-digit code to confirm it's you.")
                .font(theme.fonts.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
                .padding(.horizontal, 20.0)
                .padding(.bottom, 20.0)
            HStack {
                Text("Phone number")
                    .fontWeight(.semibold)
                    .font(theme.fonts.bodySmall)
                Spacer()
                if let phoneError = onboardingContainerViewModel.errorBinding(.authPhone).wrappedValue {
                    Text(phoneError)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.colors.error)
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
                            .font(theme.fonts.bodySmall)
                            .foregroundColor(.primary)
                        Image("down-chevron", bundle: FrameResources.module)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.medium)
                            .strokeBorder(theme.colors.surfaceStroke, lineWidth: 1)
                    )
                }
                .frame(width: 110.0)
                .padding([.horizontal, .bottom])

                RoundedRectangle(cornerRadius: theme.radii.medium)
                    .fill(theme.colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.medium)
                            .strokeBorder(
                                phoneFieldFocused ? theme.colors.fieldFocusStroke : theme.colors.surfaceStroke,
                                lineWidth: phoneFieldFocused ? 1.5 : 1
                            )
                    )
                    .frame(maxHeight: 56.0)
                    .overlay {
                        PhoneNumberTextField(prompt: "Enter your phone number",
                                             text: $onboardingContainerViewModel.authPhoneNumber,
                                             error: onboardingContainerViewModel.errorBinding(.authPhone),
                                             regionCode: onboardingContainerViewModel.phoneCountry.alpha2,
                                             compactError: true,
                                             showsBorder: false,
                                             focused: $phoneFieldFocused)
                    }
            }
            .padding(.trailing)
            .padding(.leading, 5.0)
            if onboardingContainerViewModel.requiredCapabilities.contains(.kycPrefill) {
                HStack {
                    Text("Date of Birth")
                        .font(theme.fonts.label)
                    Spacer()
                    if let dobError = firstDateOfBirthError() {
                        Text(dobError)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.colors.error)
                    }
                }
                .padding(.horizontal)
                Button {
                    showAuthBirthDatePicker = true
                } label: {
                    HStack {
                        Text(authBirthDate, format: .dateTime.month().day().year())
                            .font(theme.fonts.body)
                            .foregroundStyle(theme.colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, minHeight: 55)
                    .background(theme.colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.medium)
                            .stroke(theme.colors.surfaceStroke)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .sheet(isPresented: $showAuthBirthDatePicker) {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button("Done") { showAuthBirthDatePicker = false }
                                .font(theme.fonts.button)
                                .padding()
                        }
                        DatePicker(
                            "",
                            selection: $authBirthDate,
                            in: authDobRange,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.horizontal)
                    }
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
                }
            }
            Spacer()
            if onboardingContainerViewModel.requiredCapabilities.contains(.geoCompliance) {
                TermsOfServiceView(padded: false)
                    .padding(.horizontal)
                    .onAppear {
                        AccountEventEmitter.emit(name: .termsOfServiceShown, screen: .termsOfService)
                    }
            }
            ContinueButton(isLoading: .constant(onboardingContainerViewModel.isPerformingAction)) {
                guard onboardingContainerViewModel.validateAllPhoneAuth() else { return }
                if onboardingContainerViewModel.requiredCapabilities.contains(.geoCompliance) {
                    AccountEventEmitter.emit(name: .termsOfServiceAccepted, screen: .termsOfService)
                }
                Task {
                    let dob = DateOfBirthFormatter.format(
                        year: onboardingContainerViewModel.authBirthYear,
                        month: onboardingContainerViewModel.authBirthMonth,
                        day: onboardingContainerViewModel.authBirthDay
                    )
                    let phoneNumber = onboardingContainerViewModel.phoneCountry.dialCode + onboardingContainerViewModel.authPhoneNumber.replacingOccurrences(of: " ", with: "")
                    await onboardingContainerViewModel.sendOTPVerification(phoneNumber: phoneNumber,
                                                                          dateOfBirth: dob)
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
            PageHeaderView(headerTitle: "Verify your personal info") {
                self.identitySteps = .phoneAuth
            }
            .onAppear {
                AccountEventEmitter.emit(name: .profileStepStarted, screen: .personalInformation)
            }
            ScrollView {
                personalInfoIntro
                CustomerInformationView(viewModel: customerInfoVM,
                                        onboardingContainerViewModel: onboardingContainerViewModel,
                                        headerTitle: "Legal name")
                BillingAddressDetailView(viewModel: personalAddressVM,
                                         headerTitle: "Home address")
                KeyboardSpacing()
            }
            // The address form's autocomplete list is drawn past the form's own bounds. The
            // button below is a sibling of this ScrollView, so without lifting the scroll view
            // the button paints over the suggestions.
            .zIndex(1)
            Spacer()
            ContinueButton(isLoading: .constant(onboardingContainerViewModel.isPerformingAction)) {
                let infoOK = customerInfoVM.validate()
                let addressOK = personalAddressVM.validate()
                guard infoOK, addressOK else {
                    AccountEventEmitter.emit(name: .profileValidationFailed, screen: .personalInformation,
                                             detail: "info valid: \(infoOK), address valid: \(addressOK)")
                    return
                }
                personalAddressVM.normalize()
                onboardingContainerViewModel.createdCustomerIdentity = customerInfoVM.identity
                onboardingContainerViewModel.createdCustomerIdentity.address = personalAddressVM.address
                onboardingContainerViewModel.phoneCountry = customerInfoVM.phoneCountry
                Task {
                    guard let presenter = UIApplication.shared.topViewController else { return }
                    switch await onboardingContainerViewModel.submitPersonalInformation(from: presenter) {
                    case .advance:
                        self.continueToNextStep.toggle()
                    case .stay:
                        break
                    case .blocked(let outcome):
                        // Land on the terminal screen, or finish outright when the host has its own.
                        if !onboardingContainerViewModel.concludeOnboarding(with: outcome) {
                            self.continueToNextStep.toggle()
                        }
                    }
                }
            }
            .padding(.bottom)
        }
    }

    private var personalInfoIntro: some View {
        Text(personalInfoIntroText)
            .font(theme.fonts.bodySmall)
            .foregroundStyle(theme.colors.textSecondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.bottom, theme.spacing.sectionGap)
    }

    private var personalInfoIntroText: AttributedString {
        var result = AttributedString(
            "This information is collected to verify your identity, keep your account safe, and help meet legal regulatory requirements. For more information, review Frame's "
        )
        var privacy = AttributedString("Privacy Policy")
        privacy.link = LegalConfiguration.privacyURL
        privacy.underlineStyle = .single
        privacy.foregroundColor = UIColor(theme.colors.textPrimary)
        result.append(privacy)
        result.append(AttributedString("."))
        return result
    }
    
    private func firstDateOfBirthError() -> String? {
        return onboardingContainerViewModel.errorBinding(.authBirthMonth).wrappedValue
            ?? onboardingContainerViewModel.errorBinding(.authBirthDay).wrappedValue
            ?? onboardingContainerViewModel.errorBinding(.authBirthYear).wrappedValue
    }

    private func seedAuthBirthDate() {
        let y = onboardingContainerViewModel.authBirthYear
        let m = onboardingContainerViewModel.authBirthMonth
        let d = onboardingContainerViewModel.authBirthDay
        guard let year = Int(y), let month = Int(m), let day = Int(d) else { return }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        if let date = Calendar.current.date(from: comps) {
            authBirthDate = date
        }
    }

    private func syncAuthBirthDate(_ date: Date) {
        let calendar = Calendar.current
        onboardingContainerViewModel.authBirthYear = String(calendar.component(.year, from: date))
        onboardingContainerViewModel.authBirthMonth = String(format: "%02d", calendar.component(.month, from: date))
        onboardingContainerViewModel.authBirthDay = String(format: "%02d", calendar.component(.day, from: date))
    }

    @ViewBuilder
    func dropdownSelectionBox(titleName: String, selection: IdentificationSelection, dropdownText: String) -> some View {
        VStack(alignment: .leading) {
            if titleName != "" {
                Text(titleName)
                    .padding([.horizontal])
                    .fontWeight(.semibold)
                    .font(theme.fonts.caption)
            }
            HStack {
                Text(dropdownText)
                    .fontWeight(.medium)
                    .font(theme.fonts.bodySmall)
                    .frame(minWidth: 18.0)
                    .padding(.leading)
                Spacer()
                Image("down-chevron", bundle: FrameResources.module)
                    .padding(.trailing)
            }
            .frame(maxWidth: .infinity, minHeight: 56.0)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.medium)
                    .stroke(theme.colors.surfaceStroke, lineWidth: 1)
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

#Preview("Dark") {
    UserIdentificationView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: [.kycPrefill]), continueToNextStep: .constant(false), returnToPreviousStep: .constant(false))
        .preferredColorScheme(.dark)
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
