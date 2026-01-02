//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/19/25.
//

import SwiftUI
import Frame_iOS

struct UserIdentificationView: View {
    enum IdentificationSelection: String, CaseIterable {
        case id
        case country
    }
    
    @State private var showIdentityInputs: Bool = false
    @State private var selectedCountry: String = "United States"
    @State private var showCountryPicker: Bool = false
    @State private var selectedIdType: String = "Driver's License"
    @State private var showIDPicker: Bool = false
    
    @Binding var continueToNextStep: Bool
    
    let idTypes: [String] = ["Driver's License", "State ID", "Military ID", "Passport"]
    let restrictedCountries: [String] = ["Iran", "Russia", "North Korea", "Syria", "Cuba",
                                         "Democratic Republic of Congo", "Iraq", "Libya",
                                         "Mali", "Nicaragua", "Sudan", "Venezuela", "Yemen"]
    
    var body: some View {
        VStack {
            if showIdentityInputs {
                verifyIdentityView
            } else {
                identityIntro
            }
        }
        .sheet(isPresented: $showIDPicker) {
            Picker(IdentificationSelection.id.rawValue, selection: $selectedIdType) {
                ForEach(idTypes, id: \.self) { id in
                    Text(id)
                }
            }
            .pickerStyle(.wheel)
            .presentationDetents([.height(200.0)])
        }
        .sheet(isPresented: $showCountryPicker) {
            Picker(IdentificationSelection.country.rawValue, selection: $selectedCountry) {
                ForEach(AvailableCountry.allCountries
                    .filter({ !restrictedCountries.contains($0.displayName) })
                    .sorted(by: { $0.displayName < $1.displayName }),
                        id: \.self) { country in
                    Text(country.displayName)
                }
            }
            .pickerStyle(.wheel)
            .presentationDetents([.height(200.0)])
        }
    }
    
    var identityIntro: some View {
        VStack(spacing: 15.0) {
            Spacer()
            Image("shield-icon", bundle: FrameResources.module)
            Text("Verify Your Identity")
                .font(.system(size: 18.0))
                .fontWeight(.semibold)
            Text("We’re required by law to verify your identity. This takes about 2 minutes and you’ll need a Government ID and a selfie.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14.0))
                .foregroundColor(secondaryTextColor)
                .padding(.horizontal, 24.0)
            Spacer()
            ContinueButton(enabled: .constant(true)) {
                showIdentityInputs.toggle()
            }
            .padding(.bottom)
        }
    }
    
    var verifyIdentityView: some View {
        VStack(alignment: .leading) {
            PageHeaderView(headerTitle: "Verify Your ID") {
                self.showIdentityInputs = false
            }
            Text("We’re required by law to verify your identity. This takes about 2 minutes and you’ll need a Government ID and a selfie.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14.0))
                .foregroundColor(secondaryTextColor)
                .padding(.horizontal, 20.0)
                .padding(.bottom, 8.0)
            dropdownSelectionBox(titleName: "Issuing Country", selection: .country)
            dropdownSelectionBox(titleName: "ID Type", selection: .id)
            
            Spacer()
            ContinueButton(enabled: .constant(true)) {
                self.continueToNextStep.toggle()
            }
            .padding(.bottom)
        }
    }
    
    @ViewBuilder
    func dropdownSelectionBox(titleName: String, selection: IdentificationSelection) -> some View {
        Text(titleName)
            .padding([.horizontal])
            .fontWeight(.semibold)
            .font(.system(size: 13.0))
        HStack {
            Text(selection == .id ? selectedIdType : selectedCountry)
                .fontWeight(.medium)
                .font(.system(size: 14.0))
                .padding()
            Spacer()
            Image("down-chevron", bundle: FrameResources.module)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 42.0)
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding([.horizontal, .bottom])
        .onTapGesture {
            switch selection {
            case .id:
                self.showIDPicker.toggle()
            case .country:
                self.showCountryPicker.toggle()
            }
        }
    }
}

#Preview {
    UserIdentificationView(continueToNextStep: .constant(false))
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
