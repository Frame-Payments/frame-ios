//
//  FrameAuth.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

// https://docs.framepayments.com/authentication

import SwiftUI
import EvervaultCore

// Create Network Request Here That Return Callbacks With User Data, This is the "Router"

// TODO: Add Pagination for Network Request

protocol FrameNetworkingEndpoints {
    var endpointURL: String { get }
    var httpMethod: String { get }
    var queryItems: [URLQueryItem]? { get }
}

// Custom protocol for URLSession
public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// Extend URLSession to conform to the protocol
extension URLSession: URLSessionProtocol {}

enum NetworkingError: Error {
    case invalidURL
    case decodingFailed
    case serverError(statusCode: Int)
    case unknownError
}

public class FrameNetworking: ObservableObject {
    nonisolated(unsafe) public static let shared = FrameNetworking()
    
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    var asyncURLSession: URLSessionProtocol = URLSession.shared
    var urlSession: URLSession = URLSession.shared
    
    let mainAPIURL: String = "https://api.framepayments.com"
    var apiKey: String = "" // API Key used to authenticate each request - Bearer Token
    
    init() {
        Evervault.shared.configure(teamId: "team_7b6ce5e75d40", appId: "app_933b505c5939")
    }
    
    public func initializeWithAPIKey(_ key: String) {
        self.apiKey = key
    }
    
    // Async/Await
    func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil) async throws -> (Data?, URLResponse?) {
        guard let url = URL(string: mainAPIURL + endpoint.endpointURL) else { return (nil, nil) }
        
        var urlRequest = URLRequest(url: url,
                                    cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
        urlRequest.httpMethod = endpoint.httpMethod
        urlRequest.httpBody = requestBody
        if let queryItems = endpoint.queryItems {
            urlRequest.url?.append(queryItems: queryItems)
        }
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("iOS", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await asyncURLSession.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                throw NetworkingError.serverError(statusCode: httpResponse.statusCode)
            }

            return (data, response)
        } catch URLError.cannotFindHost {
            throw NetworkingError.invalidURL
        } catch URLError.cannotDecodeRawData {
            throw NetworkingError.decodingFailed
        } catch {
            throw NetworkingError.unknownError
        }
    }
    
    // Completion Handler
    func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil, completion: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) {
        guard let url = URL(string: mainAPIURL + endpoint.endpointURL) else { return completion(nil, nil, nil) }
        
        var urlRequest = URLRequest(url: url,
                                    cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
        urlRequest.httpMethod = endpoint.httpMethod
        urlRequest.httpBody = requestBody
        if let queryItems = endpoint.queryItems {
            urlRequest.url?.append(queryItems: queryItems)
        }
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("iOS", forHTTPHeaderField: "User-Agent")
        
        urlSession.dataTask(with: urlRequest) { data, response, error in
            completion(data, response, error)
        }.resume()
    }
}
