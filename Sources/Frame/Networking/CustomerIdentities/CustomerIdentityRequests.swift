//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 8/12/25.
//

import Foundation

public class CustomerIdentityRequest {
    public struct CreateCustomerIdentityRequest: Codable {
        let firstName: String
        let lastName: String
        let dateOfBirth: String
        let email: String
        let phoneNumber: String
        let ssn: String
        let address: FrameObjects.BillingAddress
        
        public init(firstName: String, lastName: String, dateOfBirth: String, email: String, phoneNumber: String, ssn: String, address: FrameObjects.BillingAddress) {
            self.firstName = firstName
            self.lastName = lastName
            self.dateOfBirth = dateOfBirth
            self.email = email
            self.phoneNumber = phoneNumber
            self.ssn = ssn
            self.address = address
        }
        
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
    
    public struct CreateIdentityWithCustomerRequest: Codable {
        let customerId: String
        
        public init(customerId: String) {
            self.customerId = customerId
        }
        
        public enum CodingKeys: String, CodingKey {
            case customerId = "customer_id"
        }
    }
}
