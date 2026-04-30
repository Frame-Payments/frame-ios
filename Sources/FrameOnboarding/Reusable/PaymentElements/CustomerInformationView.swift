//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import Frame

struct CustomerInformationView: View {
    @ObservedObject var viewModel: OnboardingContainerViewModel

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

    init(viewModel: OnboardingContainerViewModel,
         emailAddress: Binding<String>,
         phoneNumber: Binding<String>,
         firstName: Binding<String>,
         lastName: Binding<String>,
         dateOfBirth: Binding<String>,
         ssn: Binding<String>,
         headerTitle: String = "Customer Information") {
        self.viewModel = viewModel
        self._emailAddress = emailAddress
        self._phoneNumber = phoneNumber
        self._firstName = firstName
        self._lastName = lastName
        self._dateOfBirth = dateOfBirth
        self._ssn = ssn
        self._headerTitle = State(initialValue: headerTitle)
    }

    var body: some View {
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
                            ValidatedTextField(prompt: "First Name",
                                               text: $firstName,
                                               error: viewModel.errorBinding(.personalFirstName))
                            Divider()
                            ValidatedTextField(prompt: "Last Name",
                                               text: $lastName,
                                               error: viewModel.errorBinding(.personalLastName))
                        }
                        .frame(height: 49.0)
                        Divider()
                        ValidatedTextField(prompt: "Email Address",
                                           text: $emailAddress,
                                           error: viewModel.errorBinding(.personalEmail),
                                           keyboardType: .emailAddress)
                        Divider()
                        PhoneNumberTextField(prompt: "Phone Number",
                                             text: $phoneNumber,
                                             error: viewModel.errorBinding(.personalPhone),
                                             regionCode: viewModel.phoneCountry.alpha2)
                    }
                }
                .padding(.horizontal)
            birthdayView
            socialSecurityView
        }
        .onAppear {
            seedBirthComponentsFromStoredValue()
        }
        .onChange(of: birthYear, { oldValue, newValue in
            self.dateOfBirth = OnboardingContainerViewModel.formatDateOfBirth(year: birthYear, month: birthMonth, day: birthDay)
        })
        .onChange(of: birthMonth, { oldValue, newValue in
            self.dateOfBirth = OnboardingContainerViewModel.formatDateOfBirth(year: birthYear, month: birthMonth, day: birthDay)
        })
        .onChange(of: birthDay, { oldValue, newValue in
            self.dateOfBirth = OnboardingContainerViewModel.formatDateOfBirth(year: birthYear, month: birthMonth, day: birthDay)
        })
    }

    /// Splits a stored YYYY-M(M)-D(D) string back into the three editable components.
    /// Tolerates unpadded month/day so legacy data (e.g. "1990-1-5") still hydrates the form.
    private func seedBirthComponentsFromStoredValue() {
        let parts = dateOfBirth.components(separatedBy: "-")
        guard parts.count == 3, parts.allSatisfy({ !$0.isEmpty }) else { return }
        self.birthYear = parts[0]
        self.birthMonth = parts[1]
        self.birthDay = parts[2]
    }

    @ViewBuilder
    var birthdayView: some View {
        Text("Birthday")
            .bold()
            .font(headerFont)
            .padding([.horizontal, .top])
        RoundedRectangle(cornerRadius: 10.0)
            .fill(.white)
            .stroke(.gray.opacity(0.3))
            .frame(height: 50.0)
            .overlay {
                HStack {
                    ValidatedTextField(prompt: "Month",
                                       text: $birthMonth,
                                       error: viewModel.errorBinding(.personalBirthMonth),
                                       keyboardType: .numberPad,
                                       characterLimit: 2)
                    Divider()
                    ValidatedTextField(prompt: "Day",
                                       text: $birthDay,
                                       error: viewModel.errorBinding(.personalBirthDay),
                                       keyboardType: .numberPad,
                                       characterLimit: 2)
                    Divider()
                    ValidatedTextField(prompt: "Year",
                                       text: $birthYear,
                                       error: viewModel.errorBinding(.personalBirthYear),
                                       keyboardType: .numberPad,
                                       characterLimit: 4)
                }
            }
            .padding(.horizontal)
    }

    @ViewBuilder
    var socialSecurityView: some View {
        Text("Social Security Number")
            .bold()
            .font(headerFont)
            .padding([.horizontal, .top])
        RoundedRectangle(cornerRadius: 10.0)
            .fill(.white)
            .stroke(.gray.opacity(0.3))
            .frame(height: 50.0)
            .overlay {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 10.0)
                        .fill(.gray.opacity(0.3))
                        .stroke(.gray.opacity(0.3))
                        .frame(width: 120.0, height: 50.0)
                        .overlay {
                            Text("Last 4 Digits")
                                .font(.footnote)
                                .bold()
                                .foregroundColor(.black)
                        }
                    ValidatedTextField(prompt: "SSN",
                                       text: $ssn,
                                       error: viewModel.errorBinding(.personalSSN),
                                       keyboardType: .numberPad,
                                       characterLimit: 4)
                }
            }
            .padding(.horizontal)
    }
}
