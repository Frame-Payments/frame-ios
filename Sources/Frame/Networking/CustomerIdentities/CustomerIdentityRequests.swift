//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

/// Request body namespace for Customer Identity API calls.
public class CustomerIdentityRequest {
    /// Request body for creating a new customer identity.
    public struct CreateCustomerIdentityRequest: Codable, Equatable {
        /// The customer's first name.
        public var firstName: String
        /// The customer's last name.
        public var lastName: String
        /// The customer's date of birth in `YYYY-MM-DD` format.
        public var dateOfBirth: String
        /// The customer's email address.
        public var email: String
        /// The customer's phone number.
        public var phoneNumber: String
        /// The customer's Social Security Number.
        public var ssn: String
        /// The customer's billing address.
        public var address: FrameObjects.BillingAddress

        /// Creates a new ``CreateCustomerIdentityRequest``.
        /// - Parameters:
        ///   - firstName: The customer's first name.
        ///   - lastName: The customer's last name.
        ///   - dateOfBirth: The customer's date of birth in `YYYY-MM-DD` format.
        ///   - email: The customer's email address.
        ///   - phoneNumber: The customer's phone number.
        ///   - ssn: The customer's Social Security Number.
        ///   - address: The customer's billing address.
        public init(firstName: String, lastName: String, dateOfBirth: String, email: String, phoneNumber: String, ssn: String, address: FrameObjects.BillingAddress) {
            self.firstName = firstName
            self.lastName = lastName
            self.dateOfBirth = dateOfBirth
            self.email = email
            self.phoneNumber = phoneNumber
            self.ssn = ssn
            self.address = address
        }

        /// Coding keys mapping Swift property names to their JSON counterparts.
        public enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName = "last_name"
            case dateOfBirth = "date_of_birth"
            case email
            case phoneNumber = "phone_number"
            case ssn
            case address
        }
    }

    /// Request body for creating a customer identity linked to an existing customer.
    public struct CreateIdentityWithCustomerRequest: Codable {
        let customerId: String

        /// Creates a new ``CreateIdentityWithCustomerRequest``.
        /// - Parameter customerId: The unique identifier of the existing customer to associate with the identity.
        public init(customerId: String) {
            self.customerId = customerId
        }

        /// Coding keys mapping Swift property names to their JSON counterparts.
        public enum CodingKeys: String, CodingKey {
            case customerId = "customer_id"
        }
    }
}
