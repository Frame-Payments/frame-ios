import Foundation

enum CheckoutSessionEndpoints: FrameNetworkingEndpoints {
    case createCheckoutSession
    case getAccount(accountId: String)
    case getPaymentMethods(accountId: String)

    var endpointURL: String {
        switch self {
        case .createCheckoutSession:
            return "/v1/checkout_sessions"
        case .getAccount(let accountId):
            return "/v1/accounts/\(accountId)"
        case .getPaymentMethods(let accountId):
            return "/v1/accounts/\(accountId)/payment_methods"
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .createCheckoutSession:
            return .POST
        case .getAccount, .getPaymentMethods:
            return .GET
        }
    }

    var queryItems: [URLQueryItem]? { nil }
}
