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
        case intro
        case information
        case inputs
    }
    
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel
    
    @State private var identitySteps: UserIdentificationSteps = .intro
    @State private var selectedCountry: AvailableCountry = .defaultCountry
    @State private var phoneNumber: String = ""
    @State private var birthYear: String = ""
    @State private var birthMonth: String = ""
    @State private var birthDay: String = ""
    @State private var showCountryPicker: Bool = false
    @State private var selectedIdType: IdentificationTypes = .driversLicense
    @State private var showIDPicker: Bool = false
    @State private var canVerifyPhoneNumber: Bool = false
    @State private var canCustomerContinue: Bool = false
    @State private var dateOfBirth: String = ""
    
    @State private var returnToPhoneNumberEntry: Bool = false
    @State private var continueToCustomerInfoStep: Bool = false
    
    @Binding var continueToNextStep: Bool
    
    let idTypes = IdentificationTypes.allCases
    
    var body: some View {
        VStack {
            switch identitySteps {
            case .phoneAuth:
                authenticationView
            case .verifyPhone:
                SecurePMVerificationView(onboardingContainerViewModel: onboardingContainerViewModel,
                                         continueToNextStep: $continueToCustomerInfoStep,
                                         returnToPreviousStep: $returnToPhoneNumberEntry)
            case .intro:
                identityIntro
                    .onAppear {
                        Task {
                            //TODO: Check steps/capabilities at the account level before preceding.
                            await onboardingContainerViewModel.checkExistingAccount()
                        }
                    }
            case .information:
                customerInformationView
            case .inputs:
                verifyIdentityView
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
        .onChange(of: onboardingContainerViewModel.createdCustomerIdentity) { oldValue, newValue in
            self.canCustomerContinue = onboardingContainerViewModel.checkIfCustomerCanContinueWithPersonalInformation()
        }
        .onChange(of: birthYear, { oldValue, newValue in
            self.dateOfBirth = "\(birthYear)-\(birthMonth)-\(birthDay)"
        })
        .onChange(of: birthMonth, { oldValue, newValue in
            self.dateOfBirth = "\(birthYear)-\(birthMonth)-\(birthDay)"
        })
        .onChange(of: birthDay, { oldValue, newValue in
            self.dateOfBirth = "\(birthYear)-\(birthMonth)-\(birthDay)"
        })
        .onChange(of: phoneNumber, { oldValue, newValue in
            self.checkIfReadyToVerifyPhoneNumber()
        })
        .onChange(of: dateOfBirth, { oldValue, newValue in
            self.checkIfReadyToVerifyPhoneNumber()
        })
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
    }
    
    var identityIntro: some View {
        VStack(spacing: 15.0) {
            Spacer()
            Image("shield-icon", bundle: FrameResources.module)
            Text("Verify Your Identity")
                .font(.system(size: 18.0))
                .fontWeight(.semibold)
            Text("We’re required by law to verify your identity. This takes about 2 minutes and you’ll need a Government ID and a selfie.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14.0))
                .foregroundColor(FrameColors.secondaryTextColor)
                .padding(.horizontal, 24.0)
            Spacer()
            ContinueButton(enabled: .constant(true)) {
                self.identitySteps = .phoneAuth
            }
            .padding(.bottom)
        }
    }
    
    var authenticationView: some View {
        VStack(alignment: .leading) {
            PageHeaderView(headerTitle: "Add Phone Number & DOB") {
                self.identitySteps = .intro
            }
            Text("We’ll send you a code — it helps us keep your account secure.")
                .font(.system(size: 14.0))
                .foregroundColor(FrameColors.secondaryTextColor)
                .padding(.horizontal, 20.0)
                .padding(.bottom, 20.0)
            Text("Phone Number")
                .padding(.horizontal)
                .fontWeight(.semibold)
                .font(.system(size: 14.0))
            HStack(alignment: .top, spacing: 0) {
                dropdownSelectionBox(titleName: "", selection: .countryCode, dropdownText: "+1")
                    .frame(width: 100.0)
                RoundedRectangle(cornerRadius: 10.0)
                    .fill(.white)
                    .stroke(.gray.opacity(0.3))
                    .frame(maxHeight: 56.0)
                    .overlay {
                        ReusableFormTextField(prompt: "Enter your phone number", text: $phoneNumber, showDivider: false, keyboardType: .numberPad, characterLimit: 10)
                    }
            }
            .padding(.trailing)
            .padding(.leading, 5.0)
            
            Text("Date of Birth")
                .padding(.horizontal)
                .fontWeight(.semibold)
                .font(.system(size: 14.0))
            RoundedRectangle(cornerRadius: 10.0)
                .fill(.white)
                .stroke(.gray.opacity(0.3))
                .overlay {
                    VStack(spacing: 0) {
                        HStack {
                            ReusableFormTextField(prompt: "Month", text: $birthMonth, showDivider: false, keyboardType: .numberPad, characterLimit: 2)
                            Divider()
                            ReusableFormTextField(prompt: "Day", text: $birthDay, showDivider: false, keyboardType: .numberPad, characterLimit: 2)
                            Divider()
                            ReusableFormTextField(prompt: "Year", text: $birthYear, showDivider: false, keyboardType: .numberPad, characterLimit: 4)
                        }
                    }
                }
                .padding(.horizontal)
                .frame(height: 55.0)
            Spacer()
            ContinueButton(enabled: .constant(canVerifyPhoneNumber)) {
                Task {
                    //TODO: Prove SDK OTP flow.
                    self.identitySteps = .verifyPhone
                }
            }
            .padding(.bottom)
        }
    }
    
    var customerInformationView: some View {
        VStack(alignment: .leading) {
            PageHeaderView(headerTitle: "Personal Information") {
                self.identitySteps = .intro
            }
            ScrollView {
                CustomerInformationView(emailAddress: $onboardingContainerViewModel.createdCustomerIdentity.email,
                                        phoneNumber: $onboardingContainerViewModel.createdCustomerIdentity.phoneNumber,
                                        firstName: $onboardingContainerViewModel.createdCustomerIdentity.firstName,
                                        lastName: $onboardingContainerViewModel.createdCustomerIdentity.lastName,
                                        dateOfBirth: $onboardingContainerViewModel.createdCustomerIdentity.dateOfBirth,
                                        ssn: $onboardingContainerViewModel.createdCustomerIdentity.ssn)
                BillingAddressDetailView(addressLineOne: $onboardingContainerViewModel.createdCustomerIdentity.address.addressLine1.orEmpty,
                                         addressLineTwo: $onboardingContainerViewModel.createdCustomerIdentity.address.addressLine2.orEmpty,
                                         city: $onboardingContainerViewModel.createdCustomerIdentity.address.city.orEmpty,
                                         state: $onboardingContainerViewModel.createdCustomerIdentity.address.state.orEmpty,
                                         zipCode: $onboardingContainerViewModel.createdCustomerIdentity.address.postalCode,
                                         country: $onboardingContainerViewModel.createdCustomerIdentity.address.country.orEmpty,
                                         headerTitle: "Current Address")
                KeyboardSpacing()
            }
            Spacer()
            ContinueButton(enabled: $canCustomerContinue) {
                Task {
                    if onboardingContainerViewModel.accountId == nil {
                        await onboardingContainerViewModel.createIndividualAccount()
                    } else {
                        await onboardingContainerViewModel.updateExistingIndividualAccount()
                    }
                    await onboardingContainerViewModel.createCustomerIdentity()
                    self.continueToNextStep.toggle()
                }
            }
            .padding(.bottom)
        }
    }
    
    var verifyIdentityView: some View {
        VStack(alignment: .leading) {
            PageHeaderView(headerTitle: "Verify Your ID") {
                self.identitySteps = .intro
            }
            Text("We’re required by law to verify your identity. This takes about 2 minutes and you’ll need a Government ID and a selfie.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14.0))
                .foregroundColor(FrameColors.secondaryTextColor)
                .padding(.horizontal, 20.0)
                .padding(.bottom, 8.0)
            dropdownSelectionBox(titleName: "Issuing Country", selection: .country, dropdownText: selectedCountry.displayName)
            dropdownSelectionBox(titleName: "ID Type", selection: .id, dropdownText: selectedIdType.rawValue)
            
            Spacer()
            ContinueButton(enabled: .constant(true)) {
                Task {
                    //TODO: Figure out what to do with this information on the account level.
//                    await onboardingContainerViewModel.createOnboardingSession(selectedIdType: selectedIdType,
//                                                                               selectedCountry: selectedCountry)
                    self.identitySteps = .information
                }
            }
            .padding(.bottom)
        }
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
    
    func checkIfReadyToVerifyPhoneNumber() {
        self.canVerifyPhoneNumber = birthDay.count == 2 && birthMonth.count == 2 && birthYear.count == 4 && phoneNumber.count == 10
    }
}

#Preview {
    UserIdentificationView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []), continueToNextStep: .constant(false))
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
