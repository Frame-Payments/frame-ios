//
//  PhoneCountryPickerSheet.swift
//  Frame-iOS
//

import SwiftUI

/// A SwiftUI sheet that lets the user search for and select a phone country calling code.
///
/// Present this view as a sheet to allow users to browse or search the full list of
/// supported countries and select one as the dialling-code prefix for a phone number field.
public struct PhoneCountryPickerSheet: View {
    @Binding var selected: PhoneCountrySelection
    @Binding var isPresented: Bool

    @State private var searchText: String = ""

    let allCountries = PhoneCountrySelection.all

    /// Creates a phone country picker sheet.
    ///
    /// - Parameters:
    ///   - selected: A binding to the currently selected ``PhoneCountrySelection``, updated when the user taps a row.
    ///   - isPresented: A binding that controls whether the sheet is visible; set to `false` to dismiss.
    public init(selected: Binding<PhoneCountrySelection>, isPresented: Binding<Bool>) {
        self._selected = selected
        self._isPresented = isPresented
    }

    /// The body of the picker sheet, rendering a searchable list of countries.
    public var body: some View {
        NavigationView {
            List(filtered) { country in
                Button {
                    selected = country
                    isPresented = false
                } label: {
                    HStack(spacing: 12) {
                        Text(country.flag)
                            .font(.title2)
                        Text(country.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(country.dialCode)
                            .foregroundColor(.secondary)
                        if country == selected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search country or code")
            .navigationBarTitle("Choose Country", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }

    private var filtered: [PhoneCountrySelection] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return allCountries }
        return allCountries.filter {
            $0.displayName.localizedCaseInsensitiveContains(trimmed)
            || $0.dialCode.contains(trimmed)
            || $0.alpha2.localizedCaseInsensitiveContains(trimmed)
        }
    }
}
