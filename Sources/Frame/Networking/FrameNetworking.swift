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
    
    private var apiSecretKey: String = "" // API Key used to authenticate each request - Bearer Token
    private var apiPublishableKey: String = "" // Publishable key for client-side only endpoints
    private var debugMode: Bool = false // Print API data on task calls.

    var isEvervaultConfigured: Bool = false

    // SDK-wide theme. Read by FrameThemeKey.defaultValue
    @MainActor
    public private(set) var globalTheme: FrameTheme = .default

    /// Apple Pay merchant identifier, captured at SDK init and read by every Apple Pay surface.
    public private(set) var applePayMerchantId: String?

    public func initializeWithAPIKey(_ key: String,
                                     publishableKey: String,
                                     applePayMerchantId: String? = nil,
                                     theme: FrameTheme = .default,
                                     debugMode: Bool = false) {
        self.apiSecretKey = key
        self.apiPublishableKey = publishableKey
        self.applePayMerchantId = applePayMerchantId
        self.debugMode = debugMode

        // Initializes Sift, Sonar Session, and Device Attestation when the SDK is initialized.
        Task {
            await SiftManager.initializeSift()
            await SessionManager.initializeSession()
            _ = try? await DeviceAttestationManager.shared.attestDevice()
        }

        if !isEvervaultConfigured {
            self.configureEvervault()
        }
        
        // Set global theme
        Task {
            await MainActor.run {
                globalTheme = theme
            }
        }
    }

    func currentSonarSessionId() -> String? {
        SonarSessionStorage.currentSessionId()
    }
    
    // Async/Await
    public func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil, usePublishableKey: Bool = false) async throws -> (Data?, NetworkingError?) {
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

        let authKey = usePublishableKey && !apiPublishableKey.isEmpty ? apiPublishableKey : apiSecretKey
        urlRequest.setValue("Bearer \(authKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("iOS", forHTTPHeaderField: "User-Agent")
        if let ipAddress = SiftManager.getIPAddress() {
            urlRequest.setValue(SiftManager.getIPAddress(), forHTTPHeaderField: "ip_address")
        }
        
        do {
            let (data, response) = try await asyncURLSession.data(for: urlRequest)
            if debugMode {
                print("\nAPI Endpoint: " + (response.url?.absoluteString ?? ""))
                printDataForTesting(data: requestBody)
                printDataForTesting(data: data)
            }
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                return (data, NetworkingError.serverError(statusCode: httpResponse.statusCode, errorDescription: returnErrorString(data: data)))
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
    
    public func performMultipartDataTask(endpoint: FrameNetworkingEndpoints, filesToUpload: [FileUpload]) async throws -> (Data?, NetworkingError?) {
        guard let url = URL(string: NetworkingConstants.mainAPIURL + endpoint.endpointURL) else { return (nil, nil) }
        
        let multipart = MultipartFormDataBuilder()
        
        filesToUpload.forEach { file in
            multipart.addFile(
                fieldName: file.fieldName.rawValue,
                fileName: file.fileName,
                mimeType: file.mimeType,
                fileData: file.data
            )
        }
        
        let body = multipart.build()
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.httpMethod.rawValue
        
        if let queryItems = endpoint.queryItems {
            urlRequest.url?.append(queryItems: queryItems)
        }
        
        urlRequest.httpBody = body
        urlRequest.setValue(multipart.contentTypeHeader, forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        urlRequest.setValue("Bearer \(apiSecretKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("iOS", forHTTPHeaderField: "User-Agent")
        if let ipAddress = SiftManager.getIPAddress() {
            urlRequest.setValue(SiftManager.getIPAddress(), forHTTPHeaderField: "ip_address")
        }
        
        do {
            let (data, response) = try await asyncURLSession.data(for: urlRequest)
            if debugMode {
                print("\nAPI Endpoint: " + (response.url?.absoluteString ?? ""))
                printDataForTesting(data: body)
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
    public func performDataTask(endpoint: FrameNetworkingEndpoints, requestBody: Data? = nil, usePublishableKey: Bool = false, completion: @escaping @Sendable (Data?, URLResponse?, NetworkingError?) -> Void) {
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
        
        let authKey = usePublishableKey && !apiPublishableKey.isEmpty ? apiPublishableKey : apiSecretKey
        urlRequest.setValue("Bearer \(authKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("iOS", forHTTPHeaderField: "User-Agent")
        
        if let ipAddress = SiftManager.getIPAddress() {
            urlRequest.setValue(SiftManager.getIPAddress(), forHTTPHeaderField: "ip_address")
        }
        
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
    
    public func performMultipartDataTask(endpoint: FrameNetworkingEndpoints, filesToUpload: [FileUpload], completion: @escaping @Sendable (Data?, URLResponse?, NetworkingError?) -> Void) {
        guard let url = URL(string: NetworkingConstants.mainAPIURL + endpoint.endpointURL) else { return completion(nil, nil, nil) }
        
        let multipart = MultipartFormDataBuilder()
        
        filesToUpload.forEach { file in
            multipart.addFile(
                fieldName: file.fieldName.rawValue,
                fileName: file.fileName,
                mimeType: file.mimeType,
                fileData: file.data
            )
        }
        
        let body = multipart.build()
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.httpMethod.rawValue
        
        if let queryItems = endpoint.queryItems {
            urlRequest.url?.append(queryItems: queryItems)
        }
        
        urlRequest.httpBody = body
        urlRequest.setValue(multipart.contentTypeHeader, forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        urlRequest.setValue("Bearer \(apiSecretKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("iOS", forHTTPHeaderField: "User-Agent")
        
        if let ipAddress = SiftManager.getIPAddress() {
            urlRequest.setValue(SiftManager.getIPAddress(), forHTTPHeaderField: "ip_address")
        }
        
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

final class MultipartFormDataBuilder {

    private let boundary: String
    private var body = Data()

    init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }

    var contentTypeHeader: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    func addFile(
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) {
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
    }

    func build() -> Data {
        var finalBody = body
        finalBody.append("--\(boundary)--\r\n")
        return finalBody
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

