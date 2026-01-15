//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import Frame

public struct BillingAddressDetailView: View {
    @Binding public var addressLineOne: String
    @Binding public var addressLineTwo: String
    @Binding public var city: String
    @Binding public var state: String
    @Binding public var zipCode: String
    @Binding public var country: String
    
    @State public var countryText: String = ""
    @State public var headerTitle: String = "Billing Address"
    @State public var headerFont: Font = Font.subheadline
    @State public var showHeaderText: Bool = true
    
    @State private var selectedCountry: AvailableCountry = .defaultCountry
    @State private var showCountryPicker: Bool = false
    
    public var body: some View {
        VStack(alignment: .leading) {
            if showHeaderText {
                Text(headerTitle)
                    .bold()
                    .font(headerFont)
                    .padding([.horizontal, .top])
            }
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
            CountryPickerSheet(
                selectedCountry: $selectedCountry,
                isPresented: $showCountryPicker
            )
            .presentationDetents([.fraction(0.3)])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    VStack {
        BillingAddressDetailView(addressLineOne: .constant(""), addressLineTwo: .constant(""), city: .constant(""),
                                 state: .constant(""), zipCode: .constant(""), country: .constant(AvailableCountry.defaultCountry.displayName))
        BillingAddressDetailView(addressLineOne: .constant(""), addressLineTwo: .constant(""), city: .constant(""),
                                 state: .constant(""), zipCode: .constant(""), country: .constant(AvailableCountry.defaultCountry.displayName),
                                 showHeaderText: false)
    }
}
