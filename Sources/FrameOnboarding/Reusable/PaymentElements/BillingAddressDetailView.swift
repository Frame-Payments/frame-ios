//
//  BillingAddressDetailView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import Frame

/// A SwiftUI view that renders a validated billing-address form for use in onboarding payment flows.
///
/// The view adapts its field layout and labels to the selected country when operating in
/// international mode, and restricts entry to US-only addresses when in US-only mode.
/// Validation errors are surfaced inline beneath each field via the bound ``BillingAddressViewModel``.
public struct BillingAddressDetailView: View {
    @Environment(\.frameTheme) private var theme
    @ObservedObject var viewModel: BillingAddressViewModel

    @State private var headerTitle: String
    @State private var showHeaderText: Bool

    @State private var selectedCountry: AvailableCountry = .defaultCountry
    @State private var countryText: String = ""
    @State private var showCountryPicker: Bool = false
    @State private var showSubregionPicker: Bool = false

    /// Creates a billing-address detail view.
    ///
    /// - Parameters:
    ///   - viewModel: The view model that owns the address data and validation state.
    ///   - headerTitle: The section heading displayed above the address fields. Defaults to `"Billing Address"`.
    ///   - showHeaderText: When `false`, the section heading is hidden. Defaults to `true`.
    public init(viewModel: BillingAddressViewModel,
                headerTitle: String = "Billing Address",
                showHeaderText: Bool = true) {
        self.viewModel = viewModel
        self._headerTitle = State(initialValue: headerTitle)
        self._showHeaderText = State(initialValue: showHeaderText)
    }

    private var allowsInternational: Bool { viewModel.mode == .international }

    /// Fills the billing address fields from a picked autocomplete suggestion.
    ///
    /// Address line 2 is left alone: Mapbox does not reliably return apartment or unit, so
    /// whatever the user typed there stands.
    ///
    /// The country is written through `selectedCountry` rather than `viewModel.address.country`,
    /// because the view holds the picker's selection and its `onChange` is what keeps the two in
    /// step. Writing the model directly would leave the picker showing the old country. A US-only
    /// form ignores the country outright, and any country the picker does not offer is dropped.
    private func apply(_ address: FrameObjects.BillingAddress) {
        if let line1 = address.addressLine1 { viewModel.address.addressLine1 = line1 }
        if let city = address.city { viewModel.address.city = city }
        if let state = address.state { viewModel.address.state = state }
        viewModel.address.postalCode = address.postalCode

        if allowsInternational,
           let code = address.country,
           let match = AvailableCountry.allCountries.first(where: { $0.alpha2Code == code }) {
            selectedCountry = match
        }

        for field in [BillingAddressViewModel.Field.line1, .city, .state, .postal] {
            viewModel.errors[field] = nil
        }
    }

    private var format: AddressFormat {
        let code = allowsInternational
            ? selectedCountry.alpha2Code
            : "US"
        return AddressFormat.format(forCountry: code)
    }

    /// The subregions the API accepts for the active country, or `nil` when it accepts free text.
    private var subregions: [AddressSubregion]? {
        AddressSubregions.subregions(forCountry: allowsInternational ? selectedCountry.alpha2Code : "US")
    }

    /// The display name for the currently selected subregion, or the field label when unset.
    private var subregionText: String {
        let code = viewModel.address.state ?? ""
        let country = allowsInternational ? selectedCountry.alpha2Code : "US"
        return AddressSubregions.subregion(forCode: code, countryCode: country)?.name ?? format.stateLabel
    }

    /// A tappable row that opens the subregion picker, styled to sit beside the City field.
    private var subregionDropdown: some View {
        HStack(spacing: 4) {
            Text(subregionText)
                .font(theme.fonts.body)
                .foregroundColor((viewModel.address.state ?? "").isEmpty
                                 ? theme.colors.textSecondary
                                 : theme.colors.textPrimary)
                .lineLimit(1)
                .padding(.horizontal)
            if let error = viewModel.errors[.state] {
                Text(error)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.error)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 49.0)
        .contentShape(Rectangle())
        .onTapGesture { showSubregionPicker = true }
    }

    /// The root view hierarchy for the billing-address form.
    public var body: some View {
        VStack(alignment: .leading) {
            if showHeaderText {
                Text(headerTitle)
                    .bold()
                    .font(theme.fonts.label)
                    .padding([.horizontal, .top])
            }
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .fill(theme.colors.surface)
                .stroke(theme.colors.surfaceStroke)
                .frame(minHeight: allowsInternational ? 250.0 : 200.0)
                .overlay {
                    VStack(spacing: 0) {
                        AddressAutocompleteField(prompt: "Address Line 1",
                                                 text: $viewModel.address.addressLine1.orEmpty,
                                                 error: viewModel.errorBinding(.line1),
                                                 countryCode: selectedCountry.alpha2Code,
                                                 inlineError: true) { address in
                            apply(address)
                        }
                        Divider()
                        ValidatedTextField(prompt: "Address Line 2",
                                           text: $viewModel.address.addressLine2.orEmpty,
                                           error: .constant(nil),
                                           textContentType: .streetAddressLine2,
                                           inlineError: true)
                        Divider()
                        HStack {
                            ValidatedTextField(prompt: "City",
                                               text: $viewModel.address.city.orEmpty,
                                               error: viewModel.errorBinding(.city),
                                               textContentType: .addressCity,
                                               inlineError: true)
                            Divider()
                            if subregions != nil {
                                subregionDropdown
                            } else {
                                ValidatedTextField(prompt: format.stateLabel,
                                                   text: $viewModel.address.state.orEmpty,
                                                   error: viewModel.errorBinding(.state),
                                                   textContentType: .addressState,
                                                   characterLimit: format.stateMaxLength,
                                                   inlineError: true)
                            }
                        }
                        .frame(height: 49.0)
                        Divider()
                        ValidatedTextField(prompt: format.postalLabel,
                                           text: $viewModel.address.postalCode,
                                           error: viewModel.errorBinding(.postal),
                                           keyboardType: format.postalKeyboard,
                                           textContentType: .postalCode,
                                           characterLimit: allowsInternational ? nil : 5,
                                           inlineError: true)
                        if allowsInternational {
                            Divider()
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
                viewModel.address.country = "US"
                if let us = AvailableCountry.allCountries.first(where: { $0.alpha2Code == "US" }) {
                    selectedCountry = us
                }
            } else if let savedCountry = viewModel.address.country, !savedCountry.isEmpty,
                      let match = AvailableCountry.allCountries.first(where: { $0.alpha2Code == savedCountry }) {
                selectedCountry = match
            }
            viewModel.address.country = selectedCountry.alpha2Code
            countryText = selectedCountry.displayName
        }
        .onChange(of: selectedCountry) { _, _ in
            viewModel.address.country = selectedCountry.alpha2Code
            countryText = selectedCountry.displayName
            // If a postal error is already visible, refresh it for the new country's rules
            // so the message switches from US ZIP to the new country's format guidance.
            if allowsInternational, viewModel.errors[.postal] != nil {
                viewModel.errors[.postal] = Validators.validatePostalCode(viewModel.address.postalCode,
                                                                          countryCode: selectedCountry.alpha2Code)
            }
        }
        .sheet(isPresented: $showSubregionPicker) {
            SubregionPickerSheet(
                selectedCode: $viewModel.address.state.orEmpty,
                isPresented: $showSubregionPicker,
                countryCode: allowsInternational ? selectedCountry.alpha2Code : "US",
                title: format.stateLabel
            )
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.address.state) { _, _ in
            if viewModel.errors[.state] != nil { viewModel.errors[.state] = nil }
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

#Preview("US only") {
    @Previewable @StateObject var vm = BillingAddressViewModel(mode: .usOnly)
    VStack {
        BillingAddressDetailView(viewModel: vm)
        Button("Validate") { _ = vm.validate() }
    }
}

#Preview("International") {
    @Previewable @StateObject var vm = BillingAddressViewModel(
        address: FrameObjects.BillingAddress(country: "GB", postalCode: ""),
        mode: .international
    )
    VStack {
        BillingAddressDetailView(viewModel: vm, headerTitle: "Current Address")
        Button("Validate") { _ = vm.validate() }
    }
}

#Preview("Dark") {
    @Previewable @StateObject var vm = BillingAddressViewModel(mode: .usOnly)
    VStack {
        BillingAddressDetailView(viewModel: vm)
        Button("Validate") { _ = vm.validate() }
    }
    .preferredColorScheme(.dark)
}
