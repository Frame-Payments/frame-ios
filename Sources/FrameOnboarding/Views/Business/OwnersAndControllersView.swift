import SwiftUI
import Frame

struct OwnersAndControllersView: View {
    @Environment(\.frameTheme) private var theme
    @ObservedObject var onboardingContainerViewModel: OnboardingContainerViewModel

    @Binding var continueToNextStep: Bool
    @Binding var returnToPreviousStep: Bool

    @State private var showingInvite = false
    @State private var expandedOwnerId: String?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var role: BusinessRole = .owner
    @State private var formError: String?

    var body: some View {
        VStack(spacing: 0) {
            PageHeaderView(headerTitle: "Owners and controllers") {
                returnToPreviousStep = true
            }
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.formBlock) {
                    Text("Add anyone who owns 25% or more of the business, and anyone who controls it.")
                        .font(theme.fonts.bodySmall)
                        .foregroundStyle(theme.colors.textSecondary)
                        .padding(.horizontal)

                    ForEach(onboardingContainerViewModel.beneficialOwners) { owner in
                        ownerRow(owner)
                    }

                    if showingInvite {
                        inviteForm
                    } else {
                        Button("Add owner or controller") {
                            showingInvite = true
                        }
                        .font(theme.fonts.button)
                        .foregroundStyle(theme.colors.primaryButton)
                        .padding(.horizontal)
                    }

                    if let formError, !showingInvite {
                        Text(formError)
                            .font(theme.fonts.caption)
                            .foregroundStyle(theme.colors.error)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, theme.spacing.sectionGap)
            }
            ContinueButton(isLoading: $onboardingContainerViewModel.isPerformingAction) {
                Task { await confirm() }
            }
            .padding(.bottom)
        }
        .task {
            await onboardingContainerViewModel.loadBeneficialOwners()
        }
    }

    private func ownerRow(_ owner: BeneficialOwners.Owner) -> some View {
        let expanded = expandedOwnerId == owner.id && owner.status == "invite_sent"
        return VStack(alignment: .leading, spacing: theme.spacing.sectionGap) {
            Button {
                if owner.status == "invite_sent" {
                    expandedOwnerId = expanded ? nil : owner.id
                }
            } label: {
                HStack(spacing: 12) {
                    Text(initials(owner))
                        .font(theme.fonts.label)
                        .foregroundStyle(theme.colors.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(theme.colors.surface)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(theme.colors.surfaceStroke))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName(owner))
                            .font(theme.fonts.body)
                            .foregroundStyle(theme.colors.textPrimary)
                        HStack(spacing: 6) {
                            let role = roleLabel(owner)
                            if !role.isEmpty {
                                pill(role)
                            }
                            pill(statusLabel(owner.status))
                        }
                    }
                    Spacer()
                    if owner.status == "invite_sent" {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                            .rotationEffect(.degrees(expanded ? 90 : 0))
                    }
                }
            }
            .buttonStyle(.plain)

            if expanded {
                HStack {
                    Button("Resend invite") {
                        Task { await onboardingContainerViewModel.resendBeneficialOwnerInvite(ownerId: owner.id) }
                    }
                    Spacer()
                    Button("Remove") {
                        Task { await onboardingContainerViewModel.removeBeneficialOwner(ownerId: owner.id) }
                    }
                }
                .font(theme.fonts.caption)
                .foregroundStyle(theme.colors.primaryButton)
            }
        }
        .padding()
        .background(theme.colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .stroke(theme.colors.surfaceStroke)
        )
        .padding(.horizontal)
    }

    private var inviteForm: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sectionGap) {
            ValidatedTextField(prompt: "First name", text: $firstName, error: .constant(nil), inlineError: true)
            ValidatedTextField(prompt: "Last name", text: $lastName, error: .constant(nil), inlineError: true)
            ValidatedTextField(prompt: "Email",
                               text: $email,
                               error: .constant(nil),
                               keyboardType: .emailAddress,
                               inlineError: true)
            Picker("Role", selection: $role) {
                ForEach(BusinessRole.allCases) { item in
                    Text(item == .owner ? "Owner" : "Controller").tag(item)
                }
            }
            .pickerStyle(.segmented)
            if let formError {
                Text(formError)
                    .font(theme.fonts.caption)
                    .foregroundStyle(theme.colors.error)
            }
            HStack {
                Button("Cancel") {
                    showingInvite = false
                    formError = nil
                }
                .foregroundStyle(theme.colors.textSecondary)
                Spacer()
                Button("Send invite") {
                    Task { await sendInvite() }
                }
                .foregroundStyle(theme.colors.primaryButton)
            }
            .font(theme.fonts.button)
        }
        .padding()
        .background(theme.colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.medium)
                .stroke(theme.colors.surfaceStroke)
        )
        .padding(.horizontal)
    }

    private func pill(_ title: String) -> some View {
        Text(title)
            .font(theme.fonts.caption)
            .foregroundStyle(theme.colors.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .overlay(
                Capsule().stroke(theme.colors.surfaceStroke)
            )
    }

    private func displayName(_ owner: BeneficialOwners.Owner) -> String {
        let name = [owner.firstName, owner.lastName].compactMap { $0 }.joined(separator: " ")
        return name.isEmpty ? (owner.email ?? "Owner") : name
    }

    private func initials(_ owner: BeneficialOwners.Owner) -> String {
        let letters = [owner.firstName, owner.lastName].compactMap { $0?.first }.map(String.init)
        return letters.isEmpty ? "?" : letters.joined()
    }

    private func roleLabel(_ owner: BeneficialOwners.Owner) -> String {
        let roles = owner.roles ?? []
        if roles.contains("owner") { return "OWNER" }
        if roles.contains("controller") { return "CONTROLLER" }
        return roles.first?.uppercased() ?? ""
    }

    private func statusLabel(_ status: String?) -> String {
        switch status {
        case "completed": return "COMPLETED"
        case "invite_sent": return "INVITE SENT"
        default: return "PENDING"
        }
    }

    private func sendInvite() async {
        guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            formError = "Enter a name and email."
            onboardingContainerViewModel.reportUserError("Enter a name and email.")
            return
        }
        formError = nil
        let sent = await onboardingContainerViewModel.inviteBeneficialOwner(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role
        )
        if sent {
            firstName = ""
            lastName = ""
            email = ""
            showingInvite = false
        }
    }

    private func confirm() async {
        let result = await onboardingContainerViewModel.confirmBeneficialOwners()
        if result == .advance {
            continueToNextStep = true
        }
    }
}
