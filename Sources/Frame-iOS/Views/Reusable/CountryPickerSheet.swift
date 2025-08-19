//
//  CountryPickerSheet.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/8/25.
//

import SwiftUI

struct CountryPickerSheet: View {
    @Binding var selectedCountry: AvailableCountry
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack {
                Picker("Select a Country", selection: $selectedCountry) {
                    ForEach(AvailableCountry.allCountries.sorted(by: { $0.displayName < $1.displayName }), id: \.self) { country in
                        Text(country.displayName).tag(country)
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
