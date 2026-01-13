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
    
    @State var countryText: String = ""
    @State var headerTitle: String = "Billing Address"
    @State var headerFont: Font = Font.subheadline
    
    @State private var selectedCountry: AvailableCountry = .defaultCountry
    @State private var showCountryPicker: Bool = false
    
    public var body: some View {
        VStack(alignment: .leading) {
            Text(headerTitle)
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
                            ReusableFormTextField(prompt: "State", text: $state, showDivider: false, characterLimit: 2)
                        }
                        .frame(height: 49.0)
                        Divider()
                        ReusableFormTextField(prompt: "Zip Code", text: $zipCode, showDivider: true, keyboardType: .numberPad, characterLimit: 5)
                        DropDownWithHeaderView(headerText: .constant(""), dropDownText: $countryText, showDropdownPicker: $showCountryPicker,
                                               showHeaderText: false, showDropdownBorder: false)
                    }
                }
                .padding(.horizontal)
        }
        .onAppear {
            self.country = selectedCountry.alpha2Code
            self.countryText = selectedCountry.displayName
        }
        .onChange(of: selectedCountry, { oldValue, newValue in
            self.country = selectedCountry.alpha2Code
            self.countryText = selectedCountry.displayName
        })
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(selectedCountry: $selectedCountry,
                               isPresented: $showCountryPicker)
        }
    }
}

#Preview {
    BillingAddressDetailView(addressLineOne: .constant(""), addressLineTwo: .constant(""), city: .constant(""),
                             state: .constant(""), zipCode: .constant(""), country: .constant(AvailableCountry.defaultCountry.displayName))
}
