//
//  CustomerResponses.swift
//  Frame-iOS
//
//  Created by Frame Payments on 10/5/24.
//

import Foundation

/// Response model namespace for Customers API calls.
public class CustomerResponses {
    /// Paginated response returned when listing customers.
    public struct ListCustomersResponse: Codable {
        /// Pagination and request metadata associated with the response.
        public let meta: FrameMetadata?
        /// The array of customer objects returned by the request.
        public let data: [FrameObjects.Customer]?
    }

    /// Response returned after successfully deleting a customer.
    public struct DeleteCustomerResponse: Codable {
        /// The unique identifier of the deleted customer.
        public let id: String
        /// The object type, typically `"customer"`.
        public let object: String
        /// Indicates whether the customer was successfully deleted.
        public let deleted: Bool
    }
}
