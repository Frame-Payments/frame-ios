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

    private var format: AddressFormat {
        let code = allowsInternational
            ? selectedCountry.alpha2Code
            : "US"
        return AddressFormat.format(forCountry: code)
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
                        ValidatedTextField(prompt: "Address Line 1",
                                           text: $viewModel.address.addressLine1.orEmpty,
                                           error: viewModel.errorBinding(.line1),
                                           inlineError: true)
                        Divider()
                        ValidatedTextField(prompt: "Address Line 2",
                                           text: $viewModel.address.addressLine2.orEmpty,
                                           error: .constant(nil),
                                           inlineError: true)
                        Divider()
                        HStack {
                            ValidatedTextField(prompt: "City",
                                               text: $viewModel.address.city.orEmpty,
                                               error: viewModel.errorBinding(.city),
                                               inlineError: true)
                            Divider()
                            ValidatedTextField(prompt: format.stateLabel,
                                               text: $viewModel.address.state.orEmpty,
                                               error: viewModel.errorBinding(.state),
                                               characterLimit: format.stateMaxLength,
                                               inlineError: true)
                        }
                        .frame(height: 49.0)
                        Divider()
                        ValidatedTextField(prompt: format.postalLabel,
                                           text: $viewModel.address.postalCode,
                                           error: viewModel.errorBinding(.postal),
                                           keyboardType: format.postalKeyboard,
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
