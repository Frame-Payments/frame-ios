import Foundation

enum PayoutSessionEndpoints: FrameNetworkingEndpoints {
    case createPayoutSession
    case getAccount(accountId: String)
    case getPaymentMethods(accountId: String)

    var endpointURL: String {
        switch self {
        case .createPayoutSession:
            return "/v1/payout_sessions"
        case .getAccount(let accountId):
            return "/v1/accounts/\(accountId)"
        case .getPaymentMethods(let accountId):
            return "/v1/accounts/\(accountId)/payment_methods"
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .createPayoutSession:
            return .POST
        case .getAccount, .getPaymentMethods:
            return .GET
        }
    }

    var queryItems: [URLQueryItem]? { nil }
}
