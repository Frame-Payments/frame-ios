//
//  CustomerInformationView.swift
//  Frame-iOS
//

import SwiftUI
import Frame

/// A SwiftUI view that collects personal identity information from a customer,
/// including name, email, phone number, date of birth, and the last four digits
/// of their Social Security Number. Used during onboarding flows that require
/// KYC (Know Your Customer) identity verification.
public struct CustomerInformationView: View {
    @Environment(\.frameTheme) private var theme

    /// The view model that owns the customer identity state and field-level validation.
    @ObservedObject var viewModel: CustomerInformationViewModel

    /// The onboarding container view model, when this view is embedded in an onboarding flow.
    /// Its presence (and a KYC capability) gates the no-SSN government-ID verification button and
    /// carries the resulting verified state.
    @ObservedObject var onboardingContainerViewModel: OnboardingContainerViewModel

    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var showBirthDatePicker: Bool = false
    @FocusState private var ssnFocused: Bool

    @State private var headerTitle: String

    private var dobRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let min = calendar.date(byAdding: .year, value: -120, to: Date()) ?? Date.distantPast
        let max = Date()
        return min...max
    }

    /// Creates a ``CustomerInformationView``.
    ///
    /// - Parameters:
    ///   - viewModel: The view model that owns and validates the customer identity state.
    ///   - onboardingContainerViewModel: The onboarding container view model driving the no-SSN
    ///     government-ID verification flow and holding its verified state.
    ///   - headerTitle: The bold label displayed above the name fields.
    ///     Defaults to `"Legal name"`.
    init(viewModel: CustomerInformationViewModel,
         onboardingContainerViewModel: OnboardingContainerViewModel,
         headerTitle: String = "Legal name") {
        self.viewModel = viewModel
        self.onboardingContainerViewModel = onboardingContainerViewModel
        self._headerTitle = State(initialValue: headerTitle)
    }

    /// Whether to surface the no-SSN government-ID verification affordance: KYC is required and
    /// verification isn't already running automatically.
    private var requiresKYC: Bool {
        guard !onboardingContainerViewModel.governmentIdRequired else { return false }
        let caps = onboardingContainerViewModel.requiredCapabilities
        return caps.contains(.kyc) || caps.contains(.kycPrefill)
    }

    /// The root view hierarchy that renders all customer-information input sections.
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.formBlock) {
            Text(headerTitle)
                .font(theme.fonts.label)
                .padding(.horizontal)
                .padding(.top, theme.spacing.sectionTop)
            ValidatedTextField(prompt: "First name",
                               text: $viewModel.identity.firstName,
                               error: viewModel.errorBinding(.firstName),
                               textContentType: .givenName,
                               inputRestriction: .textOnly,
                               inlineError: true)
            .padding(.horizontal)
            ValidatedTextField(prompt: "Last name",
                               text: $viewModel.identity.lastName,
                               error: viewModel.errorBinding(.lastName),
                               textContentType: .familyName,
                               inputRestriction: .textOnly,
                               inlineError: true)
            .padding(.horizontal)
            Text("Enter your name exactly as it is recorded with government agencies (e.g., IRS).")
                .font(theme.fonts.caption)
                .foregroundStyle(theme.colors.textSecondary)
                .padding(.horizontal)

            Text("Email address")
                .font(theme.fonts.label)
                .padding(.horizontal)
            ValidatedTextField(prompt: "Email address",
                               text: $viewModel.identity.email,
                               error: viewModel.errorBinding(.email),
                               keyboardType: .emailAddress,
                               textContentType: .emailAddress,
                               inlineError: true)
            .padding(.horizontal)

            Text("Phone number")
                .font(theme.fonts.label)
                .padding(.horizontal)
            PhoneNumberTextField(prompt: "Phone number",
                                 text: $viewModel.identity.phoneNumber,
                                 error: viewModel.errorBinding(.phone),
                                 regionCode: viewModel.phoneCountry.alpha2)
            .padding(.horizontal)
            birthdayView
            if onboardingContainerViewModel.identityVerifiedViaGovId,
               !onboardingContainerViewModel.correctedKycDetailsRequired {
                governmentIdVerifiedView
            } else if !onboardingContainerViewModel.identityDocumentRequired
                        || onboardingContainerViewModel.correctedKycDetailsRequired {
                socialSecurityView
                if requiresKYC {
                    noSSNButton
                }
            }
        }
        .onAppear {
            seedBirthDateFromStoredValue()
            viewModel.skipSSN = onboardingContainerViewModel.skipsSSNEntry
        }
        .onChange(of: onboardingContainerViewModel.identityVerifiedViaGovId) { _, verified in
            viewModel.skipSSN = onboardingContainerViewModel.skipsSSNEntry
            if verified, viewModel.skipSSN {
                viewModel.errors[.ssn] = nil
                viewModel.identity.ssn = ""
            }
        }
        .onChange(of: onboardingContainerViewModel.identityDocumentRequired) { _, required in
            viewModel.skipSSN = onboardingContainerViewModel.skipsSSNEntry
            if required, viewModel.skipSSN {
                viewModel.errors[.ssn] = nil
                viewModel.identity.ssn = ""
            }
        }
        .onChange(of: birthDate) { _, newValue in
            applyBirthDate(newValue)
        }
        .onChange(of: viewModel.identity.dateOfBirth) { _, newValue in
            guard let parsed = Self.parseISODate(newValue) else { return }
            let current = Self.isoString(from: birthDate)
            if current != newValue {
                birthDate = parsed
            }
        }
    }

    private func seedBirthDateFromStoredValue() {
        if let parsed = Self.parseISODate(viewModel.identity.dateOfBirth) {
            birthDate = parsed
        }
    }

    private func applyBirthDate(_ date: Date) {
        let parts = Self.components(from: date)
        viewModel.identity.dateOfBirth = DateOfBirthFormatter.format(
            year: parts.year,
            month: parts.month,
            day: parts.day
        )
        viewModel.errors[.birthMonth] = nil
        viewModel.errors[.birthDay] = nil
        viewModel.errors[.birthYear] = nil
    }

    private static func components(from date: Date) -> (year: String, month: String, day: String) {
        let calendar = Calendar.current
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        let d = calendar.component(.day, from: date)
        return (String(y), String(format: "%02d", m), String(format: "%02d", d))
    }

    private static func isoString(from date: Date) -> String {
        let parts = components(from: date)
        return DateOfBirthFormatter.format(year: parts.year, month: parts.month, day: parts.day)
    }

    private static func parseISODate(_ value: String) -> Date? {
        let parts = value.components(separatedBy: "-")
        guard parts.count == 3,
              let y = Int(parts[0]),
              let m = Int(parts[1]),
              let d = Int(parts[2]) else { return nil }
        var comps = DateComponents()
        comps.year = y
        comps.month = m
        comps.day = d
        return Calendar.current.date(from: comps)
    }

    /// Native wheel date picker for the customer's date of birth.
    @ViewBuilder
    var birthdayView: some View {
        HStack {
            Text("Date of birth")
                .font(theme.fonts.label)
            Spacer()
            if let dobError = viewModel.firstDateOfBirthError {
                Text(dobError)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.error)
            }
        }
        .padding(.horizontal)
        Button {
            showBirthDatePicker = true
        } label: {
            HStack {
                Text(birthDate, format: .dateTime.month().day().year())
                    .font(theme.fonts.body)
                    .foregroundStyle(theme.colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(theme.colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.medium)
                    .stroke(theme.colors.surfaceStroke)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .sheet(isPresented: $showBirthDatePicker) {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Done") { showBirthDatePicker = false }
                        .font(theme.fonts.button)
                        .padding()
                }
                DatePicker(
                    "",
                    selection: $birthDate,
                    in: dobRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal)
            }
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }

    /// FrameOS-style last-4 SSN field with masked prefix addon.
    @ViewBuilder
    var socialSecurityView: some View {
        Text("Last 4 digits of Social Security number")
            .font(theme.fonts.label)
            .foregroundStyle(theme.colors.textSecondary)
            .padding(.horizontal)
        RoundedRectangle(cornerRadius: theme.radii.medium)
            .fill(theme.colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.medium)
                    .strokeBorder(
                        ssnFocused ? theme.colors.fieldFocusStroke : theme.colors.surfaceStroke,
                        lineWidth: ssnFocused ? 1.5 : 1
                    )
            )
            .frame(height: 50.0)
            .overlay {
                HStack(spacing: 0) {
                    Text("••• - •• -")
                        .font(theme.fonts.body)
                        .foregroundStyle(theme.colors.textSecondary)
                        .padding(.leading, 16)
                        .padding(.trailing, 12)
                    Rectangle()
                        .fill(ssnFocused ? theme.colors.fieldFocusStroke : theme.colors.surfaceStroke)
                        .frame(width: ssnFocused ? 1.5 : 1)
                    ValidatedTextField(prompt: "0000",
                                       text: $viewModel.identity.ssn,
                                       error: viewModel.errorBinding(.ssn),
                                       keyboardType: .numberPad,
                                       characterLimit: 4,
                                       inlineError: true,
                                       showsBorder: false,
                                       focused: $ssnFocused)
                }
            }
            .padding(.horizontal)
    }

    /// Borderless link offering the no-SSN government-ID verification path.
    @ViewBuilder
    var noSSNButton: some View {
        Button {
            guard let presenter = UIApplication.shared.topViewController else { return }
            Task {
                await onboardingContainerViewModel.verifyIdentityWithoutSsn(from: presenter)
            }
        } label: {
            Text("No Social Security number? Verify with an ID document")
                .font(theme.fonts.caption)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(onboardingContainerViewModel.isPerformingAction)
        .padding(.horizontal)
        .padding(.top, -4)
    }

    /// Confirmation row shown in place of the SSN input and no-SSN button once the applicant has
    /// verified their identity with a government ID.
    @ViewBuilder
    var governmentIdVerifiedView: some View {
        Text("Last 4 digits of Social Security number")
            .font(theme.fonts.label)
            .foregroundStyle(theme.colors.textSecondary)
            .padding(.horizontal)
        RoundedRectangle(cornerRadius: theme.radii.medium)
            .fill(theme.colors.surface)
            .stroke(theme.colors.surfaceStroke)
            .frame(height: 50.0)
            .overlay {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(theme.colors.textPrimary)
                    Text("Verified with government ID.")
                        .font(theme.fonts.label)
                        .foregroundColor(theme.colors.textPrimary)
                    Spacer()
                    Button("Use SSN instead") {
                        onboardingContainerViewModel.resetIdentityVerification()
                    }
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.horizontal)
            }
            .padding(.horizontal)
    }
}

#Preview {
    @Previewable @StateObject var vm = CustomerInformationViewModel()
    @Previewable @StateObject var containerVM = OnboardingContainerViewModel(accountId: "", requiredCapabilities: [.kycPrefill])
    ScrollView {
        CustomerInformationView(viewModel: vm, onboardingContainerViewModel: containerVM)
        Button("Validate") { _ = vm.validate() }
    }
}

#Preview("Dark") {
    @Previewable @StateObject var vm = CustomerInformationViewModel()
    @Previewable @StateObject var containerVM = OnboardingContainerViewModel(accountId: "", requiredCapabilities: [.kycPrefill])
    ScrollView {
        CustomerInformationView(viewModel: vm, onboardingContainerViewModel: containerVM)
        Button("Validate") { _ = vm.validate() }
    }
    .preferredColorScheme(.dark)
}
