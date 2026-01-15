//
//  SubscriptionObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/27/24.
//

extension FrameObjects {
    public struct Subscription: Codable, Sendable, Identifiable, Equatable {
        public let id: String
        public let description: String?
        public let currentPeriodStart: Int?
        public let currentPeriodEnd: Int?
        public let livemode: Bool
        public let plan: SubscriptionPlan?
        public let currency: String?
        public let status: String?
        public let quantity: Int
        public let customer: String?
        public let defaultPaymentMethod: String?
        public let object: String?
        public let created: Int
        public let startDate: Int?
        
        public init(id: String, description: String? = nil, currentPeriodStart: Int? = nil, currentPeriodEnd: Int? = nil, livemode: Bool, plan: SubscriptionPlan? = nil, currency: String? = nil, status: String? = nil, quantity: Int, customer: String? = nil, defaultPaymentMethod: String? = nil, object: String? = nil, created: Int, startDate: Int? = nil) {
            self.id = id
            self.description = description
            self.currentPeriodStart = currentPeriodStart
            self.currentPeriodEnd = currentPeriodEnd
            self.livemode = livemode
            self.plan = plan
            self.currency = currency
            self.status = status
            self.quantity = quantity
            self.customer = customer
            self.defaultPaymentMethod = defaultPaymentMethod
            self.object = object
            self.created = created
            self.startDate = startDate
        }
        
        public enum CodingKeys: String, CodingKey {
            case id, description, livemode, plan, currency, status, quantity, customer, object, created
            case currentPeriodStart = "current_period_start"
            case currentPeriodEnd = "current_period_end"
            case defaultPaymentMethod = "default_payment_method"
            case startDate = "start_date"
        }
    }
    
    public struct SubscriptionPlan: Codable, Sendable, Identifiable, Equatable{
        public let id: String
        public let interval: String?
        public let product: String?
        public let amount: Int
        public let currency: String?
        public let object: String?
        public let active: Bool
        public let created: Int
        public let livemode: Bool
        
        public init(id: String, interval: String, product: String, amount: Int, currency: String, object: String, active: Bool, created: Int, livemode: Bool) {
            self.id = id
            self.interval = interval
            self.product = product
            self.amount = amount
            self.currency = currency
            self.object = object
            self.active = active
            self.created = created
            self.livemode = livemode
        }
    }
}
