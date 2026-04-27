//
//  Validators.swift
//  Frame-iOS
//

import Foundation
import EvervaultInputs

enum Validators {
    static func validateNonEmpty(_ value: String, fieldName: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "\(fieldName) is required"
            : nil
    }

    static func validateFullName(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Full name is required" }
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace }).filter { !$0.isEmpty }
        return parts.count >= 2 ? nil : "Enter first and last name"
    }

    static func validateEmail(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Email is required" }
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        return trimmed.range(of: pattern, options: .regularExpression) == nil
            ? "Enter a valid email address"
            : nil
    }

    static func validateZipUS(_ value: String) -> String? {
        if value.isEmpty { return "Zip code is required" }
        let isValid = value.count == 5 && value.allSatisfy { $0.isNumber }
        return isValid ? nil : "Enter a 5-digit zip code"
    }

    static func validateCard(_ data: PaymentCardData) -> String? {
        data.isPotentiallyValid ? nil : "Enter valid card details"
    }
}
