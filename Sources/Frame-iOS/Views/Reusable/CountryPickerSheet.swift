//
//  CountryPickerSheet.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/8/25.
//

import SwiftUI

struct CountryPickerSheet: View {
    @Binding var selectedCountry: AvailableCountries
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack {
                Picker("Select a Country", selection: $selectedCountry) {
                    ForEach(AvailableCountries.allCases.sorted(by: { $0.countryName < $1.countryName }), id: \.self) { country in
                        Text(country.countryName).tag(country)
                    }
                }
                .labelsHidden()
                .pickerStyle(WheelPickerStyle())
                .frame(maxHeight: 300)
                
                Spacer()
            }
            .navigationBarTitle("Choose Country", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}
