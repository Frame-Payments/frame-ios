//
//  SubscriptionRequests.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/27/24.
//

/// Request body namespace for Subscription API calls.
public class SubscriptionRequest {
    /// Request body for creating a new subscription.
    public struct CreateSubscriptionRequest: Codable {
        /// The ID of the customer to subscribe.
        let customer: String
        /// The ID of the product the customer is subscribing to.
        let product: String
        /// The three-letter ISO currency code for billing.
        let currency: String
        /// The ID of the payment method to use as the default for this subscription.
        let defaultPaymentMethod: String
        /// An optional human-readable description for the subscription.
        let description: String?

        /// Creates a new ``CreateSubscriptionRequest``.
        /// - Parameters:
        ///   - customer: The ID of the customer to subscribe.
        ///   - product: The ID of the product the customer is subscribing to.
        ///   - currency: The three-letter ISO currency code for billing.
        ///   - defaultPaymentMethod: The ID of the payment method to use as the default.
        ///   - description: An optional human-readable description for the subscription.
        public init(customer: String, product: String, currency: String, defaultPaymentMethod: String, description: String? = nil) {
            self.customer = customer
            self.product = product
            self.currency = currency
            self.defaultPaymentMethod = defaultPaymentMethod
            self.description = description
        }

        enum CodingKeys: String, CodingKey {
            case customer
            case product
            case currency
            case defaultPaymentMethod = "default_payment_method"
            case description
        }
    }

    /// Request body for updating an existing subscription.
    public struct UpdateSubscriptionRequest: Codable {
        /// An updated human-readable description for the subscription.
        let description: String?
        /// The ID of the new default payment method for the subscription.
        let defaultPaymentMethod: String?

        /// Creates a new ``UpdateSubscriptionRequest``.
        /// - Parameters:
        ///   - description: An updated human-readable description for the subscription.
        ///   - defaultPaymentMethod: The ID of the new default payment method.
        public init(description: String? = nil, defaultPaymentMethod: String? = nil) {
            self.description = description
            self.defaultPaymentMethod = defaultPaymentMethod
        }

        enum CodingKeys: String, CodingKey {
            case description
            case defaultPaymentMethod = "default_payment_method"
        }
    }

    /// Request body for searching/filtering subscriptions.
    public struct SearchSubscriptionRequest: Codable {
        /// Filters results to subscriptions with the given status.
        let status: String?
        /// Filters results to subscriptions created before this Unix timestamp.
        let createdBefore: Int?
        /// Filters results to subscriptions created after this Unix timestamp.
        let createdAfter: Int?

        /// Creates a new ``SearchSubscriptionRequest``.
        /// - Parameters:
        ///   - status: Filters results to subscriptions with the given status.
        ///   - createdBefore: Filters results to subscriptions created before this Unix timestamp.
        ///   - createdAfter: Filters results to subscriptions created after this Unix timestamp.
        public init(status: String? = nil, createdBefore: Int? = nil, createdAfter: Int? = nil) {
            self.status = status
            self.createdBefore = createdBefore
            self.createdAfter = createdAfter
        }

        enum CodingKeys: String, CodingKey {
            case status
            case createdBefore = "created_before"
            case createdAfter = "created_after"
        }
    }
}
