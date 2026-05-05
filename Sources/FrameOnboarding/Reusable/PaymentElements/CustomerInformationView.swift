//
//  CustomerInformationView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
//

import SwiftUI
import Frame

public struct CustomerInformationView: View {
    @ObservedObject var viewModel: CustomerInformationViewModel

    @State private var birthYear: String = ""
    @State private var birthMonth: String = ""
    @State private var birthDay: String = ""

    @State private var headerTitle: String
    @State private var headerFont: Font = Font.subheadline

    public init(viewModel: CustomerInformationViewModel,
                headerTitle: String = "Customer Information") {
        self.viewModel = viewModel
        self._headerTitle = State(initialValue: headerTitle)
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Text(headerTitle)
                .bold()
                .font(headerFont)
                .padding([.horizontal, .top])
            RoundedRectangle(cornerRadius: 10.0)
                .fill(FrameColors.surfaceColor)
                .stroke(FrameColors.surfaceStrokeColor)
                .frame(height: 150.0)
                .overlay {
                    VStack(spacing: 0) {
                        HStack {
                            ValidatedTextField(prompt: "First Name",
                                               text: $viewModel.identity.firstName,
                                               error: viewModel.errorBinding(.firstName),
                                               inlineError: true)
                            Divider()
                            ValidatedTextField(prompt: "Last Name",
                                               text: $viewModel.identity.lastName,
                                               error: viewModel.errorBinding(.lastName),
                                               inlineError: true)
                        }
                        .frame(height: 49.0)
                        Divider()
                        ValidatedTextField(prompt: "Email Address",
                                           text: $viewModel.identity.email,
                                           error: viewModel.errorBinding(.email),
                                           keyboardType: .emailAddress,
                                           inlineError: true)
                        Divider()
                        PhoneNumberTextField(prompt: "Phone Number",
                                             text: $viewModel.identity.phoneNumber,
                                             error: viewModel.errorBinding(.phone),
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
        .onChange(of: birthYear) { _, _ in
            viewModel.identity.dateOfBirth = DateOfBirthFormatter.format(year: birthYear, month: birthMonth, day: birthDay)
        }
        .onChange(of: birthMonth) { _, _ in
            viewModel.identity.dateOfBirth = DateOfBirthFormatter.format(year: birthYear, month: birthMonth, day: birthDay)
        }
        .onChange(of: birthDay) { _, _ in
            viewModel.identity.dateOfBirth = DateOfBirthFormatter.format(year: birthYear, month: birthMonth, day: birthDay)
        }
        .onChange(of: viewModel.identity.dateOfBirth) { _, newValue in
            // Re-seed from async hydration (e.g. checkExistingAccount populating identity after mount).
            // Skip if the user has already started typing — otherwise zero-padding would rewrite their input mid-entry.
            guard birthYear.isEmpty, birthMonth.isEmpty, birthDay.isEmpty else { return }
            let parts = newValue.components(separatedBy: "-")
            guard parts.count == 3, parts.allSatisfy({ !$0.isEmpty }) else { return }
            birthYear = parts[0]
            birthMonth = parts[1]
            birthDay = parts[2]
        }
    }

    /// Splits a stored YYYY-M(M)-D(D) string back into the three editable components.
    /// Tolerates unpadded month/day so legacy data (e.g. "1990-1-5") still hydrates the form.
    private func seedBirthComponentsFromStoredValue() {
        let parts = viewModel.identity.dateOfBirth.components(separatedBy: "-")
        guard parts.count == 3, parts.allSatisfy({ !$0.isEmpty }) else { return }
        birthYear = parts[0]
        birthMonth = parts[1]
        birthDay = parts[2]
    }

    @ViewBuilder
    var birthdayView: some View {
        HStack {
            Text("Birthday")
                .bold()
                .font(headerFont)
            Spacer()
            if let dobError = viewModel.firstDateOfBirthError {
                Text(dobError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding([.horizontal, .top])
        RoundedRectangle(cornerRadius: 10.0)
            .fill(FrameColors.surfaceColor)
            .stroke(FrameColors.surfaceStrokeColor)
            .frame(height: 50.0)
            .overlay {
                HStack {
                    ValidatedTextField(prompt: "Month",
                                       text: $birthMonth,
                                       error: viewModel.errorBinding(.birthMonth),
                                       keyboardType: .numberPad,
                                       characterLimit: 2,
                                       compactError: true)
                    Divider()
                    ValidatedTextField(prompt: "Day",
                                       text: $birthDay,
                                       error: viewModel.errorBinding(.birthDay),
                                       keyboardType: .numberPad,
                                       characterLimit: 2,
                                       compactError: true)
                    Divider()
                    ValidatedTextField(prompt: "Year",
                                       text: $birthYear,
                                       error: viewModel.errorBinding(.birthYear),
                                       keyboardType: .numberPad,
                                       characterLimit: 4,
                                       compactError: true)
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
            .fill(FrameColors.surfaceColor)
            .stroke(FrameColors.surfaceStrokeColor)
            .frame(height: 50.0)
            .overlay {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 10.0)
                        .fill(FrameColors.surfaceStrokeColor)
                        .stroke(FrameColors.surfaceStrokeColor)
                        .frame(width: 120.0, height: 50.0)
                        .overlay {
                            Text("Last 4 Digits")
                                .font(.footnote)
                                .bold()
                                .foregroundColor(FrameColors.primaryTextColor)
                        }
                    ValidatedTextField(prompt: "SSN",
                                       text: $viewModel.identity.ssn,
                                       error: viewModel.errorBinding(.ssn),
                                       keyboardType: .numberPad,
                                       characterLimit: 4,
                                       inlineError: true)
                }
            }
            .padding(.horizontal)
    }
}

#Preview {
    @Previewable @StateObject var vm = CustomerInformationViewModel()
    ScrollView {
        CustomerInformationView(viewModel: vm)
        Button("Validate") { _ = vm.validate() }
    }
}

#Preview("Dark") {
    @Previewable @StateObject var vm = CustomerInformationViewModel()
    ScrollView {
        CustomerInformationView(viewModel: vm)
        Button("Validate") { _ = vm.validate() }
    }
    .preferredColorScheme(.dark)
}
