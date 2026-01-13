//
//  CountryPickerSheet.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/8/25.
//

import SwiftUI

public struct CountryPickerSheet: View {
    @Binding public var selectedCountry: AvailableCountry
    @Binding public var isPresented: Bool

    @State public var restrictedCountries: [String] = []
    
    let allCountries = AvailableCountry.allCountries
    
    public init(selectedCountry: Binding<AvailableCountry>, isPresented: Binding<Bool>, restrictedCountries: [String] = AvailableCountry.restrictedCountries) {
        self._selectedCountry = selectedCountry
        self._isPresented = isPresented
        self.restrictedCountries = restrictedCountries
    }
    
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
