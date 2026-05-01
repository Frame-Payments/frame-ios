//
//  BillingAddressViewModel.swift
//  Frame-iOS
//

import SwiftUI
import Frame

public enum BillingAddressMode: Sendable {
    case usOnly, international
}

@MainActor
public final class BillingAddressViewModel: ObservableObject {
    public enum Field: Hashable, Sendable {
        case line1, city, state, postal, country
    }

    @Published public var address: FrameObjects.BillingAddress
    @Published public var errors: [Field: String] = [:]
    public let mode: BillingAddressMode

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

    public func errorBinding(_ field: Field) -> Binding<String?> {
        Binding(
            get: { [weak self] in self?.errors[field] },
            set: { [weak self] in self?.errors[field] = $0 }
        )
    }
}
