//
//  NetworkingConstants.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import Foundation
import UIKit

/// Internal constants used to configure networking behaviour across the SDK.
class NetworkingConstants {
    /// The base URL for the Frame Payments REST API.
    static let mainAPIURL: String = "https://api.framepayments.com"
}

/// The HTTP method to use when making a network request.
public enum HTTPMethod: String {
    /// Removes the specified resource.
    case DELETE
    /// Retrieves data from the specified resource.
    case GET
    /// Applies partial modifications to a resource.
    case PATCH
    /// Submits data to be processed by the specified resource.
    case POST
    /// Replaces all current representations of the target resource.
    case PUT
}

/// A container for an image file to be uploaded to the Frame API.
public struct FileUpload {
    /// Identifies which document side or type the image represents.
    public enum FieldName: String {
        /// The front side of an identity document.
        case front
        /// The back side of an identity document.
        case back
        /// A selfie photo used for identity verification.
        case selfie
    }

    /// The JPEG-encoded bytes of ``image``, compressed at 30% quality for upload efficiency.
    var data: Data {
        return image.jpegData(compressionQuality: 0.3) ?? Data()
    }

    /// The image to be uploaded.
    public let image: UIImage

    /// The document field this image is associated with.
    public let fieldName: FieldName

    /// The file name used in the multipart form upload, derived from ``fieldName``.
    var fileName: String {
        return "\(fieldName).jpg"
    }
    /// The MIME type declared in the multipart form upload body.
    let mimeType: String = "image/jpeg"

    /// Creates a new ``FileUpload`` with the given image and field name.
    /// - Parameters:
    ///   - image: The ``UIImage`` to upload.
    ///   - fieldName: The ``FieldName`` indicating which document side or type this image represents.
    public init(image: UIImage, fieldName: FieldName) {
        self.image = image
        self.fieldName = fieldName
    }
}

/// Defines the interface for Frame API endpoint descriptors.
///
/// Conform to this protocol to describe a specific API endpoint, including its
/// URL path, HTTP method, and optional query parameters.
public protocol FrameNetworkingEndpoints {
    /// The full or relative URL string for this endpoint.
    var endpointURL: String { get }

    /// The HTTP method used when calling this endpoint.
    var httpMethod: HTTPMethod { get }

    /// Optional query parameters to append to the request URL.
    var queryItems: [URLQueryItem]? { get }
}

/// An abstraction over `URLSession` used to enable testing of network calls.
///
/// The SDK uses this protocol internally so that unit tests can inject a mock
/// session without requiring live network access.
public protocol URLSessionProtocol {
    /// Performs an asynchronous data request.
    ///
    /// - Parameter request: The URL request to perform.
    /// - Returns: A tuple containing the raw response ``Data`` and the ``URLResponse``.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Provides access to the SDK's resource bundle across both Swift Package Manager and CocoaPods distributions.
public enum FrameResources {
    #if SWIFT_PACKAGE
    /// The bundle containing SDK resources such as localizations and assets.
    public static var module: Bundle {
        return Bundle.module
    }
    #else
    private final class BundleAnchor {}
    /// The bundle containing SDK resources such as localizations and assets.
    public static let module: Bundle = {
        let anchor = Bundle(for: BundleAnchor.self)
        if let url = anchor.url(forResource: "Frame", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return anchor
    }()
    #endif
}

// Extend URLSession to conform to the protocol
extension URLSession: URLSessionProtocol {}

/// Errors that can be returned by Frame SDK networking operations.
public enum NetworkingError: Error, Equatable {
    /// The server returned a response with no body.
    case noData
    /// The constructed URL was malformed or could not be created.
    case invalidURL
    /// The response body could not be decoded into the expected model type.
    case decodingFailed
    /// The server returned an HTTP error status code along with a description.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code returned by the server.
    ///   - errorDescription: A human-readable description from the server response body.
    case serverError(statusCode: Int, errorDescription: String)
    /// An unexpected error occurred that does not fit the other cases.
    case unknownError
}

extension NetworkingError {
    /// True when the server rejected a device assertion (422 with an assertion-related message).
    /// Signals that the stored attestation key is stale and should be reset before retrying.
    public var isAssertionRejection: Bool {
        guard case .serverError(let statusCode, let description) = self, statusCode == 422 else {
            return false
        }
        let message = (NetworkingError.extractEnvelopeMessage(description) ?? description).lowercased()
        return message.contains("assertion") || message.contains("device not attested") || message.contains("attestation")
    }

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

    /// Extracts a user-facing message from the Frame error envelope JSON.
    ///
    /// The server's `error_details` field is polymorphic — sometimes an object with a `message`
    /// key, sometimes a plain string (e.g. `"Card submitted is not a test card"` for 422
    /// validation failures). Both shapes are handled; `error_details` is preferred over the
    /// generic `error` key (which tends to be the HTTP status name like `"Unprocessable Entity"`).
    ///
    /// - Parameter raw: The raw string body from the server error response.
    /// - Returns: A user-facing message string, or `nil` when the body is not valid JSON or
    ///   contains no usable field.
    static func extractEnvelopeMessage(_ raw: String) -> String? {
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

/// Pagination metadata returned alongside list responses from the Frame API.
public struct FrameMetadata: Codable {
    /// The current page number in the paginated result set.
    public let page: Int

    /// The URL of the current page request.
    public let url: String

    /// Indicates whether additional pages of results are available.
    public let hasMore: Bool

    /// Maps Swift property names to the snake_case keys used in the Frame API JSON response.
    public enum CodingKeys: String, CodingKey {
        case page, url
        /// Maps to the `has_more` JSON key.
        case hasMore = "has_more"
    }
}
