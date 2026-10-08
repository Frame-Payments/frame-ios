//
//  TransferV2Objects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/29/26.
//

import Foundation

extension FrameObjects {
    /// Coarse lifecycle status on a V2 ``TransferV2``.
    ///
    /// Detail lives on nested ``TransferV2Payment/status``, ``TransferV2Payout/status``, or
    /// ``TransferV2AccountTransfer/status``. An unrecognised value decodes to ``unknown``.
    public enum TransferV2Status: String, Codable, Sendable {
        case pending
        case completed
        case failed
        case canceled
        case reversed
        case unknown

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = TransferV2Status(rawValue: raw) ?? .unknown
        }
    }

    /// Discriminator for which nested detail a V2 transfer carries.
    public enum TransferV2Type: String, Codable, Sendable {
        case payment
        case payout
        case accountTransfer = "account_transfer"
        case unknown

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = TransferV2Type(rawValue: raw) ?? .unknown
        }
    }

    /// Amount expressed as `{ value, currency }` on the V2 Transfers API.
    public struct TransferV2Money: Codable, Sendable, Equatable {
        /// Amount in the smallest currency unit (e.g. cents for USD).
        public let value: Int
        /// ISO 4217 currency code (e.g. `"usd"`).
        @Lenient public private(set) var currency: String?

        public init(value: Int, currency: String? = nil) {
            self.value = value
            self.currency = currency
        }
    }

    /// Nested payment detail on a payment-type V2 transfer.
    public struct TransferV2Payment: Codable, Sendable, Equatable {
        @Lenient public private(set) var status: String?
        @Lenient public private(set) var authorizationMode: String?
        @Lenient public private(set) var receiptEmail: String?
        @Lenient public private(set) var statementDescriptor: String?
        @Lenient public private(set) var productId: String?
        @Lenient public private(set) var paymentLinkId: String?
        @Lenient public private(set) var subscriptionId: String?
        @Lenient public private(set) var invoiceId: String?
        @Lenient public private(set) var cartData: [String: String]?
        @Lenient public private(set) var amountAuthorized: TransferV2Money?
        @Lenient public private(set) var amountCaptured: TransferV2Money?
        @Lenient public private(set) var amountRefunded: TransferV2Money?
        @Lenient public private(set) var failureCode: String?
        @Lenient public private(set) var failureReason: String?
        @Lenient public private(set) var shipping: TransferV2Shipping?

        public enum CodingKeys: String, CodingKey {
            case status, shipping
            case authorizationMode = "authorization_mode"
            case receiptEmail = "receipt_email"
            case statementDescriptor = "statement_descriptor"
            case productId = "product_id"
            case paymentLinkId = "payment_link_id"
            case subscriptionId = "subscription_id"
            case invoiceId = "invoice_id"
            case cartData = "cart_data"
            case amountAuthorized = "amount_authorized"
            case amountCaptured = "amount_captured"
            case amountRefunded = "amount_refunded"
            case failureCode = "failure_code"
            case failureReason = "failure_reason"
        }
    }

    /// Nested payout detail on a payout-type V2 transfer.
    public struct TransferV2Payout: Codable, Sendable, Equatable {
        @Lenient public private(set) var status: String?
        @Lenient public private(set) var rail: String?
        @Lenient public private(set) var speed: String?
        @Lenient public private(set) var failureCode: String?
        @Lenient public private(set) var failureReason: String?

        public enum CodingKeys: String, CodingKey {
            case status, rail, speed
            case failureCode = "failure_code"
            case failureReason = "failure_reason"
        }
    }

    /// Nested account-transfer detail on an account_transfer-type V2 transfer.
    public struct TransferV2AccountTransfer: Codable, Sendable, Equatable {
        @Lenient public private(set) var status: String?
        @Lenient public private(set) var failureCode: String?
        @Lenient public private(set) var failureReason: String?

        public enum CodingKeys: String, CodingKey {
            case status
            case failureCode = "failure_code"
            case failureReason = "failure_reason"
        }
    }

    /// Shipping block returned on a V2 payment.
    public struct TransferV2Shipping: Codable, Sendable, Equatable {
        @Lenient public private(set) var name: String?
        @Lenient public private(set) var phone: String?
        @Lenient public private(set) var carrier: String?
        @Lenient public private(set) var trackingNumber: String?
        @Lenient public private(set) var address: TransferV2Address?

        public enum CodingKeys: String, CodingKey {
            case name, phone, carrier, address
            case trackingNumber = "tracking_number"
        }
    }

    /// Address fields used on V2 shipping / billing.
    public struct TransferV2Address: Codable, Sendable, Equatable {
        @Lenient public private(set) var line1: String?
        @Lenient public private(set) var line2: String?
        @Lenient public private(set) var city: String?
        @Lenient public private(set) var state: String?
        @Lenient public private(set) var postalCode: String?
        @Lenient public private(set) var country: String?

        public init(line1: String? = nil,
                    line2: String? = nil,
                    city: String? = nil,
                    state: String? = nil,
                    postalCode: String? = nil,
                    country: String? = nil) {
            self.line1 = line1
            self.line2 = line2
            self.city = city
            self.state = state
            self.postalCode = postalCode
            self.country = country
        }

        public enum CodingKeys: String, CodingKey {
            case city, state, country
            case line1 = "line_1"
            case line2 = "line_2"
            case postalCode = "postal_code"
        }
    }

    /// A `source` or `destination` slot on a V2 transfer response.
    public struct TransferV2Endpoint: Codable, Sendable, Equatable {
        @Lenient public private(set) var paymentMethod: FrameObjects.PaymentMethod?
        @Lenient public private(set) var account: TransferV2AccountRef?
        @Lenient public private(set) var wallet: TransferV2WalletRef?

        public enum CodingKeys: String, CodingKey {
            case account, wallet
            case paymentMethod = "payment_method"
        }
    }

    /// Minimal account reference on a V2 endpoint.
    public struct TransferV2AccountRef: Codable, Sendable, Equatable, Identifiable {
        public let id: String
        @Lenient public private(set) var object: String?
        @Lenient public private(set) var name: String?
    }

    /// Minimal wallet reference on a V2 endpoint.
    public struct TransferV2WalletRef: Codable, Sendable, Equatable, Identifiable {
        public let id: String
        @Lenient public private(set) var object: String?
        @Lenient public private(set) var provider: String?
        @Lenient public private(set) var chain: String?
        @Lenient public private(set) var token: String?
    }

    /// A 3D Secure challenge session for the client to complete.
    ///
    /// The API serialises `source`, `directory_server_name`, and `challenge_url`.
    public struct UseFrameSDK: Codable, Sendable, Equatable {
        /// The opaque session identifier the challenge is driven from.
        public let source: String
        /// The card network's directory server for this challenge (e.g. `"visa"`).
        @Lenient public private(set) var directoryServerName: String?
        /// The issuer challenge page to present. Absent if the API could not build one.
        ///
        /// Decoded from a string rather than declared `URL`: `URL`'s own `Decodable` cannot be
        /// driven through `@Lenient`, which would silently yield `nil` for a valid URL.
        public var challengeURL: URL? { challengeURLString.flatMap(URL.init(string:)) }

        @Lenient private var challengeURLString: String?

        public init(source: String, directoryServerName: String? = nil, challengeURL: URL? = nil) {
            self.source = source
            self.directoryServerName = directoryServerName
            self.challengeURLString = challengeURL?.absoluteString
        }

        public enum CodingKeys: String, CodingKey {
            case source
            case directoryServerName = "directory_server_name"
            case challengeURLString = "challenge_url"
        }
    }

    /// Challenge presentation fields for client-side 3DS (when the API exposes them).
    public struct TransferV2NextAction: Codable, Sendable, Equatable {
        /// The kind of action required. Currently `"use_frame_sdk"` or a redirect.
        @Lenient public private(set) var type: String?
        /// Legacy/simple redirect URL when the API does not emit `use_frame_sdk`.
        @Lenient public private(set) var redirectUrl: String?
        /// Parameters for driving a 3D Secure challenge, when ``type`` is `"use_frame_sdk"`.
        @Lenient public private(set) var useFrameSDK: UseFrameSDK?

        public enum CodingKeys: String, CodingKey {
            case type
            case redirectUrl = "redirect_url"
            case useFrameSDK = "use_frame_sdk"
        }
    }

    /// A V2 transfer (`Core::Transfer`) returned by `/v2/transfers`.
    public struct TransferV2: Codable, Sendable, Identifiable, Equatable {
        public let id: String
        @Lenient public private(set) var object: String?
        @Lenient public private(set) var type: TransferV2Type?
        @Lenient public private(set) var status: TransferV2Status?
        @Lenient public private(set) var description: String?
        @Lenient public private(set) var amount: TransferV2Money?
        @Lenient public private(set) var fee: TransferV2Money?
        @Lenient public private(set) var netAmount: TransferV2Money?
        @Lenient public private(set) var livemode: Bool?
        @Lenient public private(set) var created: Int?
        @Lenient public private(set) var pendingAt: Int?
        @Lenient public private(set) var completedAt: Int?
        @Lenient public private(set) var failedAt: Int?
        @Lenient public private(set) var canceledAt: Int?
        @Lenient public private(set) var reversedAt: Int?
        @Lenient public private(set) var reference: String?
        @Lenient public private(set) var metadata: [String: String]?
        @Lenient public private(set) var source: TransferV2Endpoint?
        @Lenient public private(set) var destination: TransferV2Endpoint?
        @Lenient public private(set) var payment: TransferV2Payment?
        @Lenient public private(set) var payout: TransferV2Payout?
        @Lenient public private(set) var accountTransfer: TransferV2AccountTransfer?
        @Lenient public private(set) var nextAction: TransferV2NextAction?

        public init(id: String,
                    object: String? = nil,
                    type: TransferV2Type? = nil,
                    status: TransferV2Status? = nil,
                    description: String? = nil,
                    amount: TransferV2Money? = nil,
                    fee: TransferV2Money? = nil,
                    netAmount: TransferV2Money? = nil,
                    livemode: Bool? = nil,
                    created: Int? = nil,
                    pendingAt: Int? = nil,
                    completedAt: Int? = nil,
                    failedAt: Int? = nil,
                    canceledAt: Int? = nil,
                    reversedAt: Int? = nil,
                    reference: String? = nil,
                    metadata: [String: String]? = nil,
                    source: TransferV2Endpoint? = nil,
                    destination: TransferV2Endpoint? = nil,
                    payment: TransferV2Payment? = nil,
                    payout: TransferV2Payout? = nil,
                    accountTransfer: TransferV2AccountTransfer? = nil,
                    nextAction: TransferV2NextAction? = nil) {
            self.id = id
            self.object = object
            self.type = type
            self.status = status
            self.description = description
            self.amount = amount
            self.fee = fee
            self.netAmount = netAmount
            self.livemode = livemode
            self.created = created
            self.pendingAt = pendingAt
            self.completedAt = completedAt
            self.failedAt = failedAt
            self.canceledAt = canceledAt
            self.reversedAt = reversedAt
            self.reference = reference
            self.metadata = metadata
            self.source = source
            self.destination = destination
            self.payment = payment
            self.payout = payout
            self.accountTransfer = accountTransfer
            self.nextAction = nextAction
        }

        public enum CodingKeys: String, CodingKey {
            case id, object, type, status, description, amount, fee, metadata, livemode, created
            case source, destination, payment, payout, reference
            case netAmount = "net_amount"
            case pendingAt = "pending_at"
            case completedAt = "completed_at"
            case failedAt = "failed_at"
            case canceledAt = "canceled_at"
            case reversedAt = "reversed_at"
            case accountTransfer = "account_transfer"
            case nextAction = "next_action"
        }
    }
}
