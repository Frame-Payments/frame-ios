//
//  CountryPickerSheet.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/8/25.
//

import SwiftUI

/// A SwiftUI sheet that presents a wheel-style picker for selecting an available country.
///
/// Present this view as a sheet to let users choose from the list of supported countries,
/// automatically excluding any restricted regions. The selected value is reflected back
/// through the `selectedCountry` binding.
public struct CountryPickerSheet: View {
    @Binding var selectedCountry: AvailableCountry
    @Binding var isPresented: Bool

    @State var restrictedCountries: [String] = []

    let allCountries = AvailableCountry.allCountries

    /// Creates a `CountryPickerSheet`.
    ///
    /// - Parameters:
    ///   - selectedCountry: A binding to the currently selected country, updated when the user taps Done.
    ///   - isPresented: A binding that controls whether the sheet is visible; set to `false` to dismiss.
    ///   - restrictedCountries: Display names of countries to exclude from the picker; defaults to `AvailableCountry.restrictedCountries`.
    public init(selectedCountry: Binding<AvailableCountry>, isPresented: Binding<Bool>, restrictedCountries: [String] = AvailableCountry.restrictedCountries) {
        self._selectedCountry = selectedCountry
        self._isPresented = isPresented
        self.restrictedCountries = restrictedCountries
    }

    /// The content and layout of the country picker sheet.
    public var body: some View {
        NavigationView {
            VStack {
                Picker("Select a Country", selection: $selectedCountry) {
                    ForEach(allCountries
                        .filter({ !restrictedCountries.contains($0.displayName) })
                        .sorted(by: { $0.displayName < $1.displayName }), id: \.self) { country in
                        Text(country.displayName)
                                .tag(country)
                    }
                }
                .labelsHidden()
                .pickerStyle(.wheel)
                .frame(maxHeight: 250)
                
                Spacer()
            }
            .navigationBarTitle("Choose Country", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}
