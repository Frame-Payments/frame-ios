//
//  PaymentObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/26/24.
//

//TODO: Move Later To Other Common Objects Folder
struct FrameMetadata: Decodable {
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
        let customer: String? // ID of the Customer
        let billing: BillingAddress? //Billing information associated with the PaymentMethod
        let type: String
        let object: String
        let created: Int // Timestamp
        let updated: Int // Timestamp
        let livemode: Bool
        let card: PaymentCard?
        
        public init(id: String, customer: String?, billing: BillingAddress?, type: String, object: String, created: Int, updated: Int, livemode: Bool, card: PaymentCard?) {
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
        let city: String?
        let country: String?
        let state: String?
        let postalCode: String?
        let addressLine1: String?
        let addressLine2: String?
        
        public init(city: String?, country: String?, state: String?, postalCode: String?, addressLine1: String?, addressLine2: String?) {
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
        let brand: String
        let expirationMonth: String
        let expirationYear: String
        let issuer: String?
        let currency: String?
        let segment: String?
        let type: String?
        let lastFourDigits: String
        
        public init(brand: String, expirationMonth: String, expirationYear: String, issuer: String?, currency: String?, segment: String?, type: String?, lastFourDigits: String) {
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
