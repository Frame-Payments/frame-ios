//
//  CustomerInformationView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/9/26.
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

    @State private var birthYear: String = ""
    @State private var birthMonth: String = ""
    @State private var birthDay: String = ""

    @State private var headerTitle: String

    /// Creates a ``CustomerInformationView``.
    ///
    /// - Parameters:
    ///   - viewModel: The view model that owns and validates the customer identity state.
    ///   - onboardingContainerViewModel: The onboarding container view model driving the no-SSN
    ///     government-ID verification flow and holding its verified state.
    ///   - headerTitle: The bold label displayed above the name/email/phone fields.
    ///     Defaults to `"Customer Information"`.
    init(viewModel: CustomerInformationViewModel,
         onboardingContainerViewModel: OnboardingContainerViewModel,
         headerTitle: String = "Customer Information") {
        self.viewModel = viewModel
        self.onboardingContainerViewModel = onboardingContainerViewModel
        self._headerTitle = State(initialValue: headerTitle)
    }

    /// Whether the current onboarding flow requires KYC (which is what surfaces the SSN row and,
    /// with it, the no-SSN government-ID verification affordance).
    private var requiresKYC: Bool {
        let caps = onboardingContainerViewModel.requiredCapabilities
        return caps.contains(.kyc) || caps.contains(.kycPrefill)
    }

    /// The root view hierarchy that renders all customer-information input sections.
    public var body: some View {
        VStack(alignment: .leading) {
            Text(headerTitle)
                .bold()
                .font(theme.fonts.label)
                .padding([.horizontal, .top])
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .fill(theme.colors.surface)
                .stroke(theme.colors.surfaceStroke)
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
            if onboardingContainerViewModel.identityVerifiedViaGovId {
                governmentIdVerifiedView
            } else {
                socialSecurityView
                if requiresKYC {
                    noSSNButton
                }
            }
        }
        .onAppear {
            seedBirthComponentsFromStoredValue()
            // Keep the info view model's SSN-skip flag in sync with any already-verified state.
            viewModel.identityVerifiedViaGovId = onboardingContainerViewModel.identityVerifiedViaGovId
        }
        .onChange(of: onboardingContainerViewModel.identityVerifiedViaGovId) { _, verified in
            viewModel.identityVerifiedViaGovId = verified
            if verified {
                // Clear any stale SSN error and value so nothing leaks into submit.
                viewModel.errors[.ssn] = nil
                viewModel.identity.ssn = ""
            }
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

    /// A grouped row of Month, Day, and Year text fields for capturing the customer's date of birth.
    @ViewBuilder
    var birthdayView: some View {
        HStack {
            Text("Birthday")
                .bold()
                .font(theme.fonts.label)
            Spacer()
            if let dobError = viewModel.firstDateOfBirthError {
                Text(dobError)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.error)
            }
        }
        .padding([.horizontal, .top])
        RoundedRectangle(cornerRadius: theme.radii.medium)
            .fill(theme.colors.surface)
            .stroke(theme.colors.surfaceStroke)
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

    /// A labeled input row that collects the last four digits of the customer's Social Security Number.
    @ViewBuilder
    var socialSecurityView: some View {
        Text("Social Security Number")
            .bold()
            .font(theme.fonts.label)
            .padding([.horizontal, .top])
        RoundedRectangle(cornerRadius: theme.radii.medium)
            .fill(theme.colors.surface)
            .stroke(theme.colors.surfaceStroke)
            .frame(height: 50.0)
            .overlay {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: theme.radii.medium)
                        .fill(theme.colors.surfaceStroke)
                        .stroke(theme.colors.surfaceStroke)
                        .frame(width: 120.0, height: 50.0)
                        .overlay {
                            Text("Last 4 Digits")
                                .font(.footnote)
                                .bold()
                                .foregroundColor(theme.colors.textPrimary)
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

    /// Secondary text-style button offering the no-SSN government-ID verification path. Shown
    /// directly under the SSN row while KYC is required and the applicant has not yet verified.
    @ViewBuilder
    var noSSNButton: some View {
        ContinueButton(buttonText: "I don't have a social security number",
                       style: .secondary,
                       isLoading: .constant(onboardingContainerViewModel.isPerformingAction)) {
            guard let presenter = UIApplication.shared.topViewController else { return }
            Task {
                await onboardingContainerViewModel.verifyIdentityWithoutSsn(from: presenter)
            }
        }
    }

    /// Confirmation row shown in place of the SSN input and no-SSN button once the applicant has
    /// verified their identity with a government ID.
    @ViewBuilder
    var governmentIdVerifiedView: some View {
        Text("Social Security Number")
            .bold()
            .font(theme.fonts.label)
            .padding([.horizontal, .top])
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
