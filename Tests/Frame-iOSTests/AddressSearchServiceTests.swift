//
//  AddressSearchServiceTests.swift
//  Frame-iOSTests
//

import XCTest
@testable import Frame

final class AddressSearchServiceTests: XCTestCase {
    /// Records every request and replies with a canned body per path, which
    /// `MockURLAsyncSession` cannot do — it returns one response for every call and keeps no log.
    private final class RecordingSession: URLSessionProtocol, @unchecked Sendable {
        private let lock = NSLock()
        private var requests: [URLRequest] = []

        var suggestBody = Data()
        var retrieveBody = Data()
        var statusCode = 200

        var recorded: [URLRequest] {
            lock.lock()
            defer { lock.unlock() }
            return requests
        }

        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            lock.lock()
            requests.append(request)
            lock.unlock()

            let path = request.url?.path ?? ""
            let body = path.contains("/retrieve") ? retrieveBody : suggestBody
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url), statusCode: statusCode,
                httpVersion: nil, headerFields: nil
            )
            return (body, try XCTUnwrap(response))
        }
    }

    private func queryValue(_ name: String, in request: URLRequest) -> String? {
        guard let url = request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        return components.queryItems?.first { $0.name == name }?.value
    }

    func testSuggestSendsTokenQueryAndCountry() async throws {
        let session = RecordingSession()
        session.suggestBody = Data("""
        {"suggestions": [
            {"mapbox_id": "abc", "name": "100 Main St", "place_formatted": "Austin, Texas"}
        ]}
        """.utf8)

        let service = AddressSearchService(session: session, tokenProvider: { "pk.test" })
        let suggestions = try await service.suggest(query: "100 Main", countryCode: "US")

        XCTAssertEqual(suggestions, [
            AddressSuggestion(id: "abc", title: "100 Main St", subtitle: "Austin, Texas")
        ])

        let request = try XCTUnwrap(session.recorded.first)
        XCTAssertEqual(queryValue("q", in: request), "100 Main")
        XCTAssertEqual(queryValue("access_token", in: request), "pk.test")
        XCTAssertEqual(queryValue("country", in: request), "us")
        XCTAssertEqual(queryValue("types", in: request), "address")
        XCTAssertEqual(queryValue("limit", in: request), "3")
        XCTAssertNotNil(queryValue("session_token", in: request))
    }

    func testSuggestOmitsCountryWhenNoneGiven() async throws {
        let session = RecordingSession()
        session.suggestBody = Data(#"{"suggestions": []}"#.utf8)

        let service = AddressSearchService(session: session, tokenProvider: { "pk.test" })
        _ = try await service.suggest(query: "100 Main", countryCode: nil)

        XCTAssertNil(queryValue("country", in: try XCTUnwrap(session.recorded.first)))
    }

    /// Keystrokes and the retrieve that ends them share one session token, which is how Mapbox
    /// bills a search. A token per request would bill every keystroke separately.
    func testSuggestAndRetrieveShareOneSessionToken() async throws {
        let session = RecordingSession()
        session.suggestBody = Data(#"{"suggestions": [{"mapbox_id": "abc", "name": "100 Main St"}]}"#.utf8)
        session.retrieveBody = Data("""
        {"features": [{"properties": {"address": "100 Main St", "context": {}}}]}
        """.utf8)

        let service = AddressSearchService(session: session, tokenProvider: { "pk.test" })
        let suggestions = try await service.suggest(query: "100 Main", countryCode: "US")
        _ = try await service.retrieve(suggestion: try XCTUnwrap(suggestions.first))

        XCTAssertEqual(session.recorded.count, 2)
        XCTAssertEqual(
            queryValue("session_token", in: session.recorded[0]),
            queryValue("session_token", in: session.recorded[1])
        )
    }

    /// A retrieve ends the billing session, so the next search starts a new one.
    func testSessionTokenRotatesAfterRetrieve() async throws {
        let session = RecordingSession()
        session.suggestBody = Data(#"{"suggestions": [{"mapbox_id": "abc", "name": "100 Main St"}]}"#.utf8)
        session.retrieveBody = Data(#"{"features": [{"properties": {"address": "100 Main St"}}]}"#.utf8)

        let service = AddressSearchService(session: session, tokenProvider: { "pk.test" })
        let first = try await service.suggest(query: "100 Main", countryCode: "US")
        _ = try await service.retrieve(suggestion: try XCTUnwrap(first.first))
        _ = try await service.suggest(query: "200 Oak", countryCode: "US")

        XCTAssertNotEqual(
            queryValue("session_token", in: session.recorded[0]),
            queryValue("session_token", in: session.recorded[2])
        )
    }

    func testThrowsUnavailableWhenNoTokenExists() async {
        let service = AddressSearchService(session: RecordingSession(), tokenProvider: { nil })

        do {
            _ = try await service.suggest(query: "100 Main", countryCode: "US")
            XCTFail("expected the search to fail without a token")
        } catch {
            XCTAssertEqual(error as? AddressSearchError, .unavailable)
        }
    }

    func testThrowsRequestFailedOnNonSuccessStatus() async {
        let session = RecordingSession()
        session.statusCode = 500
        session.suggestBody = Data(#"{"suggestions": []}"#.utf8)

        let service = AddressSearchService(session: session, tokenProvider: { "pk.test" })

        do {
            _ = try await service.suggest(query: "100 Main", countryCode: "US")
            XCTFail("expected a 500 to fail the search")
        } catch {
            XCTAssertEqual(error as? AddressSearchError, .requestFailed)
        }
    }

    /// The token is fetched once and reused, rather than refetched per keystroke.
    func testTokenIsFetchedOnceAndReused() async throws {
        let session = RecordingSession()
        session.suggestBody = Data(#"{"suggestions": []}"#.utf8)

        let counter = TokenCounter()
        let service = AddressSearchService(session: session, tokenProvider: {
            await counter.increment()
            return "pk.test"
        })

        _ = try await service.suggest(query: "100 Main", countryCode: "US")
        _ = try await service.suggest(query: "200 Oak", countryCode: "US")

        let count = await counter.value
        XCTAssertEqual(count, 1)
    }

    /// A rejected token is dropped so the next call refetches instead of repeating a request that
    /// cannot succeed.
    func testRejectedTokenIsRefetched() async {
        let session = RecordingSession()
        session.statusCode = 401
        session.suggestBody = Data(#"{"suggestions": []}"#.utf8)

        let counter = TokenCounter()
        let service = AddressSearchService(session: session, tokenProvider: {
            await counter.increment()
            return "pk.test"
        })

        _ = try? await service.suggest(query: "100 Main", countryCode: "US")
        _ = try? await service.suggest(query: "200 Oak", countryCode: "US")

        let count = await counter.value
        XCTAssertEqual(count, 2)
    }
}

private actor TokenCounter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}
