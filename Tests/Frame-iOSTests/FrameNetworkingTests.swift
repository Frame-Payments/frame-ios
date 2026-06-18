//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/02/24.
//

import XCTest
@testable import Frame

// Mock URLProtocol for completion handler tests
class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockResponse: URLResponse?
    static var mockError: Error?
    /// Records the most recent request so tests can inspect the headers the SDK produced
    /// (e.g. the `Authorization` Bearer token) on the completion-handler / multipart paths.
    static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool {
        lastRequest = request
        return true
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        if let response = MockURLProtocol.mockResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = MockURLProtocol.mockData {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

func makeMockURLSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

class MockURLAsyncSession: URLSessionProtocol {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    
    init(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
        self.data = data
        self.response = response
        self.error = error
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        
        guard let data = data, let response = response else {
            throw URLError(.badServerResponse)
        }
        
        return (data, response)
    }
}

struct MockFrameEndpoints: FrameNetworkingEndpoints {
    var endpointURL: String
    var httpMethod: HTTPMethod
    var queryItems: [URLQueryItem]?
}

final class FrameNetworkingTests: XCTestCase {
    // Test Async/Await Method
    func testPerformDataTaskAsync() async {
        let mockSession = MockURLAsyncSession()
        mockSession.data = "{ \"message\": \"Success\" }".data(using: .utf8)
        mockSession.response = HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/customers")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)
        mockSession.error = nil
        
        let networking = FrameNetworking.shared
        networking.asyncURLSession = mockSession
        let endpoint = MockFrameEndpoints(endpointURL: "/v1/customers", httpMethod: .GET, queryItems: nil)
        
        do {
            let (data, error) = try await networking.performDataTask(endpoint: endpoint)
            XCTAssertNotNil(data)
            XCTAssertNil(error)
        } catch {
            XCTFail("Error should not be thrown")
        }
    }
    
    func testPerformDataTaskAsyncWithNoData() async {
        let mockSession = MockURLAsyncSession()
        mockSession.data = nil
        mockSession.response = HTTPURLResponse(url: URL(string: "https://api.framepayments.com")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)
        mockSession.error = nil
        
        let networking = FrameNetworking.shared
        networking.asyncURLSession = mockSession
        let endpoint = MockFrameEndpoints(endpointURL: "/v1/customers", httpMethod: .GET, queryItems: nil)
        
        do {
            let (data, response) = try await networking.performDataTask(endpoint: endpoint)
            XCTAssertNil(data)
            XCTAssertNotNil(response)
        } catch let error {
            if let error = error as? URLError {
                XCTAssertNotNil(error)
            }
        }
    }
    
    func testPerformDataTaskAsyncWithNoResponse() async {
        let mockSession = MockURLAsyncSession()
        mockSession.data = "{ \"message\": \"Success\" }".data(using: .utf8)
        mockSession.response = nil
        mockSession.error = nil
        
        let networking = FrameNetworking.shared
        networking.asyncURLSession = mockSession
        let endpoint = MockFrameEndpoints(endpointURL: "/v1/customers", httpMethod: .GET, queryItems: nil)
        
        do {
            let (data, error) = try await networking.performDataTask(endpoint: endpoint)
            XCTAssertNil(data)
            XCTAssertNotNil(error)
            XCTAssertEqual(error, .unknownError)
        } catch {
            if let error = error as? URLError {
                XCTAssertEqual(error.code, .badURL)
            }
        }
    }

    // Test Completion Handler Method
    func testPerformDataTaskCompletion() {
        MockURLProtocol.mockData = "{ \"message\": \"Success\" }".data(using: .utf8)
        MockURLProtocol.mockResponse = HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/customers")!,
                                                       statusCode: 200,
                                                       httpVersion: nil,
                                                       headerFields: nil)
        MockURLProtocol.mockError = nil

        let networking = FrameNetworking.shared
        networking.urlSession = makeMockURLSession()
        let endpoint = MockFrameEndpoints(endpointURL: "/v1/customers", httpMethod: .GET, queryItems: nil)

        let expectation = self.expectation(description: "Completion handler called")

        networking.performDataTask(endpoint: endpoint) { data, response, error in
            XCTAssertNotNil(data)
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testPerformDataTaskCompletionWithNoData() {
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockResponse = HTTPURLResponse(url: URL(string: "https://api.framepayments.com")!,
                                                       statusCode: 200,
                                                       httpVersion: nil,
                                                       headerFields: nil)
        MockURLProtocol.mockError = nil

        let networking = FrameNetworking.shared
        networking.urlSession = makeMockURLSession()
        let endpoint = MockFrameEndpoints(endpointURL: "/v1/customers", httpMethod: .GET, queryItems: nil)

        let expectation = self.expectation(description: "Completion handler called")

        networking.performDataTask(endpoint: endpoint) { data, response, error in
            XCTAssertTrue(data?.isEmpty ?? true)
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testPerformDataTaskCompletionWithNoResponse() {
        MockURLProtocol.mockData = nil
        MockURLProtocol.mockResponse = nil
        MockURLProtocol.mockError = nil

        let networking = FrameNetworking.shared
        networking.urlSession = makeMockURLSession()
        let endpoint = MockFrameEndpoints(endpointURL: "/v1/customers", httpMethod: .GET, queryItems: nil)

        let expectation = self.expectation(description: "Completion handler called")

        networking.performDataTask(endpoint: endpoint) { data, response, error in
            XCTAssertTrue(data?.isEmpty ?? true)
            XCTAssertNil(response)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - NetworkingError.isAssertionRejection tests

final class NetworkingErrorAssertionRejectionTests: XCTestCase {

    private func make422(_ body: String) -> NetworkingError {
        .serverError(statusCode: 422, errorDescription: body)
    }

    func testAssertionSignatureFailure() {
        let error = make422(#"{"status":422,"error":"Unprocessable Entity","code":"validation_errors","error_details":"Assertion signature verification failed"}"#)
        XCTAssertTrue(error.isAssertionRejection)
    }

    func testDeviceNotAttested() {
        let error = make422(#"{"status":422,"error":"Unprocessable Entity","code":"validation_errors","error_details":"Device not attested"}"#)
        XCTAssertTrue(error.isAssertionRejection)
    }

    func testInvalidAssertionObject() {
        let error = make422(#"{"status":422,"error":"Unprocessable Entity","code":"validation_errors","error_details":"Invalid assertion object"}"#)
        XCTAssertTrue(error.isAssertionRejection)
    }

    func testUnrelatedValidationError() {
        let error = make422(#"{"status":422,"error":"Unprocessable Entity","code":"validation_errors","error_details":"Card submitted is not a test card"}"#)
        XCTAssertFalse(error.isAssertionRejection)
    }

    func testNon422ServerError() {
        let error = NetworkingError.serverError(statusCode: 500, errorDescription: #"{"error_details":"Assertion signature verification failed"}"#)
        XCTAssertFalse(error.isAssertionRejection)
    }

    func testNonServerErrors() {
        XCTAssertFalse(NetworkingError.unknownError.isAssertionRejection)
        XCTAssertFalse(NetworkingError.noData.isAssertionRejection)
        XCTAssertFalse(NetworkingError.decodingFailed.isAssertionRejection)
        XCTAssertFalse(NetworkingError.invalidURL.isAssertionRejection)
    }
}
