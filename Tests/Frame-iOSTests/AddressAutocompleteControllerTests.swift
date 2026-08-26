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

    /// A request that already reached the network must survive the next keystroke. Cancelling it
    /// is what forced the user to stop typing before any list could appear.
    func testInFlightSearchIsNotCancelledByTheNextKeystroke() async {
        let recorder = SearchRecorder()
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(1),
            search: { query, _ in
                // Long enough that the next keystroke lands while this is still in flight.
                try await Task.sleep(for: .milliseconds(120))
                recorder.record(query)
                return [AddressSuggestion(id: query, title: query, subtitle: "")]
            }
        )

        controller.queryChanged("100 Ma", countryCode: "US")
        try? await Task.sleep(for: .milliseconds(40))
        controller.queryChanged("100 Main", countryCode: "US")

        try? await Task.sleep(for: .milliseconds(400))

        // Both searches ran to completion; neither was killed mid-flight.
        XCTAssertEqual(Set(recorder.recorded), ["100 Ma", "100 Main"])
        // The list shows the newest query's results.
        XCTAssertEqual(controller.suggestions.map(\.id), ["100 Main"])
    }

    /// An earlier search that resolves after a later one must not overwrite the newer results.
    func testStaleResponseDoesNotReplaceNewerResults() async {
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(1),
            search: { query, _ in
                // The short query answers slowly, the long one quickly, so they land out of order.
                let delay = query == "10" ? 250 : 20
                try await Task.sleep(for: .milliseconds(delay))
                return [AddressSuggestion(id: query, title: query, subtitle: "")]
            }
        )

        controller.queryChanged("10", countryCode: "US")
        try? await Task.sleep(for: .milliseconds(30))
        controller.queryChanged("100 Main Street", countryCode: "US")

        try? await Task.sleep(for: .milliseconds(500))

        XCTAssertEqual(controller.suggestions.map(\.id), ["100 Main Street"])
    }

    /// A response landing after the user picks a suggestion must not repopulate the list.
    func testLateResponseDoesNotRepopulateAfterSelection() async {
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(1),
            search: { query, _ in
                try await Task.sleep(for: .milliseconds(150))
                return [AddressSuggestion(id: query, title: query, subtitle: "")]
            },
            retrieve: { _ in FrameObjects.BillingAddress(postalCode: "78701") }
        )

        controller.queryChanged("100 Main", countryCode: "US")
        try? await Task.sleep(for: .milliseconds(30))

        _ = await controller.select(self.suggestion("picked"))
        try? await Task.sleep(for: .milliseconds(400))

        XCTAssertTrue(controller.suggestions.isEmpty)
    }

    /// The list holds at most three rows, which is what fits on a phone between the address
    /// field and the form controls below it.
    func testCapsSuggestionsToTheMaximum() async {
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(10),
            search: { _, _ in
                (1...10).map { AddressSuggestion(id: "\($0)", title: "Title \($0)", subtitle: "") }
            }
        )

        XCTAssertEqual(AddressAutocompleteController.maximumSuggestions, 3)

        controller.queryChanged("100 Main", countryCode: "US")
        try? await Task.sleep(for: .milliseconds(150))

        // The first three, in the order Mapbox ranked them.
        XCTAssertEqual(controller.suggestions.map(\.id), ["1", "2", "3"])
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

        controller.queryChanged("1", countryCode: "US")
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(recorder.recorded.isEmpty)
        XCTAssertTrue(controller.suggestions.isEmpty)
    }

    /// A query at exactly the minimum does send a request, which is what makes the list feel
    /// responsive rather than waiting for a third keystroke.
    func testQueryAtTheMinimumSendsARequest() async {
        let recorder = SearchRecorder()
        let controller = AddressAutocompleteController(
            debounceInterval: .milliseconds(10),
            search: { query, _ in
                recorder.record(query)
                return [AddressSuggestion(id: query, title: query, subtitle: "")]
            }
        )

        XCTAssertEqual(AddressAutocompleteController.minimumQueryLength, 2)

        controller.queryChanged("10", countryCode: "US")
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(recorder.recorded, ["10"])
        XCTAssertFalse(controller.suggestions.isEmpty)
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

        controller.queryChanged("1", countryCode: "US")

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
