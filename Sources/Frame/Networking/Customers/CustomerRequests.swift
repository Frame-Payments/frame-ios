//
//  CustomerRequest.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

/// Request body namespace for Customers API calls.
public class CustomerRequest {
    /// Request body used to create a new customer.
    public struct CreateCustomerRequest: Codable {
        /// Optional billing address for the customer.
        var billingAddress: FrameObjects.BillingAddress?
        /// Optional shipping address for the customer.
        var shippingAddress: FrameObjects.BillingAddress?
        /// Full legal name of the customer.
        let name: String
        /// Optional phone number for the customer.
        var phone: String?
        /// Email address of the customer.
        let email: String
        /// Optional Social Security Number in `XXX-XX-XXXX` or `XXXXXXXXXX` format.
        var ssn: String? // XXX-XX-XXXX or XXXXXXXXXX format
        /// Optional date of birth in `YYYY-MM-DD` format.
        var dateOfBirth: String? // YYYY-MM-DD format
        /// Optional free-text description for internal use.
        var description: String?
        /// Optional key-value metadata to associate with the customer.
        var metadata: [String: String]?

        /// Creates a new ``CreateCustomerRequest``.
        ///
        /// - Parameters:
        ///   - billingAddress: Optional billing address.
        ///   - shippingAddress: Optional shipping address.
        ///   - name: Full legal name of the customer.
        ///   - phone: Optional phone number.
        ///   - email: Email address of the customer.
        ///   - ssn: Optional SSN in `XXX-XX-XXXX` or `XXXXXXXXXX` format.
        ///   - dateOfBirth: Optional date of birth in `YYYY-MM-DD` format.
        ///   - description: Optional free-text description.
        ///   - metadata: Optional key-value metadata.
        public init(billingAddress: FrameObjects.BillingAddress? = nil, shippingAddress: FrameObjects.BillingAddress? = nil, name: String, phone: String? = nil, email: String, ssn: String? = nil, dateOfBirth: String? = nil, description: String? = nil, metadata: [String : String]? = nil) {
            self.billingAddress = billingAddress
            self.shippingAddress = shippingAddress
            self.name = name
            self.phone = phone
            self.email = email
            self.ssn = ssn
            self.dateOfBirth = dateOfBirth
            self.description = description
            self.metadata = metadata
        }

        enum CodingKeys: String, CodingKey {
            case name, phone, email, description, metadata, ssn
            case billingAddress = "billing_address"
            case shippingAddress = "shipping_address"
            case dateOfBirth = "date_of_birth"
        }
    }

    /// Request body used to update an existing customer; all fields are optional.
    public struct UpdateCustomerRequest: Codable {
        /// Replacement billing address for the customer.
        var billingAddress: FrameObjects.BillingAddress?
        /// Replacement shipping address for the customer.
        var shippingAddress: FrameObjects.BillingAddress?
        /// Updated full legal name of the customer.
        var name: String?
        /// Updated phone number for the customer.
        var phone: String?
        /// Updated email address of the customer.
        var email: String?
        /// Updated SSN in `XXX-XX-XXXX` or `XXXXXXXXXX` format.
        var ssn: String? // XXX-XX-XXXX or XXXXXXXXXX format
        /// Updated date of birth in `YYYY-MM-DD` format.
        var dateOfBirth: String? // YYYY-MM-DD format
        /// Updated free-text description for internal use.
        var description: String?
        /// Updated key-value metadata to associate with the customer.
        var metadata: [String: String]?

        /// Creates a new ``UpdateCustomerRequest``.
        ///
        /// - Parameters:
        ///   - billingAddress: Replacement billing address.
        ///   - shippingAddress: Replacement shipping address.
        ///   - name: Updated full legal name.
        ///   - phone: Updated phone number.
        ///   - email: Updated email address.
        ///   - ssn: Updated SSN in `XXX-XX-XXXX` or `XXXXXXXXXX` format.
        ///   - dateOfBirth: Updated date of birth in `YYYY-MM-DD` format.
        ///   - description: Updated free-text description.
        ///   - metadata: Updated key-value metadata.
        public init(billingAddress: FrameObjects.BillingAddress? = nil, shippingAddress: FrameObjects.BillingAddress? = nil, name: String? = nil, phone: String? = nil, email: String? = nil, ssn: String? = nil, dateOfBirth: String? = nil, description: String? = nil, metadata: [String : String]? = nil) {
            self.billingAddress = billingAddress
            self.shippingAddress = shippingAddress
            self.name = name
            self.phone = phone
            self.email = email
            self.ssn = ssn
            self.dateOfBirth = dateOfBirth
            self.description = description
            self.metadata = metadata
        }

        enum CodingKeys: String, CodingKey {
            case name, phone, email, description, metadata, ssn
            case billingAddress = "billing_address"
            case shippingAddress = "shipping_address"
            case dateOfBirth = "date_of_birth"
        }
    }

    /// Request body used to search for customers by one or more filter criteria.
    public struct SearchCustomersRequest: Codable {
        /// Filter results to customers whose name matches this value.
        var name: String?
        /// Filter results to customers with this phone number.
        var phone: String?
        /// Filter results to customers with this email address.
        var email: String?
        /// Return only customers created before this Unix timestamp.
        var createdBefore: Int?
        /// Return only customers created after this Unix timestamp.
        var createdAfter: Int?

        /// Creates a new ``SearchCustomersRequest``.
        ///
        /// - Parameters:
        ///   - name: Optional name filter.
        ///   - phone: Optional phone filter.
        ///   - email: Optional email filter.
        ///   - createdBefore: Optional upper-bound Unix timestamp filter.
        ///   - createdAfter: Optional lower-bound Unix timestamp filter.
        public init(name: String? = nil, phone: String? = nil, email: String? = nil, createdBefore: Int? = nil, createdAfter: Int? = nil) {
            self.name = name
            self.phone = phone
            self.email = email
            self.createdBefore = createdBefore
            self.createdAfter = createdAfter
        }

        enum CodingKeys: String, CodingKey {
            case name, phone, email
            case createdBefore = "created_before"
            case createdAfter = "created_after"
        }
    }
}
