//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import Frame

public struct BillingAddressDetailView: View {
    @Binding var addressLineOne: String
    @Binding var addressLineTwo: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    @Binding var country: String
    
    @State var headerFont: Font = Font.subheadline
    
    @State private var selectedCountry: AvailableCountry = .defaultCountry
    @State private var showCountryPicker: Bool = false
    
    public var body: some View {
        VStack(alignment: .leading) {
            Text("Billing Address")
                .bold()
                .font(headerFont)
                .padding([.horizontal, .top])
            RoundedRectangle(cornerRadius: 10.0)
                .fill(.white)
                .stroke(.gray.opacity(0.3))
                .frame(height: 250.0)
                .overlay {
                    VStack(spacing: 0) {
                        ReusableFormTextField(prompt: "Address Line 1", text: $addressLineOne, showDivider: true)
                        ReusableFormTextField(prompt: "Address Line 2", text: $addressLineTwo, showDivider: true)
                        HStack {
                            ReusableFormTextField(prompt: "City", text: $city, showDivider: false)
                            ReusableFormTextField(prompt: "State", text: $state, showDivider: false)
                        }
                        .frame(height: 49.0)
                        Divider()
                        ReusableFormTextField(prompt: "Zip Code", text: $zipCode, showDivider: true, keyboardType: .numberPad)
                        DropDownWithHeaderView(headerText: .constant(""), dropDownText: $country, showDropdownPicker: $showCountryPicker,
                                               showHeaderText: false, showDropdownBorder: false)
                    }
                }
                .padding(.horizontal)
        }
        .onAppear {
            self.country = selectedCountry.displayName
        }
        .onChange(of: selectedCountry, { oldValue, newValue in
            self.country = selectedCountry.displayName
        })
        .sheet(isPresented: $showCountryPicker) {
            Picker("Countries", selection: $selectedCountry) {
                ForEach(AvailableCountry.allCountries
                    .filter({ !AvailableCountry.restrictedCountries.contains($0.displayName) })
                    .sorted(by: { $0.displayName < $1.displayName }),
                        id: \.self) { country in
                    Text(country.displayName)
                }
            }
            .pickerStyle(.wheel)
            .presentationDetents([.height(200.0)])
        }
    }
}

#Preview {
    BillingAddressDetailView(addressLineOne: .constant(""), addressLineTwo: .constant(""), city: .constant(""),
                             state: .constant(""), zipCode: .constant(""), country: .constant(AvailableCountry.defaultCountry.displayName))
}
