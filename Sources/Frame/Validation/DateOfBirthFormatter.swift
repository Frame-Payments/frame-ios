//
//  DateOfBirthFormatter.swift
//  Frame-iOS
//

import Foundation

public enum DateOfBirthFormatter {
    /// Assembles ISO 8601 "YYYY-MM-DD" with zero-padded month/day. Returns an empty string if any component is empty.
    public static func format(year: String, month: String, day: String) -> String {
        guard !year.isEmpty, !month.isEmpty, !day.isEmpty else { return "" }
        let paddedYear = year.count >= 4 ? year : String(repeating: "0", count: 4 - year.count) + year
        let paddedMonth = month.count == 2 ? month : "0" + month
        let paddedDay = day.count == 2 ? day : "0" + day
        return "\(paddedYear)-\(paddedMonth)-\(paddedDay)"
    }
}
