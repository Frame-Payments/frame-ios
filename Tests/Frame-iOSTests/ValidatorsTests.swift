//
//  ValidatorsTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame

final class ValidatorsTests: XCTestCase {

    // MARK: - Date of birth

    func testDateOfBirth_validAdult() {
        let cal = Calendar(identifier: .gregorian)
        let year = cal.component(.year, from: Date()) - 30
        XCTAssertNil(Validators.validateDateOfBirth(year: "\(year)", month: "06", day: "15"))
    }

    func testDateOfBirth_leapDay_isAccepted() {
        // Regression: Feb 29 in a leap year must round-trip through Calendar without rejection.
        XCTAssertNil(Validators.validateDateOfBirth(year: "2000", month: "02", day: "29"))
    }

    func testDateOfBirth_feb29InNonLeapYear_isRejected() {
        XCTAssertNotNil(Validators.validateDateOfBirth(year: "2001", month: "02", day: "29"))
    }

    func testDateOfBirth_invalidDay_isRejected() {
        XCTAssertNotNil(Validators.validateDateOfBirth(year: "1990", month: "04", day: "31"))
        XCTAssertNotNil(Validators.validateDateOfBirth(year: "1990", month: "13", day: "01"))
        XCTAssertNotNil(Validators.validateDateOfBirth(year: "1990", month: "00", day: "10"))
        XCTAssertNotNil(Validators.validateDateOfBirth(year: "1990", month: "01", day: "00"))
    }

    func testDateOfBirth_emptyParts_required() {
        XCTAssertNotNil(Validators.validateDateOfBirth(year: "", month: "01", day: "01"))
        XCTAssertNotNil(Validators.validateDateOfBirth(year: "1990", month: "", day: "01"))
        XCTAssertNotNil(Validators.validateDateOfBirth(year: "1990", month: "01", day: ""))
    }

    func testDateOfBirth_shortYear_isRejected() {
        XCTAssertNotNil(Validators.validateDateOfBirth(year: "90", month: "01", day: "01"))
    }

    func testDateOfBirth_underMinAge_isRejected() {
        let cal = Calendar(identifier: .gregorian)
        let year = cal.component(.year, from: Date()) - 5
        XCTAssertNotNil(Validators.validateDateOfBirth(year: "\(year)", month: "01", day: "01"))
    }

    func testDateOfBirth_overMaxAge_isRejected() {
        XCTAssertNotNil(Validators.validateDateOfBirth(year: "1800", month: "01", day: "01"))
    }

    func testDateOfBirth_unpaddedMonthDay_isAccepted() {
        // The view sometimes hands single-digit values straight through; the validator should still accept.
        XCTAssertNil(Validators.validateDateOfBirth(year: "1990", month: "1", day: "5"))
    }

    // MARK: - DateOfBirthFormatter

    func testDateOfBirthFormatter_padsSingleDigits() {
        XCTAssertEqual(DateOfBirthFormatter.format(year: "1990", month: "1", day: "5"), "1990-01-05")
    }

    func testDateOfBirthFormatter_passesThroughPadded() {
        XCTAssertEqual(DateOfBirthFormatter.format(year: "1990", month: "12", day: "25"), "1990-12-25")
    }

    func testDateOfBirthFormatter_emptyAnyPart_returnsEmpty() {
        XCTAssertEqual(DateOfBirthFormatter.format(year: "", month: "1", day: "1"), "")
        XCTAssertEqual(DateOfBirthFormatter.format(year: "1990", month: "", day: "1"), "")
        XCTAssertEqual(DateOfBirthFormatter.format(year: "1990", month: "1", day: ""), "")
    }

    // MARK: - Phone (E.164 via PhoneNumberKit)

    func testPhone_validUS() {
        XCTAssertNil(Validators.validatePhoneE164("+1 415 555 2671", regionCode: "US"))
        XCTAssertNil(Validators.validatePhoneE164("(415) 555-2671", regionCode: "US"))
    }

    func testPhone_empty_required() {
        XCTAssertNotNil(Validators.validatePhoneE164("", regionCode: "US"))
        XCTAssertNotNil(Validators.validatePhoneE164("   ", regionCode: "US"))
    }

    func testPhone_garbage_isRejected() {
        XCTAssertNotNil(Validators.validatePhoneE164("abc", regionCode: "US"))
        XCTAssertNotNil(Validators.validatePhoneE164("12", regionCode: "US"))
    }

    // MARK: - Postal code

    func testPostal_US() {
        XCTAssertNil(Validators.validatePostalCode("75115", countryCode: "US"))
        XCTAssertNil(Validators.validatePostalCode("75115-1234", countryCode: "US"))
        XCTAssertNotNil(Validators.validatePostalCode("7511", countryCode: "US"))
        XCTAssertNotNil(Validators.validatePostalCode("abcde", countryCode: "US"))
        XCTAssertNotNil(Validators.validatePostalCode("", countryCode: "US"))
    }

    func testPostal_CA() {
        XCTAssertNil(Validators.validatePostalCode("K1A 0B1", countryCode: "CA"))
        XCTAssertNil(Validators.validatePostalCode("K1A0B1", countryCode: "CA"))
        XCTAssertNotNil(Validators.validatePostalCode("123456", countryCode: "CA"))
    }

    func testPostal_GB_acceptsCommonForms() {
        XCTAssertNil(Validators.validatePostalCode("EC1A 1BB", countryCode: "GB"))
        XCTAssertNil(Validators.validatePostalCode("M1 1AA", countryCode: "GB"))
        XCTAssertNil(Validators.validatePostalCode("CR2 6XH", countryCode: "GB"))
        XCTAssertNotNil(Validators.validatePostalCode("XYZ", countryCode: "GB"))
    }

    func testPostal_unknownCountry_returnsNil() {
        // Unmapped countries should not block the user.
        XCTAssertNil(Validators.validatePostalCode("anything-goes", countryCode: "ZZ"))
    }

    // MARK: - SSN (last 4)

    func testSSN_valid() {
        XCTAssertNil(Validators.validateSSNLast4("1234"))
        XCTAssertNil(Validators.validateSSNLast4("0000"))
    }

    func testSSN_invalid() {
        XCTAssertNotNil(Validators.validateSSNLast4(""))
        XCTAssertNotNil(Validators.validateSSNLast4("123"))
        XCTAssertNotNil(Validators.validateSSNLast4("12345"))
        XCTAssertNotNil(Validators.validateSSNLast4("12a4"))
    }

    // MARK: - Routing number (US ABA checksum)

    func testRoutingNumber_validChecksum() {
        // 011000015 — Federal Reserve Bank of Boston, well-known valid routing number.
        XCTAssertNil(Validators.validateRoutingNumberUS("011000015"))
    }

    func testRoutingNumber_invalidChecksum() {
        XCTAssertNotNil(Validators.validateRoutingNumberUS("011000016"))
    }

    func testRoutingNumber_wrongLength() {
        XCTAssertNotNil(Validators.validateRoutingNumberUS(""))
        XCTAssertNotNil(Validators.validateRoutingNumberUS("12345678"))
        XCTAssertNotNil(Validators.validateRoutingNumberUS("1234567890"))
        XCTAssertNotNil(Validators.validateRoutingNumberUS("01100001a"))
    }

    // MARK: - Account number

    func testAccountNumber_valid() {
        XCTAssertNil(Validators.validateAccountNumberUS("12345678"))
        XCTAssertNil(Validators.validateAccountNumberUS("1234"))
        XCTAssertNil(Validators.validateAccountNumberUS("12345678901234567"))
    }

    func testAccountNumber_invalid() {
        XCTAssertNotNil(Validators.validateAccountNumberUS(""))
        XCTAssertNotNil(Validators.validateAccountNumberUS("123"))
        XCTAssertNotNil(Validators.validateAccountNumberUS("123456789012345678"))
        XCTAssertNotNil(Validators.validateAccountNumberUS("1234abcd"))
    }
}
