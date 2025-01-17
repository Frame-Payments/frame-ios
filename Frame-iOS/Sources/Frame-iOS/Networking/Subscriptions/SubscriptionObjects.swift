//
//  SubscriptionObjects.swift
//  Frame-iOS
//
//  Created by Frame Payments on 9/27/24.
//

extension FrameObjects {
    public struct Subscription: Codable, Sendable {
        let id: String
        let description: String
        let currentPeriodStart: Int
        let currentPeriodEnd: Int
        let livemode: Bool
        let plan: SubscriptionPlan?
        let currency: String
        let status: String
        let quantity: Int
        let customer: String?
        let defaultPaymentMethod: String
        let object: String
        let created: Int
        let startDate: Int
        
        public init(id: String, description: String, currentPeriodStart: Int, currentPeriodEnd: Int, livemode: Bool, plan: SubscriptionPlan? = nil, currency: String, status: String, quantity: Int, customer: String? = nil, defaultPaymentMethod: String, object: String, created: Int, startDate: Int) {
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
        
        enum CodingKeys: String, CodingKey {
            case id, description, livemode, plan, currency, status, quantity, customer, object, created
            case currentPeriodStart = "current_period_start"
            case currentPeriodEnd = "current_period_end"
            case defaultPaymentMethod = "default_payment_method"
            case startDate = "start_date"
        }
    }
    
    public struct SubscriptionPlan: Codable, Sendable {
        let id: String
        let interval: String
        let product: String
        let amount: Int
        let currency: String
        let object: String
        let active: Bool
        let created: Int
        let livemode: Bool
        
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
