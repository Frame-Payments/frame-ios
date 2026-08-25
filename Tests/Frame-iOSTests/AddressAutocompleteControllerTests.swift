//
//  AddressAutocompleteControllerTests.swift
//  Frame-iOSTests
//

import XCTest
@testable import Frame

@MainActor
final class AddressAutocompleteControllerTests: XCTestCase {
    /// Counts the searches that actually reached the network seam, which is what the debounce is
    /// supposed to reduce.
    private final class SearchRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var queries: [String] = []

        func record(_ query: String) {
            lock.lock()
            defer { lock.unlock() }
            queries.append(query)
        }

        var recorded: [String] {
            lock.lock()
            defer { lock.unlock() }
            return queries
        }
    }

    private func suggestion(_ id: String) -> AddressSuggestion {
        AddressSuggestion(id: id, title: "Title \(id)", subtitle: "Subtitle \(id)")
    }

    /// A burst of keystrokes must produce one request, for the last query only.
    func testDebouncesABurstOfKeystrokesIntoOneSearch() async {
        let recorder = SearchRecorder()
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(10),
            search: { query, _ in
                recorder.record(query)
                return [AddressSuggestion(id: query, title: query, subtitle: "")]
            }
        )

        for query in ["100", "100 M", "100 Ma", "100 Mai", "100 Main"] {
            controller.queryChanged(query, countryCode: "US")
        }

        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertEqual(recorder.recorded, ["100 Main"])
        XCTAssertEqual(controller.suggestions.map(\.id), ["100 Main"])
    }

    /// A query shorter than the minimum sends nothing at all.
    func testShortQuerySendsNoRequest() async {
        let recorder = SearchRecorder()
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(10),
            search: { query, _ in
                recorder.record(query)
                return []
            }
        )

        controller.queryChanged("10", countryCode: "US")
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(recorder.recorded.isEmpty)
        XCTAssertTrue(controller.suggestions.isEmpty)
    }

    /// Backspacing below the minimum clears a list that is already showing.
    func testShortQueryClearsExistingSuggestions() async {
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(10),
            search: { query, _ in [AddressSuggestion(id: query, title: query, subtitle: "")] }
        )

        controller.queryChanged("100 Main", countryCode: "US")
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(controller.suggestions.isEmpty)

        controller.queryChanged("10", countryCode: "US")

        XCTAssertTrue(controller.suggestions.isEmpty)
    }

    /// A slow in-flight search must not overwrite the list once newer input has replaced it.
    func testCancelledSearchDoesNotPublishItsResults() async {
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(1),
            search: { query, _ in
                if query == "slow" {
                    try await Task.sleep(for: .milliseconds(300))
                    return [AddressSuggestion(id: "stale", title: "stale", subtitle: "")]
                }
                return [AddressSuggestion(id: "fresh", title: "fresh", subtitle: "")]
            }
        )

        controller.queryChanged("slow", countryCode: "US")
        try? await Task.sleep(for: .milliseconds(50))
        controller.queryChanged("fast", countryCode: "US")

        try? await Task.sleep(for: .milliseconds(400))

        XCTAssertEqual(controller.suggestions.map(\.id), ["fresh"])
    }

    /// A failing lookup leaves an empty list and no error, so manual entry carries on unaffected.
    func testFailedSearchYieldsEmptySuggestions() async {
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(10),
            search: { _, _ in throw AddressSearchError.unavailable }
        )

        controller.queryChanged("100 Main", countryCode: "US")
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(controller.suggestions.isEmpty)
    }

    func testCountryCodeReachesTheSearch() async {
        let received = SearchRecorder()
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(10),
            search: { _, country in
                received.record(country ?? "none")
                return []
            }
        )

        controller.queryChanged("100 Main", countryCode: "CA")
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(received.recorded, ["CA"])
    }

    func testSelectReturnsTheRetrievedAddressAndClearsTheList() async {
        let expected = FrameObjects.BillingAddress(
            city: "Toronto", country: "CA", state: "ON",
            postalCode: "M5V 2T6", addressLine1: "301 Front Street West"
        )
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(10),
            search: { query, _ in [AddressSuggestion(id: query, title: query, subtitle: "")] },
            retrieve: { _ in expected }
        )

        controller.queryChanged("301 Front", countryCode: "CA")
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(controller.suggestions.isEmpty)

        let address = await controller.select(suggestion("any"))

        XCTAssertEqual(address, expected)
        XCTAssertTrue(controller.suggestions.isEmpty)
    }

    /// A failed retrieve reports nothing, so the form keeps whatever the user typed.
    func testSelectReturnsNilWhenRetrieveFails() async {
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(10),
            retrieve: { _ in throw AddressSearchError.requestFailed }
        )

        let address = await controller.select(suggestion("any"))

        XCTAssertNil(address)
    }

    func testClearCancelsAndEmptiesTheList() async {
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(10),
            search: { query, _ in [AddressSuggestion(id: query, title: query, subtitle: "")] }
        )

        controller.queryChanged("100 Main", countryCode: "US")
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(controller.suggestions.isEmpty)

        controller.clear()

        XCTAssertTrue(controller.suggestions.isEmpty)
    }
}
