//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/2/26.
//

import Foundation

/// Endpoint definitions for the Sonar charge-session API resource.
///
/// Conforms to ``FrameNetworkingEndpoints`` and provides the URL paths,
/// HTTP methods, and query items used when creating or updating charge sessions.
public enum SonarSessionEndpoints: FrameNetworkingEndpoints {
    /// Creates a new charge session (`POST /v1/charge_sessions`).
    case create
    /// Updates an existing charge session by ID (`PATCH /v1/charge_sessions/{id}`).
    case update(id: String)

    /// The relative URL path for the endpoint.
    public var endpointURL: String {
        switch self {
        case .create:
            return "/v1/charge_sessions"
        case .update(let id):
            return "/v1/charge_sessions/\(id)"
        }
    }

    /// The HTTP method to use when calling the endpoint.
    public var httpMethod: HTTPMethod {
        switch self {
        case .create:
            return .POST
        case .update:
            return .PATCH
        }
    }

    /// Query items to append to the request URL; always `nil` for charge-session endpoints.
    public var queryItems: [URLQueryItem]? { nil }
}
