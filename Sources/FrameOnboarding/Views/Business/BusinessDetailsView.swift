import SwiftUI
import Frame

struct BusinessDetailsView: View {
    @Environment(\.frameTheme) private var theme
    @ObservedObject var onboardingContainerViewModel: OnboardingContainerViewModel

    @Binding var continueToNextStep: Bool
    @Binding var returnToPreviousStep: Bool

    @State private var legalName = ""
    @State private var structure: BusinessStructure?
    @State private var category: BusinessCategory?
    @State private var ein = ""
    @State private var email = ""
    @State private var website = ""
    @State private var samePhysicalAddress = true
    @State private var showCategoryPicker = false
    @State private var showTypePicker = false
    @State private var categoryQuery = ""
    @State private var fieldError: String?

    @StateObject private var legalAddress = BillingAddressViewModel()
    @StateObject private var physicalAddress = BillingAddressViewModel()

    var body: some View {
        VStack(spacing: 0) {
            PageHeaderView(headerTitle: "Business details") {
                returnToPreviousStep = true
            }
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.formBlock) {
                    Text("Tell us about the business you're onboarding.")
                        .font(theme.fonts.bodySmall)
                        .foregroundStyle(theme.colors.textSecondary)
                        .padding(.horizontal)

                    ValidatedTextField(prompt: "Legal business name",
                                       text: $legalName,
                                       error: .constant(nil),
                                       inlineError: true)
                    .padding(.horizontal)
                    Text("Exactly as registered with the IRS.")
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .padding(.horizontal)

                    menuRow(title: "Business type", value: structure?.label) { showTypePicker = true }
                    menuRow(title: "Business category", value: category?.name) { showCategoryPicker = true }
                    Text("Choose the category that best describes what your business sells.")
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .padding(.horizontal)

                    ValidatedTextField(prompt: "Website",
                                       text: $website,
                                       error: .constant(nil),
                                       keyboardType: .URL,
                                       inlineError: true)
                    .padding(.horizontal)

                    ValidatedTextField(prompt: "EIN",
                                       text: $ein,
                                       error: .constant(nil),
                                       keyboardType: .numberPad,
                                       characterLimit: 10,
                                       inlineError: true)
                    .padding(.horizontal)

                    ValidatedTextField(prompt: "Business email",
                                       text: $email,
                                       error: .constant(nil),
                                       keyboardType: .emailAddress,
                                       textContentType: .emailAddress,
                                       inlineError: true)
                    .padding(.horizontal)

                    BillingAddressDetailView(viewModel: legalAddress, headerTitle: "Legal address")

                    Toggle(isOn: $samePhysicalAddress) {
                        Text("Physical address is the same as my legal address")
                            .font(theme.fonts.bodySmall)
                            .foregroundStyle(theme.colors.textPrimary)
                    }
                    .tint(theme.colors.primaryButton)
                    .padding(.horizontal)

                    if !samePhysicalAddress {
                        BillingAddressDetailView(viewModel: physicalAddress, headerTitle: "Physical address")
                    }
                }
                .padding(.top, theme.spacing.sectionGap)
            }
            if let fieldError {
                Text(fieldError)
                    .font(theme.fonts.caption)
                    .foregroundStyle(theme.colors.error)
                    .padding(.horizontal)
            }
            ContinueButton(isLoading: $onboardingContainerViewModel.isPerformingAction) {
                Task { await submit() }
            }
            .padding(.bottom)
        }
        .confirmationDialog("Business type", isPresented: $showTypePicker, titleVisibility: .visible) {
            ForEach(BusinessStructure.allCases) { item in
                Button(item.label) { structure = item }
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            categorySheet
        }
    }

    private func menuRow(title: String, value: String?, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sectionGap) {
            Text(title)
                .font(theme.fonts.label)
                .foregroundStyle(theme.colors.textSecondary)
                .padding(.horizontal)
            Button(action: action) {
                HStack {
                    Text(value ?? title)
                        .font(theme.fonts.body)
                        .foregroundStyle(value == nil ? theme.colors.textSecondary : theme.colors.textPrimary)
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
        }
    }

    private var categorySheet: some View {
        NavigationStack {
            List(filteredCategories) { item in
                Button {
                    category = item
                    showCategoryPicker = false
                } label: {
                    Text(item.name)
                        .font(theme.fonts.body)
                        .foregroundStyle(theme.colors.textPrimary)
                }
            }
            .searchable(text: $categoryQuery, prompt: "Search categories")
            .navigationTitle("Business category")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var filteredCategories: [BusinessCategory] {
        let query = categoryQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return BusinessCategories.all }
        return BusinessCategories.all.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.code.contains(query)
        }
    }

    private func submit() async {
        fieldError = nil
        guard !legalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fail("Enter the legal business name.")
            return
        }
        guard structure != nil else {
            fail("Select a business type.")
            return
        }
        guard category != nil else {
            fail("Select a business category.")
            return
        }
        if let einError = Validators.validateEIN(ein) {
            fail(einError)
            return
        }
        let digits = ein.filter(\.isNumber)
        guard !website.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fail("Enter a website.")
            return
        }
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fail("Enter a business email.")
            return
        }
        legalAddress.normalize()
        guard legalAddress.validate() else {
            fail(legalAddress.errors.values.first ?? "Enter the legal address.")
            return
        }
        if !samePhysicalAddress {
            physicalAddress.normalize()
            guard physicalAddress.validate() else {
                fail(physicalAddress.errors.values.first ?? "Enter the physical address.")
                return
            }
        }

        let result = await onboardingContainerViewModel.submitBusinessDetails(
            legalName: legalName.trimmingCharacters(in: .whitespacesAndNewlines),
            structure: structure,
            category: category,
            ein: digits,
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            website: website,
            legalAddress: legalAddress.address,
            samePhysicalAddress: samePhysicalAddress,
            physicalAddress: physicalAddress.address
        )
        if result == .advance {
            continueToNextStep = true
        }
    }

    private func fail(_ message: String) {
        fieldError = message
        onboardingContainerViewModel.reportUserError(message)
    }
}
