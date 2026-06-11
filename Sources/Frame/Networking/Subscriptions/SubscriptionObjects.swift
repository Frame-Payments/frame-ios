//
//  SubscriptionObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/27/24.
//

extension FrameObjects {
    /// A recurring billing subscription associated with a customer in the Frame platform.
    public struct Subscription: Codable, Sendable, Identifiable, Equatable {
        /// Unique identifier for the subscription.
        public let id: String
        /// An optional human-readable description of the subscription.
        public let description: String?
        /// Unix timestamp (seconds) marking the start of the current billing period.
        public let currentPeriodStart: Int?
        /// Unix timestamp (seconds) marking the end of the current billing period.
        public let currentPeriodEnd: Int?
        /// Whether the subscription exists in live mode (`true`) or test mode (`false`).
        public let livemode: Bool
        /// The plan that governs the subscription's billing interval and amount.
        public let plan: SubscriptionPlan?
        /// Three-letter ISO 4217 currency code for the subscription charges.
        public let currency: String?
        /// Current status of the subscription (e.g., `"active"`, `"canceled"`, `"past_due"`).
        public let status: String?
        /// Number of units of the plan included in this subscription.
        public let quantity: Int
        /// Identifier of the customer who owns the subscription.
        public let customer: String?
        /// Identifier of the default payment method used for recurring charges.
        public let defaultPaymentMethod: String?
        /// The Frame object type string, typically `"subscription"`.
        public let object: String?
        /// Unix timestamp (seconds) when the subscription was created.
        public let created: Int
        /// Unix timestamp (seconds) when the subscription started billing.
        public let startDate: Int?

        /// Creates a new `Subscription` instance.
        ///
        /// - Parameters:
        ///   - id: Unique identifier for the subscription.
        ///   - description: Optional human-readable description.
        ///   - currentPeriodStart: Unix timestamp for the start of the current billing period.
        ///   - currentPeriodEnd: Unix timestamp for the end of the current billing period.
        ///   - livemode: `true` if the subscription is in live mode; `false` for test mode.
        ///   - plan: The plan associated with this subscription.
        ///   - currency: Three-letter ISO 4217 currency code.
        ///   - status: Current lifecycle status of the subscription.
        ///   - quantity: Number of plan units in the subscription.
        ///   - customer: Identifier of the owning customer.
        ///   - defaultPaymentMethod: Identifier of the default payment method.
        ///   - object: Frame object type string.
        ///   - created: Unix timestamp when the subscription was created.
        ///   - startDate: Unix timestamp when billing started.
        public init(id: String, description: String? = nil, currentPeriodStart: Int? = nil, currentPeriodEnd: Int? = nil, livemode: Bool, plan: SubscriptionPlan? = nil, currency: String? = nil, status: String? = nil, quantity: Int, customer: String? = nil, defaultPaymentMethod: String? = nil, object: String? = nil, created: Int, startDate: Int? = nil) {
            self.id = id
            self.description = description
            self.currentPeriodStart = currentPeriodStart
            self.currentPeriodEnd = currentPeriodEnd
            self.livemode = livemode
            self.plan = plan
            self.currency = currency
            self.status = status
            self.quantity = quantity
            self.customer = customer
            self.defaultPaymentMethod = defaultPaymentMethod
            self.object = object
            self.created = created
            self.startDate = startDate
        }

        /// Maps Swift property names to their snake_case JSON keys returned by the Frame API.
        public enum CodingKeys: String, CodingKey {
            case id, description, livemode, plan, currency, status, quantity, customer, object, created
            case currentPeriodStart = "current_period_start"
            case currentPeriodEnd = "current_period_end"
            case defaultPaymentMethod = "default_payment_method"
            case startDate = "start_date"
        }
    }

    /// The billing plan attached to a subscription, describing the price and recurrence interval.
    public struct SubscriptionPlan: Codable, Sendable, Identifiable, Equatable {
        /// Unique identifier for the plan.
        public let id: String
        /// Billing interval for the plan (e.g., `"month"`, `"year"`).
        public let interval: String?
        /// Identifier of the product this plan belongs to.
        public let product: String?
        /// Charge amount per billing cycle, in the smallest currency unit (e.g., cents).
        public let amount: Int
        /// Three-letter ISO 4217 currency code for the plan's charges.
        public let currency: String?
        /// The Frame object type string, typically `"plan"`.
        public let object: String?
        /// Whether the plan is currently available for new subscriptions.
        public let active: Bool
        /// Unix timestamp (seconds) when the plan was created.
        public let created: Int
        /// Whether the plan exists in live mode (`true`) or test mode (`false`).
        public let livemode: Bool

        /// Creates a new `SubscriptionPlan` instance.
        ///
        /// - Parameters:
        ///   - id: Unique identifier for the plan.
        ///   - interval: Billing interval string (e.g., `"month"`, `"year"`).
        ///   - product: Identifier of the associated product.
        ///   - amount: Charge amount in the smallest currency unit.
        ///   - currency: Three-letter ISO 4217 currency code.
        ///   - object: Frame object type string.
        ///   - active: `true` if the plan is available for new subscriptions.
        ///   - created: Unix timestamp when the plan was created.
        ///   - livemode: `true` for live mode; `false` for test mode.
        public init(id: String, interval: String, product: String, amount: Int, currency: String, object: String, active: Bool, created: Int, livemode: Bool) {
            self.id = id
            self.interval = interval
            self.product = product
            self.amount = amount
            self.currency = currency
            self.object = object
            self.active = active
            self.created = created
            self.livemode = livemode
        }
    }
}
