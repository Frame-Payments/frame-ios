//
//  Test.swift
//  Frame-iOS
//
//  Created by Frame Payments on 12/02/24.
//

import XCTest
@testable import Frame_iOS

// Mock URLSessionDataTask
class MockURLSessionDataTask: URLSessionDataTask, @unchecked Sendable {
    private let completion: () -> Void
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
    }
    
    override func resume() {
        // Simulate a network request completion
        completion()
    }
}

class MockURLSession: URLSession, @unchecked Sendable {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return MockURLSessionDataTask {
            completionHandler(self.data, self.response, self.error)
        }
    }
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
    var httpMethod: String
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
        let endpoint = MockFrameEndpoints(endpointURL: "/v1/customers", httpMethod: "GET", queryItems: nil)
        
        do {
            let (data, response) = try await networking.performDataTask(endpoint: endpoint)
            XCTAssertNotNil(data)
            XCTAssertNotNil(response)
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
        let endpoint = MockFrameEndpoints(endpointURL: "/v1/customers", httpMethod: "GET", queryItems: nil)
        
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
        let endpoint = MockFrameEndpoints(endpointURL: "/v1/customers", httpMethod: "GET", queryItems: nil)
        
        do {
            let (data, response) = try await networking.performDataTask(endpoint: endpoint)
            XCTAssertNotNil(data)
            XCTAssertNil(response)
        } catch {
            if let error = error as? URLError {
                XCTAssertEqual(error.code, .badURL)
            }
        }
    }

    // Test Completion Handler Method
    func testPerformDataTaskCompletion() {
        let mockSession = MockURLSession()
        mockSession.data = "{ \"message\": \"Success\" }".data(using: .utf8)
        mockSession.response = HTTPURLResponse(url: URL(string: "https://api.framepayments.com/v1/customers")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)
        mockSession.error = nil
        
        let networking = FrameNetworking.shared
        networking.urlSession = mockSession
        let endpoint = MockFrameEndpoints(endpointURL: "/v1/customers", httpMethod: "GET", queryItems: nil)
        
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
        let mockSession = MockURLSession()
        mockSession.data = nil
        mockSession.response = HTTPURLResponse(url: URL(string: "https://api.framepayments.com")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)
        mockSession.error = nil
        
        let networking = FrameNetworking.shared
        networking.urlSession = mockSession
        let endpoint = MockFrameEndpoints(endpointURL: "/v1/customers", httpMethod: "GET", queryItems: nil)
        
        let expectation = self.expectation(description: "Completion handler called")
        
        networking.performDataTask(endpoint: endpoint) { data, response, error in
            XCTAssertNil(data)
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPerformDataTaskCompletionWithNoResponse() {
        let mockSession = MockURLSession()
        mockSession.data = nil
        mockSession.response = nil
        mockSession.error = nil
        
        let networking = FrameNetworking.shared
        networking.urlSession = mockSession
        let endpoint = MockFrameEndpoints(endpointURL: "/v1/customers", httpMethod: "GET", queryItems: nil)
        
        let expectation = self.expectation(description: "Completion handler called")
        
        networking.performDataTask(endpoint: endpoint) { data, response, error in
            XCTAssertNil(data)
            XCTAssertNil(response)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
