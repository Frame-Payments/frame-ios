//
//  TextFieldInputRestrictionTests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame

/// Coverage for which characters name and locality fields accept. The filter runs on every input
/// path — typing, paste, autofill — so these cases stand in for all three.
final class TextFieldInputRestrictionTests: XCTestCase {

    // MARK: - What must be stripped

    func testDigitsAreStripped() {
        XCTAssertEqual(TextFieldInputRestriction.textOnly.filter("John123"), "John")
        XCTAssertEqual(TextFieldInputRestriction.textOnly.filter("4New York"), "New York")
    }

    func testSymbolsAreStripped() {
        XCTAssertEqual(TextFieldInputRestriction.textOnly.filter("New York@#$"), "New York")
        XCTAssertEqual(TextFieldInputRestriction.textOnly.filter("Jo*hn!"), "John")
    }

    /// A paste of nothing but disallowed characters empties the field rather than trapping.
    func testFullyInvalidInputBecomesEmpty() {
        XCTAssertEqual(TextFieldInputRestriction.textOnly.filter("12345"), "")
        XCTAssertEqual(TextFieldInputRestriction.textOnly.filter("@#$%^&"), "")
    }

    // MARK: - What must survive

    /// Real names and place names carry this punctuation. Stripping it would corrupt a legal name
    /// that KYC then compares against a government ID.
    func testNamePunctuationIsPreserved() {
        for value in ["O'Fallon", "O'Brien", "Stoke-on-Trent", "Winston-Salem",
                      "Smith-Jones", "St. Louis", "Jr."] {
            XCTAssertEqual(TextFieldInputRestriction.textOnly.filter(value), value)
        }
    }

    /// "Letter" means any Unicode letter, not `A-Za-z` — the SDK ships 17 countries.
    func testNonASCIILettersArePreserved() {
        for value in ["José", "Müller", "Renée", "李", "Þórsdóttir", "Ólafur"] {
            XCTAssertEqual(TextFieldInputRestriction.textOnly.filter(value), value)
        }
    }

    func testSpacesArePreserved() {
        XCTAssertEqual(TextFieldInputRestriction.textOnly.filter("New York City"), "New York City")
    }

    // MARK: - Opt-in

    /// Fields that never opted in keep taking whatever they took before.
    func testNoneRestrictionLeavesInputUntouched() {
        for value in ["123 Main St", "Apt #4", "John123", ""] {
            XCTAssertEqual(TextFieldInputRestriction.none.filter(value), value)
        }
    }

    func testEmptyStringIsUnchanged() {
        XCTAssertEqual(TextFieldInputRestriction.textOnly.filter(""), "")
    }
}
