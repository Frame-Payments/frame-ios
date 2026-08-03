//
//  ValidatedTextFieldTests.swift
//  Frame-iOS
//

import XCTest
import SwiftUI
@testable import Frame

final class ValidatedTextFieldTests: XCTestCase {

    func testTextContentType_defaultsToNil() {
        let field = ValidatedTextField(prompt: "x",
                                       text: .constant(""),
                                       error: .constant(nil))
        XCTAssertNil(storedTextContentType(from: field))
    }

    func testTextContentType_storesProvidedValue() {
        let field = ValidatedTextField(prompt: "Zip",
                                       text: .constant(""),
                                       error: .constant(nil),
                                       textContentType: .postalCode)
        XCTAssertEqual(storedTextContentType(from: field), .postalCode)
    }

    func testTextContentType_isIndependentOfOtherOptionalParams() {
        let field = ValidatedTextField(prompt: "State",
                                       text: .constant(""),
                                       error: .constant(nil),
                                       keyboardType: .default,
                                       textContentType: .addressState,
                                       characterLimit: 2,
                                       inlineError: true)
        XCTAssertEqual(storedTextContentType(from: field), .addressState)
    }

    private func storedTextContentType(from field: ValidatedTextField) -> UITextContentType? {
        Mirror(reflecting: field).descendant("textContentType") as? UITextContentType
    }
}
