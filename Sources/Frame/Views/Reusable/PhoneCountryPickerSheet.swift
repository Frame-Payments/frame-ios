//
//  PhoneCountryPickerSheet.swift
//  Frame-iOS
//

import SwiftUI

public struct PhoneCountryPickerSheet: View {
    @Binding var selected: PhoneCountrySelection
    @Binding var isPresented: Bool

    @State private var searchText: String = ""

    let allCountries = PhoneCountrySelection.all

    public init(selected: Binding<PhoneCountrySelection>, isPresented: Binding<Bool>) {
        self._selected = selected
        self._isPresented = isPresented
    }

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
