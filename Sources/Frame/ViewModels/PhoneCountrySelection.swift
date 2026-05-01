//
//  PhoneCountrySelection.swift
//  Frame-iOS
//

import Foundation
import PhoneNumberKit

public struct PhoneCountrySelection: Hashable, Identifiable, Sendable {
    public let alpha2: String
    public let dialCode: String

    public var id: String { alpha2 }

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

    public var displayName: String {
        Locale.current.localizedString(forRegionCode: alpha2) ?? alpha2
    }

    public init?(alpha2: String, dialCode: String) {
        guard alpha2.count == 2,
              alpha2.allSatisfy({ $0.isLetter && $0.isASCII }) else {
            return nil
        }
        self.alpha2 = alpha2.uppercased()
        self.dialCode = dialCode
    }

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
    public static var `default`: PhoneCountrySelection {
        let region = Locale.current.region?.identifier ?? "US"
        return find(alpha2: region)
            ?? find(alpha2: "US")
            ?? PhoneCountrySelection(alpha2: "US", dialCode: "+1")!
    }

    public static func find(alpha2: String) -> PhoneCountrySelection? {
        let key = alpha2.uppercased()
        return all.first(where: { $0.alpha2 == key })
    }
}
