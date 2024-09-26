//
//  FrameAuth.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 9/26/24.
//

// https://docs.framepayments.com/authentication

import SwiftUI

// Create Network Request Here That Return Callbacks With User Data, This is the "Router"

// TODO: Add Pagination for Network Request

protocol FrameNetworkingEndpoints {
    var endpointURL: String { get }
    var httpMethod: String { get }
}

public class FrameNetworking: ObservableObject {
    nonisolated(unsafe) public static let shared = FrameNetworking()
    
    var apiKey: String = "" // API Key used to authenticate each request - Bearer Token
    
    public func initializeWithAPIKey(_ key: String) {
        self.apiKey = key
    }
    
    // Async/Await
    func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil) async throws -> (Data?, URLResponse?) {
        guard let url = URL(string: endpoint.endpointURL) else { return (nil, nil) }
        
        var urlRequest = URLRequest(url: url,
                                    cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
        urlRequest.httpMethod = endpoint.httpMethod
        urlRequest.httpBody = requestBody
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
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
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            completion(data, response, error)
        }.resume()
    }
}
