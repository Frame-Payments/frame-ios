//
//  AccountEventsEndpoints.swift
//  Frame-iOS
//

import Foundation

enum AccountEventsEndpoints: FrameNetworkingEndpoints {
    case record

    var endpointURL: String {
        switch self {
        case .record:
            return "/v1/client/account_events"
        }
    }

    var httpMethod: HTTPMethod {
        return .POST
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }
}
