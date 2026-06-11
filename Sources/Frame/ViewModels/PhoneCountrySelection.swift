//
//  PhoneCountrySelection.swift
//  Frame-iOS
//

import Foundation
import PhoneNumberKit

/// A value that represents a single country available for phone-number dialling,
/// combining its ISO 3166-1 alpha-2 code with the corresponding international dial prefix.
///
/// `PhoneCountrySelection` is the model that backs the country-picker UI in the SDK's
/// phone-number entry flow.  All non-sanctioned countries supported by `PhoneNumberKit`
/// are surfaced through ``all``, and the device's current locale determines ``default``.
public struct PhoneCountrySelection: Hashable, Identifiable, Sendable {
    /// The ISO 3166-1 alpha-2 country code (e.g. `"US"`, `"GB"`), always uppercased.
    public let alpha2: String
    /// The international dialling prefix for the country, including the leading `+` (e.g. `"+1"`, `"+44"`).
    public let dialCode: String

    /// The stable identity of this selection, equal to ``alpha2``.
    public var id: String { alpha2 }

    /// The Unicode flag emoji that corresponds to the country's ``alpha2`` code.
    public var flag: String {
        let base: UInt32 = 127397
        var result = ""
        for scalar in alpha2.uppercased().unicodeScalars {
            if let flagScalar = UnicodeScalar(base + scalar.value) {
                result.unicodeScalars.append(flagScalar)
            }
        }
        return result
    }

    /// The country name localised to the device's current locale, falling back to ``alpha2`` when unavailable.
    public var displayName: String {
        Locale.current.localizedString(forRegionCode: alpha2) ?? alpha2
    }

    /// Creates a `PhoneCountrySelection` from an alpha-2 code and a dial-code string.
    ///
    /// Returns `nil` if `alpha2` is not exactly two ASCII letters.
    ///
    /// - Parameters:
    ///   - alpha2: A two-letter ISO 3166-1 alpha-2 country code.
    ///   - dialCode: The international dialling prefix, including the leading `+`.
    public init?(alpha2: String, dialCode: String) {
        guard alpha2.count == 2,
              alpha2.allSatisfy({ $0.isLetter && $0.isASCII }) else {
            return nil
        }
        self.alpha2 = alpha2.uppercased()
        self.dialCode = dialCode
    }

    /// All non-sanctioned countries supported by `PhoneNumberKit`, sorted alphabetically by localised display name.
    ///
    /// Countries on the SDK's restricted list (e.g. IR, RU, KP) are excluded.
    public static let all: [PhoneCountrySelection] = {
        let utility = PhoneNumberUtility()
        let restricted: Set<String> = ["IR", "RU", "KP", "SY", "CU", "CD", "IQ", "LY", "ML", "NI", "SD", "VE", "YE"]
        return utility.allCountries()
            .filter { !restricted.contains($0.uppercased()) }
            .compactMap { code -> PhoneCountrySelection? in
                guard let dial = utility.countryCode(for: code) else { return nil }
                return PhoneCountrySelection(alpha2: code, dialCode: "+\(dial)")
            }
            .sorted { $0.displayName < $1.displayName }
    }()

    /// Computed (not stored) so that a device locale change mid-session is reflected.
    /// The country that best matches the device's current locale, falling back to the United States.
    public static var `default`: PhoneCountrySelection {
        let region = Locale.current.region?.identifier ?? "US"
        return find(alpha2: region)
            ?? find(alpha2: "US")
            ?? PhoneCountrySelection(alpha2: "US", dialCode: "+1")!
    }

    /// Returns the entry in ``all`` whose ``alpha2`` matches the given code (case-insensitive), or `nil` if not found.
    ///
    /// - Parameter alpha2: The ISO 3166-1 alpha-2 country code to look up.
    /// - Returns: The matching ``PhoneCountrySelection``, or `nil`.
    public static func find(alpha2: String) -> PhoneCountrySelection? {
        let key = alpha2.uppercased()
        return all.first(where: { $0.alpha2 == key })
    }
}
