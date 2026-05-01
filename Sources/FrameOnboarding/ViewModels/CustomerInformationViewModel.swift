//
//  CustomerInformationViewModel.swift
//  Frame-iOS
//

import SwiftUI
import Frame

@MainActor
public final class CustomerInformationViewModel: ObservableObject {
    public enum Field: Hashable, Sendable {
        case firstName, lastName, email, phone, birthMonth, birthDay, birthYear, ssn
    }

    @Published public var identity: CustomerIdentityRequest.CreateCustomerIdentityRequest
    @Published public var phoneCountry: PhoneCountrySelection
    @Published public var errors: [Field: String] = [:]

    public init(identity: CustomerIdentityRequest.CreateCustomerIdentityRequest = CustomerIdentityRequest.CreateCustomerIdentityRequest(
                    firstName: "", lastName: "", dateOfBirth: "", email: "", phoneNumber: "",
                    ssn: "", address: FrameObjects.BillingAddress(postalCode: "")),
                phoneCountry: PhoneCountrySelection = .default) {
        self.identity = identity
        self.phoneCountry = phoneCountry
    }

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

        if let err = Validators.validateSSNLast4(identity.ssn) {
            next[.ssn] = err
        }

        errors = next
        return next.isEmpty
    }

    public func errorBinding(_ field: Field) -> Binding<String?> {
        Binding(
            get: { [weak self] in self?.errors[field] },
            set: { [weak self] in self?.errors[field] = $0 }
        )
    }
}
