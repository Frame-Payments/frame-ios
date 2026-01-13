//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import Frame

public struct CustomerInformationView: View {
    
    
    @Binding var emailAddress: String
    @Binding var phoneNumber: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var dateOfBirth: String
    @Binding var ssn: String
    
    @State private var birthYear: String = ""
    @State private var birthMonth: String = ""
    @State private var birthDay: String = ""
    
    @State var headerTitle: String = "Customer Information"
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
                .frame(height: 150.0)
                .overlay {
                    VStack(spacing: 0) {
                        HStack {
                            ReusableFormTextField(prompt: "First Name", text: $firstName, showDivider: false)
                            Divider()
                            ReusableFormTextField(prompt: "Last Name", text: $lastName, showDivider: false)
                        }
                        .frame(height: 49.0)
                        Divider()
                        ReusableFormTextField(prompt: "Email Address", text: $emailAddress, showDivider: true)
                        ReusableFormTextField(prompt: "Phone Number", text: $phoneNumber, showDivider: false, characterLimit: 10)
                    }
                }
                .padding(.horizontal)
            Text("Birthday & SSN")
                .bold()
                .font(headerFont)
                .padding([.horizontal, .top])
            RoundedRectangle(cornerRadius: 10.0)
                .fill(.white)
                .stroke(.gray.opacity(0.3))
                .frame(height: 100.0)
                .overlay {
                    VStack(spacing: 0) {
                        HStack {
                            ReusableFormTextField(prompt: "Birth Year", text: $birthYear, showDivider: false, keyboardType: .numberPad, characterLimit: 4)
                            Divider()
                            ReusableFormTextField(prompt: "Month", text: $birthMonth, showDivider: false, keyboardType: .numberPad, characterLimit: 2)
                            Divider()
                            ReusableFormTextField(prompt: "Day", text: $birthDay, showDivider: false, keyboardType: .numberPad, characterLimit: 2)
                        }
                        .frame(height: 49.0)
                        Divider()
                        ReusableFormTextField(prompt: "Social Security Number", text: $ssn, showDivider: true, keyboardType: .numberPad, characterLimit: 9)
                    }
                }
                .padding(.horizontal)
        }
        .onChange(of: birthYear, { oldValue, newValue in
            self.dateOfBirth = "\(birthYear)-\(birthMonth)-\(birthDay)"
        })
        .onChange(of: birthMonth, { oldValue, newValue in
            self.dateOfBirth = "\(birthYear)-\(birthMonth)-\(birthDay)"
        })
        .onChange(of: birthDay, { oldValue, newValue in
            self.dateOfBirth = "\(birthYear)-\(birthMonth)-\(birthDay)"
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
    CustomerInformationView(emailAddress: .constant(""), phoneNumber: .constant(""), firstName: .constant(""),
                            lastName: .constant(""), dateOfBirth: .constant(""), ssn: .constant(""))
}
