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
    var apiKey: String = "" // API Key used to authenticate each request - Bearer Token
    public var debugMode: Bool = false // Print API data on task calls.
    
    var isEvervaultConfigured: Bool = false
    
    init() {
        self.configureEvervault()
    }
    
    public func initializeWithAPIKey(_ key: String) {
        self.apiKey = key
    }
    
    // Async/Await
    func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil) async throws -> (Data?, NetworkingError?) {
        guard let url = URL(string: NetworkingConstants.mainAPIURL + endpoint.endpointURL) else { return (nil, nil) }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.httpMethod
        if endpoint.httpMethod == "POST" || endpoint.httpMethod == "PATCH" {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        urlRequest.httpBody = requestBody
        if let queryItems = endpoint.queryItems {
            urlRequest.url?.append(queryItems: queryItems)
        }
        
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("iOS", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await asyncURLSession.data(for: urlRequest)
            if debugMode {
                print(response.url?.absoluteString ?? "")
                printDataForTesting(data: requestBody)
                printDataForTesting(data: data)
            }
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                return (nil, NetworkingError.serverError(statusCode: httpResponse.statusCode))
            }
            return (data, nil)
        } catch URLError.cannotFindHost {
            return (nil, NetworkingError.invalidURL)
        } catch URLError.cannotDecodeRawData {
            return (nil, NetworkingError.decodingFailed)
        } catch {
            return (nil, NetworkingError.unknownError)
        }
    }
    
    // Completion Handler
    func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil, completion: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) {
        guard let url = URL(string: NetworkingConstants.mainAPIURL + endpoint.endpointURL) else { return completion(nil, nil, nil) }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.httpMethod
        if endpoint.httpMethod == "POST" || endpoint.httpMethod == "PATCH" {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
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
    
    func configureEvervault() {
        Task {
            if let configResponse = try? await ConfigurationAPI.getEvervaultConfiguration() {
                Evervault.shared.configure(teamId: configResponse.teamId ?? "", appId: configResponse.appId ?? "")
                FrameNetworking.shared.isEvervaultConfigured = true
            } else if let data = ConfigurationAPI.retrieveFromKeychain(key: ConfigurationKeys.evervault.rawValue) {
                if let response = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetConfigurationResponse.self, from: data) {
                    Evervault.shared.configure(teamId: response.teamId ?? "", appId: response.appId ?? "")
                    FrameNetworking.shared.isEvervaultConfigured = true
                }
            }
        }
    }
    
    func printDataForTesting(data: Data?) {
        do {
            if let data, let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } catch {
            print("Error converting data to JSON: \(error.localizedDescription)")
        }
    }
}
