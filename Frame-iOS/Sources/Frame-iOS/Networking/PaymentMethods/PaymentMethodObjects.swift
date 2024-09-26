//
//  PaymentObjects.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 9/26/24.
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

class FramePaymentObjects {
    public class PaymentMethod: Decodable {
        let id: String
        let customer: String? // ID of the Customer
        let billing: PaymentBilling? //Billing information associated with the PaymentMethod
        let type: String
        let object: String
        let created: Int // Timestamp
        let updated: Int // Timestamp
        let livemode: Bool
        let card: PaymentCard
    }
    
    class PaymentBilling: Codable {
        let city: String?
        let country: String?
        let state: String?
        let postalCode: String?
        let addressLine1: String?
        let addressLine2: String?
        
        enum CodingKeys: String, CodingKey {
            case city, country, state
            case postalCode = "postal_code"
            case addressLine1 = "line_1"
            case addressLine2 = "line_2"
        }
    }
    
    //TODO: Get real types for mark objects as optional
    class PaymentCard: Codable {
        let brand: String
        let expirationMonth: String
        let expirationYear: String
        let issuer: String?
        let currency: String?
        let segment: String?
        let type: String?
        let lastFourDigits: String
        
        init(brand: String, expirationMonth: String, expirationYear: String, issuer: String?, currency: String?, segment: String?, type: String?, lastFourDigits: String) {
            self.brand = brand
            self.expirationMonth = expirationMonth
            self.expirationYear = expirationYear
            self.issuer = issuer
            self.currency = currency
            self.segment = segment
            self.type = type
            self.lastFourDigits = lastFourDigits
        }
        
        enum CodingKeys: String, CodingKey {
            case brand, issuer, currency, segment, type
            case expirationMonth = "exp_month"
            case expirationYear = "exp_year"
            case lastFourDigits = "last_four"
        }
    }
}
