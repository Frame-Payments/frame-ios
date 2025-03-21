//
//  PaymentObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

import Foundation

//TODO: Move Later To Other Common Objects Folder
struct FrameMetadata: Codable {
    let page: Int
    let url: String
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case page, url
        case hasMore = "has_more"
    }
}

public class FrameObjects {
    public struct PaymentMethod: Codable, Sendable, Identifiable, Equatable {
        public let id: String
        public var customer: String? // ID of the Customer
        public var billing: BillingAddress? // Billing information associated with the PaymentMethod
        public let type: String
        public let object: String
        public let created: Int // Timestamp
        public let updated: Int // Timestamp
        public let livemode: Bool
        public var card: PaymentCard?
        
        public init(id: String, customer: String? = nil, billing: BillingAddress? = nil, type: String, object: String, created: Int, updated: Int, livemode: Bool, card: PaymentCard? = nil) {
            self.id = id
            self.customer = customer
            self.billing = billing
            self.type = type
            self.object = object
            self.created = created
            self.updated = updated
            self.livemode = livemode
            self.card = card
        }
    }
    
    public struct BillingAddress: Codable, Sendable, Equatable {
        public let city: String?
        public let country: String?
        public let state: String?
        public let postalCode: String
        public let addressLine1: String?
        public let addressLine2: String?
        
        public init(city: String? = nil, country: String? = nil, state: String? = nil, postalCode: String, addressLine1: String? = nil, addressLine2: String? = nil) {
            self.city = city
            self.country = country
            self.state = state
            self.postalCode = postalCode
            self.addressLine1 = addressLine1
            self.addressLine2 = addressLine2
        }
        
        public enum CodingKeys: String, CodingKey {
            case city, country, state
            case postalCode = "postal_code"
            case addressLine1 = "line_1"
            case addressLine2 = "line_2"
        }
    }
    
    //TODO: Get real types for mark objects as optional
    public struct PaymentCard: Codable, Sendable, Equatable {
        public let brand: String
        public let expirationMonth: String
        public let expirationYear: String
        public let issuer: String?
        public let currency: String?
        public let segment: String?
        public let type: String?
        public let lastFourDigits: String
        
        public init(brand: String, expirationMonth: String, expirationYear: String, issuer: String? = nil, currency: String?, segment: String? = nil,
                    type: String? = nil, lastFourDigits: String) {
            self.brand = brand
            self.expirationMonth = expirationMonth
            self.expirationYear = expirationYear
            self.issuer = issuer
            self.currency = currency
            self.segment = segment
            self.type = type
            self.lastFourDigits = lastFourDigits
        }
        
        public enum CodingKeys: String, CodingKey {
            case brand, issuer, currency, segment, type
            case expirationMonth = "exp_month"
            case expirationYear = "exp_year"
            case lastFourDigits = "last_four"
        }
    }
}
