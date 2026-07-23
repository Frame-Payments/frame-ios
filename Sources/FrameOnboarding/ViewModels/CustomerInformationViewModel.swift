//
//  CustomerInformationViewModel.swift
//  Frame-iOS
//

import SwiftUI
import Frame

/// View model that manages customer identity form state, field validation, and error messages
/// during the onboarding customer-information step.
@MainActor
public final class CustomerInformationViewModel: ObservableObject {
    /// Identifies each editable field in the customer-information form.
    public enum Field: Hashable, Sendable {
        /// The customer's first name.
        case firstName
        /// The customer's last name.
        case lastName
        /// The customer's email address.
        case email
        /// The customer's phone number.
        case phone
        /// The month component of the customer's date of birth.
        case birthMonth
        /// The day component of the customer's date of birth.
        case birthDay
        /// The year component of the customer's date of birth.
        case birthYear
        /// The last four digits of the customer's Social Security Number.
        case ssn
    }

    /// The customer identity payload that will be submitted to the API.
    @Published public var identity: CustomerIdentityRequest.CreateCustomerIdentityRequest
    /// The selected phone-number country and dialing region.
    @Published public var phoneCountry: PhoneCountrySelection
    /// A map from each form field to its current validation error message, if any.
    @Published public var errors: [Field: String] = [:]

    /// When `true`, the applicant verified identity with a government ID (no-SSN path), so SSN
    /// entry is not shown and SSN validation is skipped. Kept in sync with the container view
    /// model's `identityVerifiedViaGovId`.
    @Published public var identityVerifiedViaGovId: Bool = false

    /// Creates a new view model with optional pre-populated identity data and phone country.
    ///
    /// - Parameters:
    ///   - identity: The initial customer identity values; defaults to an empty request.
    ///   - phoneCountry: The initial phone country selection; defaults to `.default`.
    public init(identity: CustomerIdentityRequest.CreateCustomerIdentityRequest = CustomerIdentityRequest.CreateCustomerIdentityRequest(
                    firstName: "", lastName: "", dateOfBirth: "", email: "", phoneNumber: "",
                    ssn: "", address: FrameObjects.BillingAddress(postalCode: "")),
                phoneCountry: PhoneCountrySelection = .default) {
        self.identity = identity
        self.phoneCountry = phoneCountry
    }

    /// Validates all form fields, populates ``errors``, and returns whether the form is valid.
    ///
    /// - Returns: `true` when all fields pass validation; `false` when one or more errors exist.
    @discardableResult
    public func validate() -> Bool {
        var next: [Field: String] = [:]

        if let err = Validators.validateNonEmpty(identity.firstName, fieldName: "First name") {
            next[.firstName] = err
        }
        if let err = Validators.validateNonEmpty(identity.lastName, fieldName: "Last name") {
            next[.lastName] = err
        }
        if let err = Validators.validateEmail(identity.email) {
            next[.email] = err
        }
        if let err = Validators.validatePhoneE164(identity.phoneNumber, regionCode: phoneCountry.alpha2) {
            next[.phone] = err
        }

        let parts = identity.dateOfBirth.components(separatedBy: "-")
        let year = parts.count == 3 ? parts[0] : ""
        let month = parts.count == 3 ? parts[1] : ""
        let day = parts.count == 3 ? parts[2] : ""
        if let err = Validators.validateDateOfBirth(year: year, month: month, day: day) {
            next[.birthMonth] = err
            next[.birthDay] = err
            next[.birthYear] = err
        }

        // Skip SSN validation when the applicant verified with a government ID (no-SSN path).
        if !identityVerifiedViaGovId, let err = Validators.validateSSNLast4(identity.ssn) {
            next[.ssn] = err
        }

        errors = next
        return next.isEmpty
    }

    /// Returns a two-way binding to the validation error message for a specific field.
    ///
    /// - Parameter field: The form field whose error binding is requested.
    /// - Returns: A `Binding<String?>` that reads and writes the error entry in ``errors``.
    public func errorBinding(_ field: Field) -> Binding<String?> {
        Binding(
            get: { [weak self] in self?.errors[field] },
            set: { [weak self] in self?.errors[field] = $0 }
        )
    }

    /// Returns the first non-nil DOB field error in display order (month → day → year),
    /// so the header row can surface a single compact message rather than three.
    public var firstDateOfBirthError: String? {
        errors[.birthMonth] ?? errors[.birthDay] ?? errors[.birthYear]
    }
}
