//
//  AccountEventsAPITests.swift
//  Frame-iOS
//

import XCTest
@testable import Frame

final class AccountEventsAPITests: XCTestCase {

    private func makeEvent(name: String = "attestation_failed") -> AccountEventsRequests.Event {
        AccountEventsRequests.Event(
            accountId: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
            name: name,
            screen: "ApplePay",
            platform: "ios",
            sdkVersion: FrameSDK.version,
            hostSDKVersion: nil,
            occurredAt: ISO8601DateFormatter().string(from: Date()),
            detail: "DCAppAttestService returned invalidKey"
        )
    }

    func testRecordDecodesSuccessfulResponse() async throws {
        let response = HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/client/account_events")!,
                                       statusCode: 202, httpVersion: nil, headerFields: nil)
        let body = #"{"recorded":1,"rejected":[]}"#.data(using: .utf8)
        let session = MockURLAsyncSession(data: body, response: response, error: nil)
        FrameNetworking.shared.asyncURLSession = session

        let (decoded, error) = await AccountEventsAPI.record([makeEvent()])
        XCTAssertNil(error)
        XCTAssertEqual(decoded?.recorded, 1)
        XCTAssertEqual(decoded?.rejected.count, 0)
    }

    func testRecordDecodesPerEventRejections() async throws {
        let response = HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/client/account_events")!,
                                       statusCode: 202, httpVersion: nil, headerFields: nil)
        let body = #"{"recorded":1,"rejected":[{"index":1,"name":"attestation_failed","error":"account not found"}]}"#.data(using: .utf8)
        let session = MockURLAsyncSession(data: body, response: response, error: nil)
        FrameNetworking.shared.asyncURLSession = session

        let (decoded, _) = await AccountEventsAPI.record([makeEvent(), makeEvent()])
        XCTAssertEqual(decoded?.recorded, 1)
        XCTAssertEqual(decoded?.rejected.first?.index, 1)
        XCTAssertEqual(decoded?.rejected.first?.error, "account not found")
    }

    func testRecordAuthenticatesWithPublishableKey() async throws {
        MockURLProtocol.mockData = #"{"recorded":1,"rejected":[]}"#.data(using: .utf8)
        MockURLProtocol.mockResponse = HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/client/account_events")!,
                                                        statusCode: 202, httpVersion: nil, headerFields: nil)
        MockURLProtocol.mockError = nil

        let networking = FrameNetworking.shared
        networking.urlSession = makeMockURLSession()

        let expectation = self.expectation(description: "request captured")
        networking.performDataTask(endpoint: AccountEventsEndpoints.record, auth: .publishable) { _, _, _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)

        let path = MockURLProtocol.lastRequest?.url?.path
        XCTAssertEqual(path, "/v1/client/account_events")
    }

    func testRecordSurfacesTransportFailure() async {
        let session = MockURLAsyncSession(data: nil, response: nil, error: URLError(.cannotFindHost))
        FrameNetworking.shared.asyncURLSession = session

        let (decoded, error) = await AccountEventsAPI.record([makeEvent()])
        XCTAssertNil(decoded)
        XCTAssertEqual(error, .invalidURL)
        XCTAssertTrue(error?.isTransport ?? false)
    }

    func testEventEncodingOmitsHostSDKVersionWhenAbsent() throws {
        let event = makeEvent()
        let data = try FrameNetworking.shared.jsonEncoder.encode(event)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(json["host_sdk_version"])
        XCTAssertEqual(json["platform"] as? String, "ios")
        XCTAssertEqual(json["sdk_version"] as? String, FrameSDK.version)
    }
}
