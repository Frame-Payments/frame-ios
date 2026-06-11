//
//  Validators.swift
//  Frame-iOS
//

import Foundation
import EvervaultInputs
import PhoneNumberKit

/// A namespace of pure validation functions used throughout the Frame SDK.
///
/// Each method accepts a raw string value (and optional context parameters) and returns
/// either `nil` when the value is valid or a human-readable error message when it is not.
public enum Validators {

    /// Validates that a string contains at least one non-whitespace character.
    ///
    /// - Parameters:
    ///   - value: The string to validate.
    ///   - fieldName: The display name of the field, used in the error message.
    /// - Returns: An error message if the value is empty, or `nil` if it is non-empty.
    public static func validateNonEmpty(_ value: String, fieldName: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "\(fieldName) is required"
            : nil
    }

    /// Validates that a string represents a full name containing at least a first and last name.
    ///
    /// - Parameter value: The full name string to validate.
    /// - Returns: An error message if the name is empty or contains fewer than two words, or `nil` if valid.
    public static func validateFullName(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Full name is required" }
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace }).filter { !$0.isEmpty }
        return parts.count >= 2 ? nil : "Enter first and last name"
    }

    /// Validates that a string is a properly formatted email address.
    ///
    /// - Parameter value: The email address string to validate.
    /// - Returns: An error message if the value is empty or does not match a basic email pattern, or `nil` if valid.
    public static func validateEmail(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Email is required" }
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        return trimmed.range(of: pattern, options: .regularExpression) == nil
            ? "Enter a valid email address"
            : nil
    }

    /// Validates that a string is a 5-digit US ZIP code.
    ///
    /// - Parameter value: The ZIP code string to validate.
    /// - Returns: An error message if the value is empty or not exactly 5 digits, or `nil` if valid.
    public static func validateZipUS(_ value: String) -> String? {
        if value.isEmpty { return "Zip code is required" }
        let isValid = value.count == 5 && value.allSatisfy { $0.isNumber }
        return isValid ? nil : "Enter a 5-digit zip code"
    }

    /// Validates that a `PaymentCardData` object represents a potentially valid card.
    ///
    /// - Parameter data: The payment card data to validate.
    /// - Returns: An error message if the card data is not potentially valid, or `nil` if valid.
    public static func validateCard(_ data: PaymentCardData) -> String? {
        data.isPotentiallyValid ? nil : "Enter valid card details"
    }

    /// Validates that a month/year pair represents a card expiry date that has not yet passed.
    ///
    /// - Parameters:
    ///   - month: The expiry month as a 1- or 2-digit string (e.g. `"1"` or `"01"`).
    ///   - year: The expiry year as a 2- or 4-digit string (e.g. `"26"` or `"2026"`).
    /// - Returns: An error message if the month or year are invalid or the card is expired, or `nil` if valid.
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

    /// Validates that a string is a 4-digit Social Security Number suffix.
    ///
    /// - Parameter value: The last 4 digits of an SSN.
    /// - Returns: An error message if the value is empty or not exactly 4 digits, or `nil` if valid.
    public static func validateSSNLast4(_ value: String) -> String? {
        if value.isEmpty { return "SSN is required" }
        let isValid = value.count == 4 && value.allSatisfy { $0.isNumber }
        return isValid ? nil : "Enter last 4 digits of SSN"
    }

    /// Validates that a string is a valid 9-digit US ABA routing number using the standard checksum algorithm.
    ///
    /// - Parameter value: The routing number string to validate.
    /// - Returns: An error message if the value is empty, not 9 digits, or fails the checksum, or `nil` if valid.
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

    /// Validates that a string is a numeric US bank account number within the allowed length range.
    ///
    /// - Parameters:
    ///   - value: The account number string to validate.
    ///   - min: The minimum accepted digit count (default `4`).
    ///   - max: The maximum accepted digit count (default `17`).
    /// - Returns: An error message if the value is empty, non-numeric, or outside the length range, or `nil` if valid.
    public static func validateAccountNumberUS(_ value: String, min: Int = 4, max: Int = 17) -> String? {
        if value.isEmpty { return "Account number is required" }
        let isValid = value.allSatisfy({ $0.isNumber }) && (min...max).contains(value.count)
        return isValid ? nil : "Enter a valid account number"
    }

    /// Validates that year, month, and day strings represent a real date within an acceptable age range.
    ///
    /// - Parameters:
    ///   - year: A 4-digit year string.
    ///   - month: A 1- or 2-digit month string.
    ///   - day: A 1- or 2-digit day string.
    ///   - minAge: The minimum age in years the date of birth must satisfy (default `18`).
    ///   - maxAge: The maximum age in years the date of birth must satisfy (default `120`).
    /// - Returns: An error message if any component is missing, the date is invalid, or the resulting age is outside the allowed range, or `nil` if valid.
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

    /// Validates that a string matches the postal code format for a given ISO 3166-1 alpha-2 country code.
    ///
    /// Supported country codes: US, CA, GB, AU, DE, FR, NL, MX, IN, JP, BR, IT, ES, IE, NZ, SG.
    /// For unsupported country codes the value is considered valid and `nil` is returned.
    ///
    /// - Parameters:
    ///   - value: The postal code string to validate.
    ///   - countryCode: An ISO 3166-1 alpha-2 country code (case-insensitive).
    /// - Returns: An error message if the value is empty or does not match the country's pattern, or `nil` if valid.
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

    /// Validates that a raw phone number string is parseable as a valid number for the given region.
    ///
    /// - Parameters:
    ///   - raw: The phone number string to validate (any format accepted by PhoneNumberKit).
    ///   - regionCode: An ISO 3166-1 alpha-2 region code used to interpret the number (e.g. `"US"`).
    /// - Returns: An error message if the value is empty or cannot be parsed, or `nil` if valid.
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
