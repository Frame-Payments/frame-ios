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
    ///
    /// An unrecognised value decodes to ``unknown`` rather than failing the surrounding
    /// ``ChargeIntent``, so a state added server-side cannot break a shipped app.
    public enum ChargeIntentStatus: String, Codable, Sendable {
        /// The charge intent was canceled before completion.
        case canceled
        /// The charge has been disputed by the customer.
        case disputed
        /// A dispute on the charge was resolved in the merchant's favour.
        case disputedWon = "disputed_won"
        /// A dispute on the charge was resolved in the customer's favour.
        case disputedLost = "disputed_lost"
        /// The charge intent expired before it could be completed.
        case expired
        /// The charge attempt failed.
        case failed
        /// The charge was declined by fraud screening.
        case fraudDeclined = "fraud_declined"
        /// The charge is held for manual fraud review.
        case fraudReview = "fraud_review"
        /// The charge intent is incomplete and requires additional action.
        case incomplete
        /// The charge intent is pending processing.
        case pending
        /// The charge has been refunded.
        case refunded
        /// The charge intent needs an account or customer before it can proceed.
        case requiresAccountOrCustomer = "requires_account_or_customer"
        /// The charge is authorized and awaiting a merchant-initiated capture.
        case requiresCapture = "requires_capture"
        /// The charge intent is waiting to be confirmed.
        case requiresConfirmation = "requires_confirmation"
        /// The cardholder must complete a 3D Secure challenge before the charge can proceed.
        case requiresPaymentMethod = "requires_payment_method"
        /// A 3D Secure challenge is required to authenticate the cardholder.
        case requiresThreeDSecure = "requires_3d_secure"
        /// The authorization was reversed before capture.
        case reversed
        /// The charge was successfully processed.
        case succeeded
        /// A status this version of the SDK does not recognise.
        case unknown

        /// Creates a status from its API string, mapping anything unrecognised to ``unknown``.
        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = ChargeIntentStatus(rawValue: raw) ?? .unknown
        }

        /// Whether the status will not change on its own, so polling should stop.
        ///
        /// ``requiresCapture`` counts as terminal, or authorize-only merchants appear to hang.
        public var isTerminal: Bool {
            switch self {
            case .succeeded, .requiresCapture, .failed:
                return true
            case .canceled, .disputed, .disputedWon, .disputedLost, .expired, .fraudDeclined,
                 .fraudReview, .incomplete, .pending, .refunded, .requiresAccountOrCustomer,
                 .requiresConfirmation, .requiresPaymentMethod, .requiresThreeDSecure,
                 .reversed, .unknown:
                return false
            }
        }
    }

    /// The follow-up action required before a charge intent can settle. Present only while the
    /// status is ``ChargeIntentStatus/requiresThreeDSecure``.
    public struct NextAction: Codable, Sendable, Equatable {
        /// The kind of action required. Currently only `"use_frame_sdk"`.
        public let type: String
        /// Parameters for driving a 3D Secure challenge, when ``type`` is `"use_frame_sdk"`.
        @Lenient public private(set) var useFrameSDK: UseFrameSDK?

        /// Creates a next-action descriptor.
        public init(type: String, useFrameSDK: UseFrameSDK? = nil) {
            self.type = type
            self.useFrameSDK = useFrameSDK
        }

        /// Maps Swift property names to their JSON API key equivalents.
        public enum CodingKeys: String, CodingKey {
            case type
            case useFrameSDK = "use_frame_sdk"
        }
    }

    /// A 3D Secure challenge session for the client to complete.
    ///
    /// The API serialises only these two fields — there is no server-transaction identifier,
    /// despite the browser SDK's types suggesting one.
    public struct UseFrameSDK: Codable, Sendable, Equatable {
        /// The opaque session identifier the challenge is driven from. A credential for one
        /// challenge: never log or persist it.
        public let source: String
        /// The card network's directory server for this challenge (e.g. `"visa"`).
        @Lenient public private(set) var directoryServerName: String?
        /// The issuer challenge page to present. Absent if the API could not build one.
        ///
        /// Decoded from a string rather than declared `URL`: `URL`'s own `Decodable` cannot be
        /// driven through `@Lenient`, which would silently yield `nil` for a valid URL.
        public var challengeURL: URL? { challengeURLString.flatMap(URL.init(string:)) }

        @Lenient private var challengeURLString: String?

        /// Creates a 3D Secure challenge descriptor.
        public init(source: String, directoryServerName: String? = nil, challengeURL: URL? = nil) {
            self.source = source
            self.directoryServerName = directoryServerName
            self.challengeURLString = challengeURL?.absoluteString
        }

        /// Maps Swift property names to their JSON API key equivalents.
        public enum CodingKeys: String, CodingKey {
            case source
            case directoryServerName = "directory_server_name"
            case challengeURLString = "challenge_url"
        }
    }

    /// A charge intent representing a request to collect payment from a customer.
    public struct ChargeIntent: Codable, Sendable, Identifiable, Equatable {
        /// The unique identifier for this charge intent.
        public let id: String
        /// The three-letter ISO 4217 currency code for the charge.
        public let currency: String
        /// The most recent charge attempt associated with this intent, if any.
        @Lenient public private(set) var latestCharge: LatestCharge?
        /// The customer associated with this charge intent, if any.
        @Lenient public private(set) var customer: FrameObjects.Customer?
        /// The account associated with this charge intent, if any.
        @Lenient public private(set) var account: FrameObjects.Account?
        /// The payment method used for this charge intent, if any.
        @Lenient public private(set) var paymentMethod: FrameObjects.PaymentMethod?
        /// The shipping address associated with this charge intent, if any.
        @Lenient public private(set) var shipping: FrameObjects.BillingAddress?
        /// The current status of the charge intent.
        public let status: FrameObjects.ChargeIntentStatus
        /// An optional human-readable description for the charge intent.
        @Lenient public private(set) var description: String?
        /// Specifies whether the charge is captured automatically or manually.
        public let authorizationMode: FrameObjects.AuthorizationMode
        /// A human-readable explanation of why the charge failed, if applicable.
        @Lenient public private(set) var failureDescription: String?
        /// The object type identifier returned by the API.
        public let object: String
        /// The charge amount in the smallest currency unit (e.g., cents).
        public let amount: Int
        /// Unix timestamp (seconds) when the charge intent was created.
        public let created: Int
        /// Unix timestamp (seconds) when the charge intent was last updated, if available.
        @Lenient public private(set) var updated: Int?
        /// Indicates whether the charge intent was created in live mode (`true`) or test mode (`false`).
        public let livemode: Bool
        /// The follow-up action required before this intent can settle, present only while
        /// ``status`` is ``FrameObjects/ChargeIntentStatus/requiresThreeDSecure``.
        @Lenient public private(set) var nextAction: FrameObjects.NextAction?

        /// Whether a 3D Secure challenge is pending. Both halves are required: the status alone
        /// can be set without the server having produced a challenge session.
        public var requiresThreeDSecureChallenge: Bool {
            status == .requiresThreeDSecure && nextAction?.useFrameSDK != nil
        }

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
        ///   - nextAction: The follow-up action required before the intent can settle.
        public init(id: String, currency: String, latestCharge: FrameObjects.LatestCharge? = nil, customer: FrameObjects.Customer? = nil, account: FrameObjects.Account? = nil, paymentMethod: FrameObjects.PaymentMethod? = nil, shipping: FrameObjects.BillingAddress, status: FrameObjects.ChargeIntentStatus, description: String? = nil, authorizationMode: FrameObjects.AuthorizationMode, failureDescription: String? = nil, object: String, amount: Int, created: Int, updated: Int? = nil, livemode: Bool, nextAction: FrameObjects.NextAction? = nil) {
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
            self.nextAction = nextAction
        }

        /// Maps Swift property names to their JSON API key equivalents.
        public enum CodingKeys: String, CodingKey {
            case id, currency, customer, shipping, status, description, object, amount, created, livemode, updated, account
            case nextAction = "next_action"
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
        /// A machine-readable code explaining a charge failure, if applicable (e.g. `"card_declined"`).
        @Lenient public private(set) var failureCode: String?
        /// A human-readable message explaining a charge failure, if applicable.
        @Lenient public private(set) var failureMessage: String?
        /// An optional human-readable description for the charge.
        @Lenient public private(set) var description: String?
        /// The current status of the charge.
        @Lenient public private(set) var status: FrameObjects.ChargeIntentStatus?
        /// Details about the payment method used for this charge, if available.
        @Lenient public private(set) var paymentMethodDetails: FrameObjects.PaymentMethod?
        /// The identifier of the customer associated with this charge, if any.
        @Lenient public private(set) var customer: String?
        /// The identifier of the account associated with this charge, if any.
        @Lenient public private(set) var account: String?
        /// The identifier of the payment method used, if any.
        @Lenient public private(set) var paymentMethod: String?
        /// The charge amount in the smallest currency unit (e.g., cents).
        public let amount: Int

        /// Maps Swift property names to their JSON API key equivalents.
        public enum CodingKeys: String, CodingKey {
            case id, currency, created, updated, livemode, captured, disputed, refunded, description, status, customer, amount, account
            case amountCaptured = "amount_captured"
            case amountRefunded = "amount_refunded"
            case chargeIntent = "charge_intent"
            case failureCode = "failure_code"
            case failureMessage = "failure_message"
            case paymentMethodDetails = "payment_method_details"
            case paymentMethod = "payment_method"
        }
    }
}
