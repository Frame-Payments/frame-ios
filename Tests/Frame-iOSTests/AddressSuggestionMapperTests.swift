//
//  AddressSuggestionMapperTests.swift
//  Frame-iOSTests
//

import XCTest
@testable import Frame

final class AddressSuggestionMapperTests: XCTestCase {
    private func feature(from json: String) throws -> MapboxSearchResponses.RetrieveResponse.Feature {
        let response = try JSONDecoder().decode(
            MapboxSearchResponses.RetrieveResponse.self,
            from: Data(json.utf8)
        )
        return try XCTUnwrap(response.features.first)
    }

    func testMapsUSAddressWithRegionCode() throws {
        let feature = try feature(from: """
        {"features": [{"properties": {
            "name": "1600 Pennsylvania Avenue Northwest",
            "address": "1600 Pennsylvania Avenue Northwest",
            "context": {
                "place": {"name": "Washington"},
                "region": {"name": "District of Columbia", "region_code": "DC"},
                "postcode": {"name": "20500"},
                "country": {"name": "United States", "country_code": "us"}
            }
        }}]}
        """)

        let address = AddressSuggestionMapper.billingAddress(from: feature)

        XCTAssertEqual(address.addressLine1, "1600 Pennsylvania Avenue Northwest")
        XCTAssertEqual(address.city, "Washington")
        XCTAssertEqual(address.state, "DC")
        XCTAssertEqual(address.postalCode, "20500")
        XCTAssertEqual(address.country, "US")
        XCTAssertNil(address.addressLine2)
    }

    /// Mapbox returns `US-CA` in some responses; the SDK's validation matches on `CA`.
    func testStripsCountryPrefixFromRegionCode() throws {
        let feature = try feature(from: """
        {"features": [{"properties": {
            "address": "1 Market Street",
            "context": {
                "region": {"name": "California", "region_code": "US-CA"},
                "country": {"country_code": "us"}
            }
        }}]}
        """)

        XCTAssertEqual(AddressSuggestionMapper.billingAddress(from: feature).state, "CA")
    }

    /// The ticket's non-US-with-a-full-name-state case. `Validators.validateSubregion` runs before
    /// `normalize()`, so a full name has to be resolved to a code here or validation fails.
    func testResolvesFullStateNameToCodeWhenNoRegionCode() throws {
        let feature = try feature(from: """
        {"features": [{"properties": {
            "address": "301 Front Street West",
            "context": {
                "place": {"name": "Toronto"},
                "region": {"name": "Ontario"},
                "postcode": {"name": "M5V 2T6"},
                "country": {"country_code": "ca"}
            }
        }}]}
        """)

        let address = AddressSuggestionMapper.billingAddress(from: feature)

        XCTAssertEqual(address.state, "ON")
        XCTAssertEqual(address.country, "CA")
        XCTAssertNil(Validators.validateSubregion(try XCTUnwrap(address.state), countryCode: "CA"))
    }

    /// A country with no enumerated subregion list keeps whatever Mapbox sent, since there is no
    /// code to resolve to and `validateSubregion` accepts free text there.
    func testKeepsSubregionNameForCountryWithoutSubregionList() throws {
        let feature = try feature(from: """
        {"features": [{"properties": {
            "address": "10 Downing Street",
            "context": {
                "place": {"name": "London"},
                "region": {"name": "England"},
                "postcode": {"name": "SW1A 2AA"},
                "country": {"country_code": "gb"}
            }
        }}]}
        """)

        let address = AddressSuggestionMapper.billingAddress(from: feature)

        XCTAssertEqual(address.state, "England")
        XCTAssertNil(Validators.validateSubregion("England", countryCode: "GB"))
    }

    /// The ticket's missing-postal-code case. `postalCode` is non-optional on the model, so an
    /// absent one has to become empty rather than crashing or dropping the rest of the address.
    func testMissingPostalCodeBecomesEmptyString() throws {
        let feature = try feature(from: """
        {"features": [{"properties": {
            "address": "1 Infinite Loop",
            "context": {
                "place": {"name": "Cupertino"},
                "region": {"region_code": "CA"},
                "country": {"country_code": "us"}
            }
        }}]}
        """)

        let address = AddressSuggestionMapper.billingAddress(from: feature)

        XCTAssertEqual(address.postalCode, "")
        XCTAssertEqual(address.city, "Cupertino")
        XCTAssertEqual(address.state, "CA")
    }

    /// Mapbox omits `address` for some results; the display name is the only line 1 available.
    func testFallsBackToNameWhenAddressAbsent() throws {
        let feature = try feature(from: """
        {"features": [{"properties": {
            "name": "Empire State Building",
            "context": {"country": {"country_code": "us"}}
        }}]}
        """)

        XCTAssertEqual(
            AddressSuggestionMapper.billingAddress(from: feature).addressLine1,
            "Empire State Building"
        )
    }

    func testMissingContextYieldsAddressLineOnly() throws {
        let feature = try feature(from: """
        {"features": [{"properties": {"address": "Somewhere"}}]}
        """)

        let address = AddressSuggestionMapper.billingAddress(from: feature)

        XCTAssertEqual(address.addressLine1, "Somewhere")
        XCTAssertNil(address.city)
        XCTAssertNil(address.state)
        XCTAssertNil(address.country)
        XCTAssertEqual(address.postalCode, "")
    }
}
