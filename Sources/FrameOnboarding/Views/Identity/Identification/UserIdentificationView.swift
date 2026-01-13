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
    }
    
    enum UserIdentificationSteps: String, CaseIterable {
        case intro
        case information
        case inputs
    }
    
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel
    
    @State private var identitySteps: UserIdentificationSteps = .intro
    @State private var selectedCountry: AvailableCountry = .defaultCountry
    @State private var showCountryPicker: Bool = false
    @State private var selectedIdType: IdentificationTypes = .driversLicense
    @State private var showIDPicker: Bool = false
    @State private var canCustomerContinue: Bool = false
    
    @Binding var continueToNextStep: Bool
    
    let idTypes = IdentificationTypes.allCases
    
    var body: some View {
        VStack {
            switch identitySteps {
            case .intro:
                identityIntro
                    .onAppear {
                        Task {
                            await onboardingContainerViewModel.checkExistingOnboardingSession()
                            await onboardingContainerViewModel.checkExistingCustomer()
                        }
                    }
            case .information:
                customerInformationView
            case .inputs:
                verifyIdentityView
            }
        }
        
        .onChange(of: onboardingContainerViewModel.createdCustomerIdentity) { oldValue, newValue in
            self.canCustomerContinue = onboardingContainerViewModel.checkIfCustomerCanContinueWithPersonalInformation()
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
            CountryPickerSheet(selectedCountry: $selectedCountry,
                               isPresented: $showCountryPicker,
                               restrictedCountries: AvailableCountry.restrictedCountries)
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
                .foregroundColor(secondaryTextColor)
                .padding(.horizontal, 24.0)
            Spacer()
            ContinueButton(enabled: .constant(true)) {
                self.identitySteps = .inputs
            }
            .padding(.bottom)
        }
    }
    
    var customerInformationView: some View {
        VStack(alignment: .leading) {
            PageHeaderView(headerTitle: "Personal Information") {
                self.identitySteps = .inputs
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
            }
            Spacer()
            ContinueButton(enabled: $canCustomerContinue) {
                Task {
                    await onboardingContainerViewModel.updateExistingCustomer()
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
                .foregroundColor(secondaryTextColor)
                .padding(.horizontal, 20.0)
                .padding(.bottom, 8.0)
            dropdownSelectionBox(titleName: "Issuing Country", selection: .country)
            dropdownSelectionBox(titleName: "ID Type", selection: .id)
            
            Spacer()
            ContinueButton(enabled: .constant(true)) {
                Task {
                    await onboardingContainerViewModel.createOnboardingSession(selectedIdType: selectedIdType,
                                                                               selectedCountry: selectedCountry)
                    self.identitySteps = .information
                }
            }
            .padding(.bottom)
        }
    }
    
    @ViewBuilder
    func dropdownSelectionBox(titleName: String, selection: IdentificationSelection) -> some View {
        Text(titleName)
            .padding([.horizontal])
            .fontWeight(.semibold)
            .font(.system(size: 13.0))
        HStack {
            Text(selection == .id ? selectedIdType.rawValue : selectedCountry.displayName)
                .fontWeight(.medium)
                .font(.system(size: 14.0))
                .padding()
            Spacer()
            Image("down-chevron", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 42.0)
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
            }
        }
    }
}

#Preview {
    UserIdentificationView(onboardingContainerViewModel: OnboardingContainerViewModel(customerId: "", components: SessionComponents()), continueToNextStep: .constant(false))
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
