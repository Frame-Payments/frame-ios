//
//  BillingAddressViewModel.swift
//  Frame-iOS
//

import SwiftUI
import Frame

/// Controls whether the billing address form accepts US-only or international addresses.
public enum BillingAddressMode: Sendable {
    /// Restricts entry to United States addresses only.
    case usOnly
    /// Allows entry of addresses from any supported country.
    case international
}

/// View model that manages billing address input, validation, and error state for onboarding flows.
@MainActor
public final class BillingAddressViewModel: ObservableObject {

    /// Identifies each editable field in the billing address form.
    public enum Field: Hashable, Sendable {
        /// Street address line 1.
        case line1
        /// City name.
        case city
        /// State, province, or region.
        case state
        /// Postal or ZIP code.
        case postal
        /// ISO 3166-1 alpha-2 country code.
        case country
    }

    /// The current billing address value, updated as the user edits the form.
    @Published public var address: FrameObjects.BillingAddress

    /// Per-field validation error messages; keyed by ``Field``.
    @Published public var errors: [Field: String] = [:]

    /// The address input mode governing country restrictions and postal-code validation rules.
    public let mode: BillingAddressMode

    /// Creates a view model with an initial address and an optional mode.
    ///
    /// - Parameters:
    ///   - address: The pre-populated billing address. Defaults to an empty address with the default country.
    ///   - mode: Whether to restrict input to US addresses or allow international addresses. Defaults to `.usOnly`.
    public init(address: FrameObjects.BillingAddress = FrameObjects.BillingAddress(country: AvailableCountry.defaultCountry.alpha2Code, postalCode: ""),
                mode: BillingAddressMode = .usOnly) {
        var seeded = address
        if mode == .usOnly {
            seeded.country = "US"
        } else if (seeded.country ?? "").isEmpty {
            seeded.country = AvailableCountry.defaultCountry.alpha2Code
        }
        self.address = seeded
        self.mode = mode
    }

    /// Validates all address fields and populates ``errors`` with any failures.
    ///
    /// - Returns: `true` when every required field passes validation; `false` if any errors were found.
    @discardableResult
    public func validate() -> Bool {
        var next: [Field: String] = [:]

        if let err = Validators.validateNonEmpty(address.addressLine1 ?? "", fieldName: "Address line 1") {
            next[.line1] = err
        }
        if let err = Validators.validateNonEmpty(address.city ?? "", fieldName: "City") {
            next[.city] = err
        }
        let countryCode = (address.country ?? "US").isEmpty ? "US" : (address.country ?? "US")
        let stateLabel = AddressFormat.format(forCountry: countryCode).stateLabel
        if let err = Validators.validateNonEmpty(address.state ?? "", fieldName: stateLabel) {
            next[.state] = err
        }
        switch mode {
        case .usOnly:
            if let err = Validators.validateZipUS(address.postalCode) {
                next[.postal] = err
            }
        case .international:
            if let err = Validators.validatePostalCode(address.postalCode, countryCode: countryCode) {
                next[.postal] = err
            }
        }
        if mode == .international,
           let err = Validators.validateNonEmpty(address.country ?? "", fieldName: "Country") {
            next[.country] = err
        }

        errors = next
        return next.isEmpty
    }

    /// Returns a two-way binding to the error message for a specific field.
    ///
    /// - Parameter field: The field whose error message binding is requested.
    /// - Returns: A `Binding<String?>` that reads and writes the error message for `field` in ``errors``.
    public func errorBinding(_ field: Field) -> Binding<String?> {
        Binding(
            get: { [weak self] in self?.errors[field] },
            set: { [weak self] in self?.errors[field] = $0 }
        )
    }
}
