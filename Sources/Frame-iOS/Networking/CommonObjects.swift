//
//  NetworkingConstants.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import Foundation

class NetworkingConstants {
    static let mainAPIURL: String = "https://api.framepayments.com"
}

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

public enum NetworkingError: Error, Equatable {
    case noData
    case invalidURL
    case decodingFailed
    case serverError(statusCode: Int, errorDescription: String)
    case unknownError
}

public struct FrameMetadata: Codable {
    public let page: Int
    public let url: String
    public let hasMore: Bool
    
    public enum CodingKeys: String, CodingKey {
        case page, url
        case hasMore = "has_more"
    }
}
