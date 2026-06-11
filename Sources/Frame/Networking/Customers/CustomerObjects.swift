//
//  CustomerObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

extension FrameObjects {

    /// Represents the lifecycle state of a customer account.
    public enum CustomerStatus: String, Codable, Sendable {
        /// The customer account is active and can transact normally.
        case active
        /// The customer account has been blocked and cannot process payments.
        case blocked
    }

    /// A Frame customer record containing identity, contact, and payment information.
    public struct Customer: Codable, Sendable, Identifiable, Equatable {
        /// Unique identifier for the customer.
        public let id: String
        /// Unix timestamp (seconds) when the customer was created.
        public let created: Int?
        /// Shipping address associated with the customer.
        public var shippingAddress: BillingAddress?
        /// Unix timestamp (seconds) when the customer was last updated.
        public let updated: Int?
        /// Indicates whether the customer exists in live mode (`true`) or test mode (`false`).
        public let livemode: Bool
        /// Full name of the customer.
        public var name: String
        /// Phone number of the customer.
        public var phone: String?
        /// Email address of the customer.
        public var email: String?
        /// Date of birth of the customer, formatted as a string (e.g. `"YYYY-MM-DD"`).
        public var dateOfBirth: String?
        /// Optional free-text description for internal notes about the customer.
        public var description: String?
        /// The API object type identifier returned by the server (typically `"customer"`).
        public let object: String?
        /// Billing address associated with the customer.
        public var billingAddress: BillingAddress?
        /// Payment methods on file for the customer.
        public var paymentMethods: [PaymentMethod]?
        /// Current status of the customer account.
        public var status: CustomerStatus?
        /// Arbitrary key-value metadata attached to the customer.
        public let metadata: [String: String]?

        /// Creates a new `Customer` instance.
        ///
        /// - Parameters:
        ///   - id: Unique identifier for the customer.
        ///   - created: Unix timestamp when the customer was created.
        ///   - shippingAddress: Shipping address for the customer.
        ///   - updated: Unix timestamp when the customer was last updated.
        ///   - livemode: Whether this customer belongs to a live-mode account.
        ///   - name: Full name of the customer.
        ///   - phone: Phone number of the customer.
        ///   - email: Email address of the customer.
        ///   - dateOfBirth: Date of birth string for the customer.
        ///   - description: Free-text description for internal notes.
        ///   - object: API object type identifier.
        ///   - billingAddress: Billing address for the customer.
        ///   - paymentMethods: Payment methods on file for the customer.
        ///   - status: Current status of the customer account.
        ///   - metadata: Arbitrary key-value metadata.
        public init(id: String, created: Int? = nil, shippingAddress: BillingAddress? = nil, updated: Int? = nil, livemode: Bool, name: String, phone: String? = nil, email: String? = nil, dateOfBirth: String? = nil, description: String? = nil, object: String? = nil, billingAddress: BillingAddress? = nil, paymentMethods: [PaymentMethod]? = nil, status: CustomerStatus? = nil, metadata: [String : String]? = nil) {
            self.id = id
            self.created = created
            self.shippingAddress = shippingAddress
            self.updated = updated
            self.livemode = livemode
            self.name = name
            self.phone = phone
            self.email = email
            self.dateOfBirth = dateOfBirth
            self.description = description
            self.object = object
            self.billingAddress = billingAddress
            self.paymentMethods = paymentMethods
            self.status = status
            self.metadata = metadata
        }
//
        public enum CodingKeys: String, CodingKey {
            case id, created, updated, livemode, name, phone, email, description, object, status, metadata
            case billingAddress = "billing_address"
            case shippingAddress = "shipping_address"
            case paymentMethods = "payment_methods"
            case dateOfBirth = "date_of_birth"
        }
    }
}
