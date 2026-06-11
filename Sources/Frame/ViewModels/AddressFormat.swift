//
//  AddressFormat.swift
//  Frame-iOS
//

import Foundation
import UIKit

/// Locale-aware address formatting rules used to tailor address-entry UI for a given country.
///
/// Each instance describes the appropriate labels and keyboard types for the state/region and
/// postal-code fields.  Retrieve the correct format for a country via ``format(forCountry:)``.
public struct AddressFormat: Equatable {
    /// The localized label for the state or region field (e.g. "State", "Province", "County").
    public let stateLabel: String
    /// The localized label for the postal code field (e.g. "Zip Code", "Postcode", "PIN Code").
    public let postalLabel: String
    /// The keyboard type best suited for entering the country's postal code format.
    public let postalKeyboard: UIKeyboardType
    /// The maximum character length allowed for the state/region field, or `nil` if unrestricted.
    public let stateMaxLength: Int?

    /// Creates an ``AddressFormat`` with explicit field labels, keyboard type, and optional state length cap.
    ///
    /// - Parameters:
    ///   - stateLabel: Localized label for the state or region input field.
    ///   - postalLabel: Localized label for the postal code input field.
    ///   - postalKeyboard: Keyboard type to display when editing the postal code field.
    ///   - stateMaxLength: Maximum character count for the state field, or `nil` for no limit.
    public init(stateLabel: String, postalLabel: String, postalKeyboard: UIKeyboardType, stateMaxLength: Int?) {
        self.stateLabel = stateLabel
        self.postalLabel = postalLabel
        self.postalKeyboard = postalKeyboard
        self.stateMaxLength = stateMaxLength
    }

    private static let formats: [String: AddressFormat] = [
        "US": AddressFormat(stateLabel: "State", postalLabel: "Zip Code", postalKeyboard: .numberPad, stateMaxLength: 2),
        "CA": AddressFormat(stateLabel: "Province", postalLabel: "Postal Code", postalKeyboard: .default, stateMaxLength: 2),
        "GB": AddressFormat(stateLabel: "County", postalLabel: "Postcode", postalKeyboard: .default, stateMaxLength: nil),
        "AU": AddressFormat(stateLabel: "State", postalLabel: "Postcode", postalKeyboard: .numberPad, stateMaxLength: nil),
        "DE": AddressFormat(stateLabel: "State", postalLabel: "Postal Code", postalKeyboard: .numberPad, stateMaxLength: nil),
        "FR": AddressFormat(stateLabel: "Region", postalLabel: "Postal Code", postalKeyboard: .numberPad, stateMaxLength: nil),
        "NL": AddressFormat(stateLabel: "Province", postalLabel: "Postcode", postalKeyboard: .default, stateMaxLength: nil),
        "JP": AddressFormat(stateLabel: "Prefecture", postalLabel: "Postal Code", postalKeyboard: .default, stateMaxLength: nil),
        "MX": AddressFormat(stateLabel: "State", postalLabel: "Postal Code", postalKeyboard: .numberPad, stateMaxLength: nil),
        "IN": AddressFormat(stateLabel: "State", postalLabel: "PIN Code", postalKeyboard: .numberPad, stateMaxLength: nil),
        "IE": AddressFormat(stateLabel: "County", postalLabel: "Eircode", postalKeyboard: .default, stateMaxLength: nil),
        "NZ": AddressFormat(stateLabel: "Region", postalLabel: "Postcode", postalKeyboard: .numberPad, stateMaxLength: nil),
        "BR": AddressFormat(stateLabel: "State", postalLabel: "CEP", postalKeyboard: .numberPad, stateMaxLength: nil),
        "IT": AddressFormat(stateLabel: "Province", postalLabel: "Postal Code", postalKeyboard: .numberPad, stateMaxLength: nil),
        "ES": AddressFormat(stateLabel: "Province", postalLabel: "Postal Code", postalKeyboard: .numberPad, stateMaxLength: nil),
        "SG": AddressFormat(stateLabel: "Region", postalLabel: "Postal Code", postalKeyboard: .numberPad, stateMaxLength: nil)
    ]

    private static let `default` = AddressFormat(stateLabel: "State",
                                                 postalLabel: "Postal Code",
                                                 postalKeyboard: .default,
                                                 stateMaxLength: nil)

    /// Returns the ``AddressFormat`` for the given ISO 3166-1 alpha-2 country code, falling back to a generic default.
    ///
    /// - Parameter alpha2: A two-letter ISO 3166-1 alpha-2 country code (case-insensitive, e.g. `"US"`, `"gb"`).
    /// - Returns: The country-specific ``AddressFormat``, or a generic format if the country is not recognised.
    public static func format(forCountry alpha2: String) -> AddressFormat {
        formats[alpha2.uppercased()] ?? .default
    }
}
