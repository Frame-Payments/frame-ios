//
//  FrameAuth.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

// https://docs.framepayments.com/authentication

import SwiftUI
import EvervaultCore
import Sift

// Create Network Request Here That Return Callbacks With User Data, This is the "Router"

// TODO: Add Pagination for Network Request

public class FrameNetworking: ObservableObject {
    nonisolated(unsafe) public static let shared = FrameNetworking()
    
    public let jsonEncoder = JSONEncoder()
    public let jsonDecoder = JSONDecoder()
    
    var asyncURLSession: URLSessionProtocol = URLSession.shared
    var urlSession: URLSession = URLSession.shared
    
    private var apiKey: String = "" // API Key used to authenticate each request - Bearer Token
    private var debugMode: Bool = false // Print API data on task calls.
    
    var isEvervaultConfigured: Bool = false
    
    init() {
        self.configureEvervault()
    }
    
    public func initializeWithAPIKey(_ key: String, debugMode: Bool = false) {
        self.apiKey = key
        self.debugMode = debugMode
        
        // Initializes Sift when the SDK is initialized.
        Task {
            await SiftManager.initializeSift()
        }
    }
    
    // Async/Await
    public func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil) async throws -> (Data?, NetworkingError?) {
        guard let url = URL(string: NetworkingConstants.mainAPIURL + endpoint.endpointURL) else { return (nil, nil) }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.httpMethod.rawValue
        if endpoint.httpMethod == .POST || endpoint.httpMethod == .PATCH {
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
                print("API Endpoint: " + (response.url?.absoluteString ?? ""))
                printDataForTesting(data: requestBody)
                printDataForTesting(data: data)
            }
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                return (nil, NetworkingError.serverError(statusCode: httpResponse.statusCode, errorDescription: returnErrorString(data: data)))
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
    public func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil, completion: @escaping @Sendable (Data?, URLResponse?, NetworkingError?) -> Void) {
        guard let url = URL(string: NetworkingConstants.mainAPIURL + endpoint.endpointURL) else { return completion(nil, nil, nil) }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.httpMethod.rawValue
        if endpoint.httpMethod == .POST || endpoint.httpMethod == .PATCH {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        urlRequest.httpBody = requestBody
        if let queryItems = endpoint.queryItems {
            urlRequest.url?.append(queryItems: queryItems)
        }
        
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("iOS", forHTTPHeaderField: "User-Agent")
        
        urlSession.dataTask(with: urlRequest) { data, response, error in
            var networkingError: NetworkingError?
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                networkingError = NetworkingError.serverError(statusCode: httpResponse.statusCode, errorDescription: error?.localizedDescription ?? "")
            } else if data == nil {
                networkingError = NetworkingError.noData
            } else if let urlError = error as? URLError {
                switch urlError {
                case URLError.cannotFindHost:
                    networkingError = NetworkingError.invalidURL
                case URLError.cannotDecodeRawData:
                    networkingError = NetworkingError.decodingFailed
                default:
                    networkingError = NetworkingError.unknownError
                }
            }
            
            completion(data, response, networkingError)
        }.resume()
    }
    
    func configureEvervault() {
        Task {
            if let configResponse = try? await ConfigurationAPI.getEvervaultConfiguration() {
                Evervault.shared.configure(teamId: configResponse.teamId ?? "", appId: configResponse.appId ?? "")
                FrameNetworking.shared.isEvervaultConfigured = true
            } else if let data = ConfigurationAPI.retrieveFromKeychain(key: ConfigurationKeys.evervault.rawValue) {
                if let response = try? FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetEvervaultConfigurationResponse.self, from: data) {
                    Evervault.shared.configure(teamId: response.teamId ?? "", appId: response.appId ?? "")
                    FrameNetworking.shared.isEvervaultConfigured = true
                }
            }
        }
    }
    
    private func printDataForTesting(data: Data?) {
        print(returnErrorString(data: data))
    }
    
    private func returnErrorString(data: Data?) -> String {
        if let data, let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        
        return ""
    }
}
