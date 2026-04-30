//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import Frame

struct BillingAddressDetailView: View {
    @ObservedObject var viewModel: OnboardingContainerViewModel
    let addressNamespace: AddressNamespace

    @Binding var addressLineOne: String
    @Binding var addressLineTwo: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    @Binding var country: String

    @State var headerTitle: String = "Billing Address"
    @State var headerFont: Font = Font.subheadline
    @State var showHeaderText: Bool = true

    @State private var selectedCountry: AvailableCountry = .defaultCountry
    @State private var countryText: String = ""
    @State private var showCountryPicker: Bool = false

    init(viewModel: OnboardingContainerViewModel,
         addressNamespace: AddressNamespace,
         addressLineOne: Binding<String>,
         addressLineTwo: Binding<String>,
         city: Binding<String>,
         state: Binding<String>,
         zipCode: Binding<String>,
         country: Binding<String>,
         headerTitle: String = "Billing Address",
         showHeaderText: Bool = true) {
        self.viewModel = viewModel
        self.addressNamespace = addressNamespace
        self._addressLineOne = addressLineOne
        self._addressLineTwo = addressLineTwo
        self._city = city
        self._state = state
        self._zipCode = zipCode
        self._country = country
        self._headerTitle = State(initialValue: headerTitle)
        self._showHeaderText = State(initialValue: showHeaderText)
    }

    private var allowsInternational: Bool { addressNamespace == .personal }

    private var format: AddressFormat {
        allowsInternational
            ? AddressFormat.format(forCountry: selectedCountry.alpha2Code)
            : AddressFormat.format(forCountry: "US")
    }

    private var fields: (line1: OnboardingField, city: OnboardingField, state: OnboardingField, postal: OnboardingField) {
        switch addressNamespace {
        case .personal: return (.personalAddressLine1, .personalCity, .personalState, .personalPostal)
        case .payment:  return (.paymentAddressLine1, .paymentCity, .paymentState, .paymentPostal)
        case .payout:   return (.payoutAddressLine1, .payoutCity, .payoutState, .payoutPostal)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            if showHeaderText {
                Text(headerTitle)
                    .bold()
                    .font(headerFont)
                    .padding([.horizontal, .top])
            }
            RoundedRectangle(cornerRadius: 10.0)
                .fill(.white)
                .stroke(.gray.opacity(0.3))
                .frame(height: 250.0)
                .overlay {
                    VStack(spacing: 0) {
                        ValidatedTextField(prompt: "Address Line 1",
                                           text: $addressLineOne,
                                           error: viewModel.errorBinding(fields.line1))
                        Divider()
                        ValidatedTextField(prompt: "Address Line 2",
                                           text: $addressLineTwo,
                                           error: .constant(nil))
                        Divider()
                        HStack {
                            ValidatedTextField(prompt: "City",
                                               text: $city,
                                               error: viewModel.errorBinding(fields.city))
                            Divider()
                            ValidatedTextField(prompt: format.stateLabel,
                                               text: $state,
                                               error: viewModel.errorBinding(fields.state),
                                               characterLimit: format.stateMaxLength)
                        }
                        .frame(height: 49.0)
                        Divider()
                        ValidatedTextField(prompt: format.postalLabel,
                                           text: $zipCode,
                                           error: viewModel.errorBinding(fields.postal),
                                           keyboardType: format.postalKeyboard,
                                           characterLimit: addressNamespace == .personal ? nil : 5)
                        if allowsInternational {
                            DropDownWithHeaderView(headerText: .constant(""),
                                                   dropDownText: $countryText,
                                                   showDropdownPicker: $showCountryPicker,
                                                   showHeaderText: false,
                                                   showDropdownBorder: false)
                        }
                    }
                }
                .padding(.horizontal)
        }
        .onAppear {
            if !allowsInternational {
                self.country = "US"
                if let us = AvailableCountry.allCountries.first(where: { $0.alpha2Code == "US" }) {
                    self.selectedCountry = us
                }
            }
            if !country.isEmpty,
               let match = AvailableCountry.allCountries.first(where: { $0.alpha2Code == country }) {
                self.selectedCountry = match
            }
            self.country = selectedCountry.alpha2Code
            self.countryText = selectedCountry.displayName
        }
        .onChange(of: selectedCountry) { _, _ in
            self.country = selectedCountry.alpha2Code
            self.countryText = selectedCountry.displayName
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(
                selectedCountry: $selectedCountry,
                isPresented: $showCountryPicker
            )
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
    }
}
