//
//  ChargeObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/11/24.
//

import Foundation

extension FrameObjects {
    /// Controls whether a charge intent is captured automatically or requires a separate manual capture step.
    public enum AuthorizationMode: String, Codable, Sendable {
        /// The charge is captured automatically upon authorization.
        case automatic
        /// The charge is authorized but not captured until explicitly requested.
        case manual
    }

    /// Represents the lifecycle status of a charge intent.
    public enum ChargeIntentStatus: String, Codable, Sendable {
        /// The charge intent was canceled before completion.
        case canceled
        /// The charge has been disputed by the customer.
        case disputed
        /// The charge attempt failed.
        case failed
        /// The charge intent is incomplete and requires additional action.
        case incomplete
        /// The charge intent is pending processing.
        case pending
        /// The charge has been refunded.
        case refunded
        /// The authorization was reversed before capture.
        case reversed
        /// The charge was successfully processed.
        case succeeded
    }

    /// A charge intent representing a request to collect payment from a customer.
    public struct ChargeIntent: Codable, Sendable, Identifiable, Equatable {
        /// The unique identifier for this charge intent.
        public let id: String
        /// The three-letter ISO 4217 currency code for the charge.
        public let currency: String
        /// The most recent charge attempt associated with this intent, if any.
        public let latestCharge: LatestCharge?
        /// The customer associated with this charge intent, if any.
        public let customer: FrameObjects.Customer?
        /// The account associated with this charge intent, if any.
        public let account: FrameObjects.Account?
        /// The payment method used for this charge intent, if any.
        public let paymentMethod: FrameObjects.PaymentMethod?
        /// The shipping address associated with this charge intent, if any.
        public let shipping: FrameObjects.BillingAddress?
        /// The current status of the charge intent.
        public let status: FrameObjects.ChargeIntentStatus
        /// An optional human-readable description for the charge intent.
        public let description: String?
        /// Specifies whether the charge is captured automatically or manually.
        public let authorizationMode: FrameObjects.AuthorizationMode
        /// A human-readable explanation of why the charge failed, if applicable.
        public let failureDescription: String?
        /// The object type identifier returned by the API.
        public let object: String
        /// The charge amount in the smallest currency unit (e.g., cents).
        public let amount: Int
        /// Unix timestamp (seconds) when the charge intent was created.
        public let created: Int
        /// Unix timestamp (seconds) when the charge intent was last updated, if available.
        public let updated: Int?
        /// Indicates whether the charge intent was created in live mode (`true`) or test mode (`false`).
        public let livemode: Bool

        /// Creates a new ``ChargeIntent`` with the supplied field values.
        /// - Parameters:
        ///   - id: The unique identifier for this charge intent.
        ///   - currency: The three-letter ISO 4217 currency code.
        ///   - latestCharge: The most recent charge attempt, if any.
        ///   - customer: The associated customer, if any.
        ///   - account: The associated account, if any.
        ///   - paymentMethod: The payment method used, if any.
        ///   - shipping: The shipping address for the order.
        ///   - status: The current lifecycle status of the charge intent.
        ///   - description: An optional human-readable description.
        ///   - authorizationMode: Whether the charge is captured automatically or manually.
        ///   - failureDescription: A human-readable failure reason, if applicable.
        ///   - object: The API object type identifier.
        ///   - amount: The charge amount in the smallest currency unit.
        ///   - created: Unix timestamp when the charge intent was created.
        ///   - updated: Unix timestamp when the charge intent was last updated, if available.
        ///   - livemode: `true` if created in live mode, `false` for test mode.
        public init(id: String, currency: String, latestCharge: FrameObjects.LatestCharge? = nil, customer: FrameObjects.Customer? = nil, account: FrameObjects.Account? = nil, paymentMethod: FrameObjects.PaymentMethod? = nil, shipping: FrameObjects.BillingAddress, status: FrameObjects.ChargeIntentStatus, description: String? = nil, authorizationMode: FrameObjects.AuthorizationMode, failureDescription: String? = nil, object: String, amount: Int, created: Int, updated: Int? = nil, livemode: Bool) {
            self.id = id
            self.currency = currency
            self.latestCharge = latestCharge
            self.customer = customer
            self.account = account
            self.paymentMethod = paymentMethod
            self.shipping = shipping
            self.status = status
            self.description = description
            self.authorizationMode = authorizationMode
            self.failureDescription = failureDescription
            self.object = object
            self.amount = amount
            self.created = created
            self.updated = updated
            self.livemode = livemode
        }

        /// Maps Swift property names to their JSON API key equivalents.
        public enum CodingKeys: String, CodingKey {
            case id, currency, customer, shipping, status, description, object, amount, created, livemode, updated, account
            case latestCharge = "latest_charge"
            case paymentMethod = "payment_method"
            case authorizationMode = "authorization_mode"
            case failureDescription = "failure_description"
        }
    }

    /// The most recent charge attempt linked to a ``ChargeIntent``.
    public struct LatestCharge: Codable, Sendable, Equatable {
        /// The unique identifier for this charge.
        public let id: String
        /// The three-letter ISO 4217 currency code for the charge.
        public let currency: String
        /// The amount that was captured, in the smallest currency unit.
        public let amountCaptured: Int
        /// The total amount that has been refunded, in the smallest currency unit.
        public let amountRefunded: Int
        /// Unix timestamp (seconds) when the charge was created.
        public let created: Int
        /// Unix timestamp (seconds) when the charge was last updated.
        public let updated: Int
        /// Indicates whether the charge was created in live mode (`true`) or test mode (`false`).
        public let livemode: Bool
        /// Whether the charge has been captured.
        public let captured: Bool
        /// Whether the charge is currently under a dispute.
        public let disputed: Bool
        /// The identifier of the parent charge intent.
        public let chargeIntent: String
        /// Whether the charge has been refunded.
        public let refunded: Bool
        /// A human-readable message explaining a charge failure, if applicable.
        public let failureMessage: String?
        /// An optional human-readable description for the charge.
        public let description: String?
        /// The current status of the charge.
        public let status: FrameObjects.ChargeIntentStatus?
        /// Details about the payment method used for this charge, if available.
        public let paymentMethodDetails: FrameObjects.PaymentMethod?
        /// The identifier of the customer associated with this charge, if any.
        public let customer: String?
        /// The identifier of the account associated with this charge, if any.
        public let account: String?
        /// The identifier of the payment method used, if any.
        public let paymentMethod: String?
        /// The charge amount in the smallest currency unit (e.g., cents).
        public let amount: Int

        /// Maps Swift property names to their JSON API key equivalents.
        public enum CodingKeys: String, CodingKey {
            case id, currency, created, updated, livemode, captured, disputed, refunded, description, status, customer, amount, account
            case amountCaptured = "amount_captured"
            case amountRefunded = "amount_refunded"
            case chargeIntent = "charge_intent"
            case failureMessage = "failure_message"
            case paymentMethodDetails = "payment_method_details"
            case paymentMethod = "payment_method"
        }
    }
}
