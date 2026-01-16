//
//  NetworkingConstants.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import Foundation
import UIKit

class NetworkingConstants {
    static let mainAPIURL: String = "https://api.framepayments.com"
}

public enum HTTPMethod: String {
    case DELETE
    case GET
    case PATCH
    case POST
    case PUT
}

public struct FileUpload {
    public enum FieldName: String {
        case front
        case back
        case selfie
    }
    
    var data: Data {
        return image.jpegData(compressionQuality: 0.3) ?? Data()
    }
    public let image: UIImage
    public let fieldName: FieldName
    var fileName: String {
        return "\(fieldName).jpg"
    }
    let mimeType: String = "image/jpeg"
    
    public init(image: UIImage, fieldName: FieldName) {
        self.image = image
        self.fieldName = fieldName
    }
}

public protocol FrameNetworkingEndpoints {
    var endpointURL: String { get }
    var httpMethod: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
}

// Custom protocol for URLSession
public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

public enum FrameResources {
    public static var module: Bundle {
        return Bundle.module
    }
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
