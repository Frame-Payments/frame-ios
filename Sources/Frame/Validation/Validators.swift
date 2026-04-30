//
//  Validators.swift
//  Frame-iOS
//

import Foundation
import EvervaultInputs
import PhoneNumberKit

public enum Validators {
    public static func validateNonEmpty(_ value: String, fieldName: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "\(fieldName) is required"
            : nil
    }

    public static func validateFullName(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Full name is required" }
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace }).filter { !$0.isEmpty }
        return parts.count >= 2 ? nil : "Enter first and last name"
    }

    public static func validateEmail(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Email is required" }
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        return trimmed.range(of: pattern, options: .regularExpression) == nil
            ? "Enter a valid email address"
            : nil
    }

    public static func validateZipUS(_ value: String) -> String? {
        if value.isEmpty { return "Zip code is required" }
        let isValid = value.count == 5 && value.allSatisfy { $0.isNumber }
        return isValid ? nil : "Enter a 5-digit zip code"
    }

    public static func validateCard(_ data: PaymentCardData) -> String? {
        data.isPotentiallyValid ? nil : "Enter valid card details"
    }

    public static func validateCardExpiry(month: String, year: String) -> String? {
        guard let m = Int(month), (1...12).contains(m) else { return "Invalid expiration month" }
        let yearString = year.count == 2 ? "20\(year)" : year
        guard let y = Int(yearString), y >= 2000, y <= 2100 else { return "Invalid expiration year" }

        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        guard let currentYear = now.year, let currentMonth = now.month else { return nil }
        if y < currentYear || (y == currentYear && m < currentMonth) {
            return "Card has expired"
        }
        return nil
    }

    public static func validateSSNLast4(_ value: String) -> String? {
        if value.isEmpty { return "SSN is required" }
        let isValid = value.count == 4 && value.allSatisfy { $0.isNumber }
        return isValid ? nil : "Enter last 4 digits of SSN"
    }

    public static func validateRoutingNumberUS(_ value: String) -> String? {
        if value.isEmpty { return "Routing number is required" }
        guard value.count == 9, value.allSatisfy({ $0.isNumber }) else {
            return "Enter a 9-digit routing number"
        }
        let digits = value.compactMap { Int(String($0)) }
        guard digits.count == 9 else { return "Enter a 9-digit routing number" }
        let checksum = (3 * (digits[0] + digits[3] + digits[6])
                      + 7 * (digits[1] + digits[4] + digits[7])
                      +     (digits[2] + digits[5] + digits[8])) % 10
        return checksum == 0 ? nil : "Enter a valid routing number"
    }

    public static func validateAccountNumberUS(_ value: String, min: Int = 4, max: Int = 17) -> String? {
        if value.isEmpty { return "Account number is required" }
        let isValid = value.allSatisfy({ $0.isNumber }) && (min...max).contains(value.count)
        return isValid ? nil : "Enter a valid account number"
    }

    public static func validateDateOfBirth(year: String, month: String, day: String,
                                           minAge: Int = 18, maxAge: Int = 120) -> String? {
        guard !year.isEmpty, !month.isEmpty, !day.isEmpty else {
            return "Date of birth is required"
        }
        guard year.count == 4, let y = Int(year),
              let m = Int(month), (1...12).contains(m),
              let d = Int(day), d >= 1 else {
            return "Enter a valid date of birth"
        }

        var components = DateComponents()
        components.year = y
        components.month = m
        components.day = d
        let calendar = Calendar(identifier: .gregorian)
        guard let dob = calendar.date(from: components) else {
            return "Enter a valid date of birth"
        }
        let validatedComponents = calendar.dateComponents([.year, .month, .day], from: dob)
        guard validatedComponents.year == y, validatedComponents.month == m, validatedComponents.day == d else {
            return "Enter a valid date of birth"
        }

        let age = calendar.dateComponents([.year], from: dob, to: Date()).year ?? 0
        if age < minAge { return "You must be at least \(minAge) years old" }
        if age > maxAge { return "Enter a valid date of birth" }
        return nil
    }

    private static let postalRegexes: [String: String] = [
        "US": #"^\d{5}(-\d{4})?$"#,
        "CA": #"^[A-Za-z]\d[A-Za-z][ -]?\d[A-Za-z]\d$"#,
        "GB": #"^[A-Za-z]{1,2}\d[A-Za-z\d]?\s*\d[A-Za-z]{2}$"#,
        "AU": #"^\d{4}$"#,
        "DE": #"^\d{5}$"#,
        "FR": #"^\d{5}$"#,
        "NL": #"^\d{4}\s?[A-Za-z]{2}$"#,
        "MX": #"^\d{5}$"#,
        "IN": #"^\d{6}$"#,
        "JP": #"^\d{3}-?\d{4}$"#,
        "BR": #"^\d{5}-?\d{3}$"#,
        "IT": #"^\d{5}$"#,
        "ES": #"^\d{5}$"#,
        "IE": #"^[A-Za-z]\d{2}\s?[A-Za-z\d]{4}$"#,
        "NZ": #"^\d{4}$"#,
        "SG": #"^\d{6}$"#
    ]

    public static func validatePostalCode(_ value: String, countryCode: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Postal code is required" }
        guard let pattern = postalRegexes[countryCode.uppercased()] else {
            return nil
        }
        return trimmed.range(of: pattern, options: .regularExpression) == nil
            ? "Enter a valid postal code"
            : nil
    }

    private static let phoneUtility = PhoneNumberUtility()

    public static func validatePhoneE164(_ raw: String, regionCode: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Phone number is required" }
        do {
            _ = try phoneUtility.parse(trimmed, withRegion: regionCode, ignoreType: true)
            return nil
        } catch {
            return "Enter a valid phone number"
        }
    }
}
