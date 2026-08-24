//
//  AddressSubregions.swift
//  Frame-iOS
//

import Foundation

/// A state, province, or territory that the Frame API accepts for a given country.
public struct AddressSubregion: Hashable, Sendable, Identifiable {
    /// The subregion's code as submitted to the API (e.g. `"TX"`, `"ON"`).
    public let code: String
    /// The subregion's full display name (e.g. `"Texas"`, `"Ontario"`).
    public let name: String

    /// Stable identity for use in SwiftUI lists — the subregion code.
    public var id: String { code }

    /// Creates a subregion.
    public init(code: String, name: String) {
        self.code = code
        self.name = name
    }
}

/// The subregions (states / provinces / territories) the Frame API accepts for a country.
public enum AddressSubregions {

    /// The subregions accepted for United States addresses.
    public static let unitedStates: [AddressSubregion] = [
        AddressSubregion(code: "AL", name: "Alabama"),
        AddressSubregion(code: "AK", name: "Alaska"),
        AddressSubregion(code: "AZ", name: "Arizona"),
        AddressSubregion(code: "AR", name: "Arkansas"),
        AddressSubregion(code: "CA", name: "California"),
        AddressSubregion(code: "CO", name: "Colorado"),
        AddressSubregion(code: "CT", name: "Connecticut"),
        AddressSubregion(code: "DE", name: "Delaware"),
        AddressSubregion(code: "DC", name: "District of Columbia"),
        AddressSubregion(code: "FL", name: "Florida"),
        AddressSubregion(code: "GA", name: "Georgia"),
        AddressSubregion(code: "HI", name: "Hawaii"),
        AddressSubregion(code: "ID", name: "Idaho"),
        AddressSubregion(code: "IL", name: "Illinois"),
        AddressSubregion(code: "IN", name: "Indiana"),
        AddressSubregion(code: "IA", name: "Iowa"),
        AddressSubregion(code: "KS", name: "Kansas"),
        AddressSubregion(code: "KY", name: "Kentucky"),
        AddressSubregion(code: "LA", name: "Louisiana"),
        AddressSubregion(code: "ME", name: "Maine"),
        AddressSubregion(code: "MD", name: "Maryland"),
        AddressSubregion(code: "MA", name: "Massachusetts"),
        AddressSubregion(code: "MI", name: "Michigan"),
        AddressSubregion(code: "MN", name: "Minnesota"),
        AddressSubregion(code: "MS", name: "Mississippi"),
        AddressSubregion(code: "MO", name: "Missouri"),
        AddressSubregion(code: "MT", name: "Montana"),
        AddressSubregion(code: "NE", name: "Nebraska"),
        AddressSubregion(code: "NV", name: "Nevada"),
        AddressSubregion(code: "NH", name: "New Hampshire"),
        AddressSubregion(code: "NJ", name: "New Jersey"),
        AddressSubregion(code: "NM", name: "New Mexico"),
        AddressSubregion(code: "NY", name: "New York"),
        AddressSubregion(code: "NC", name: "North Carolina"),
        AddressSubregion(code: "ND", name: "North Dakota"),
        AddressSubregion(code: "OH", name: "Ohio"),
        AddressSubregion(code: "OK", name: "Oklahoma"),
        AddressSubregion(code: "OR", name: "Oregon"),
        AddressSubregion(code: "PA", name: "Pennsylvania"),
        AddressSubregion(code: "RI", name: "Rhode Island"),
        AddressSubregion(code: "SC", name: "South Carolina"),
        AddressSubregion(code: "SD", name: "South Dakota"),
        AddressSubregion(code: "TN", name: "Tennessee"),
        AddressSubregion(code: "TX", name: "Texas"),
        AddressSubregion(code: "UT", name: "Utah"),
        AddressSubregion(code: "VT", name: "Vermont"),
        AddressSubregion(code: "VA", name: "Virginia"),
        AddressSubregion(code: "WA", name: "Washington"),
        AddressSubregion(code: "WV", name: "West Virginia"),
        AddressSubregion(code: "WI", name: "Wisconsin"),
        AddressSubregion(code: "WY", name: "Wyoming"),
        AddressSubregion(code: "AS", name: "American Samoa"),
        AddressSubregion(code: "GU", name: "Guam"),
        AddressSubregion(code: "MP", name: "Northern Mariana Islands"),
        AddressSubregion(code: "PR", name: "Puerto Rico"),
        AddressSubregion(code: "VI", name: "U.S. Virgin Islands")
    ]

    /// The subregions accepted for Canadian addresses — 10 provinces and 3 territories.
    public static let canada: [AddressSubregion] = [
        AddressSubregion(code: "AB", name: "Alberta"),
        AddressSubregion(code: "BC", name: "British Columbia"),
        AddressSubregion(code: "MB", name: "Manitoba"),
        AddressSubregion(code: "NB", name: "New Brunswick"),
        AddressSubregion(code: "NL", name: "Newfoundland and Labrador"),
        AddressSubregion(code: "NT", name: "Northwest Territories"),
        AddressSubregion(code: "NS", name: "Nova Scotia"),
        AddressSubregion(code: "NU", name: "Nunavut"),
        AddressSubregion(code: "ON", name: "Ontario"),
        AddressSubregion(code: "PE", name: "Prince Edward Island"),
        AddressSubregion(code: "QC", name: "Quebec"),
        AddressSubregion(code: "SK", name: "Saskatchewan"),
        AddressSubregion(code: "YT", name: "Yukon")
    ]

    private static let byCountry: [String: [AddressSubregion]] = [
        "US": unitedStates,
        "CA": canada
    ]

    /// Returns the subregions for a country, or `nil` when its subregion is unvalidated free text.
    public static func subregions(forCountry alpha2: String) -> [AddressSubregion]? {
        let trimmed = alpha2.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return unitedStates }
        return byCountry[trimmed.uppercased()]
    }

    /// Returns the accepted subregion codes for a country, or `nil` when the country is unvalidated.
    public static func codes(forCountry alpha2: String) -> Set<String>? {
        subregions(forCountry: alpha2).map { Set($0.map(\.code)) }
    }

    /// Looks up a subregion by its code within a country's list.
    public static func subregion(forCode code: String, countryCode alpha2: String) -> AddressSubregion? {
        let needle = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return subregions(forCountry: alpha2)?.first { $0.code == needle }
    }

    /// Trims a subregion, upcasing it only for countries whose subregions are validated as codes.
    public static func normalize(_ value: String, countryCode alpha2: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return subregions(forCountry: alpha2) == nil ? trimmed : trimmed.uppercased()
    }
}
