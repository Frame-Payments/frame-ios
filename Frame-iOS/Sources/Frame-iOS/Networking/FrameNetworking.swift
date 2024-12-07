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

public class FrameNetworking: ObservableObject {
    nonisolated(unsafe) public static let shared = FrameNetworking()
    
    var apiKey: String = "" // API Key used to authenticate each request - Bearer Token
    
    public func initializeWithAPIKey(_ key: String) {
        self.apiKey = key
        Evervault.shared.configure(teamId: "team_7b6ce5e75d40", appId: "app_933b505c5939")
    }
    
    // Async/Await
    func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil) async throws -> (Data?, URLResponse?) {
        guard let url = URL(string: endpoint.endpointURL) else { return (nil, nil) }
        
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
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        return (data, response)
    }
    
    // Completion Handler
    func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil, completion: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) {
        guard let url = URL(string: endpoint.endpointURL) else { return completion(nil, nil, nil) }
        
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
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            completion(data, response, error)
        }.resume()
    }
}
