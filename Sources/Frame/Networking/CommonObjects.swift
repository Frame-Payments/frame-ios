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

extension NetworkingError {
    /// True for connectivity-class failures the user can retry. False for server-validation
    /// errors that should stay in the form so the user can correct the input.
    public var isTransport: Bool {
        switch self {
        case .invalidURL, .decodingFailed, .unknownError: return true
        case .noData, .serverError: return false
        }
    }

    /// User-facing message for the toast surface, prefixed with "Error: " for clarity. For
    /// `.serverError`, parses the standard Frame envelope (`{"error_details":{"message":"…"},"error":"…"}`)
    /// and prefers `error_details.message`. For transport-class errors or unparseable bodies,
    /// returns [fallback] prefixed the same way.
    public func toastMessage(fallback: String = "Something went wrong. Please try again.") -> String {
        let body: String
        if case .serverError(_, let description) = self {
            body = Self.extractEnvelopeMessage(description) ?? fallback
        } else {
            body = fallback
        }
        return "Error: \(body)"
    }

    /// Pull a user-facing message from the Frame error envelope JSON. The server's `error_details`
    /// field is polymorphic — sometimes an object with a `message` key, sometimes a plain string
    /// (e.g. `"Card submitted is not a test card"` for 422 validation failures). Both shapes are
    /// handled; `error_details` is preferred over the generic `error` key (which tends to be the
    /// HTTP status name like `"Unprocessable Entity"`). Returns nil when the body isn't valid
    /// JSON or no usable field is present.
    private static func extractEnvelopeMessage(_ raw: String) -> String? {
        guard !raw.isEmpty,
              let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let details = json["error_details"] as? [String: Any],
           let message = details["message"] as? String,
           !message.isEmpty {
            return message
        }
        if let detailsString = json["error_details"] as? String, !detailsString.isEmpty {
            return detailsString
        }
        if let error = json["error"] as? String, !error.isEmpty {
            return error
        }
        return nil
    }
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
