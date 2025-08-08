//
//  File.swift
//  Frame-iOS
//
//  Created by Frame Payments on 11/8/24.
//

import Foundation
import EvervaultInputs

@MainActor
class FrameCheckoutViewModel: ObservableObject {
    @Published var customerPaymentOptions: [FrameObjects.PaymentMethod]?
    @Published var customerName: String = ""
    @Published var customerEmail: String = ""
    @Published var customerAddressLine1: String = ""
    @Published var customerAddressLine2: String = ""
    @Published var customerCity: String = ""
    @Published var customerState: String = ""
    @Published var customerCountry: AvailableCountries = .US
    @Published var customerZipCode: String = ""
    
    @Published var selectedCustomerPaymentOption: FrameObjects.PaymentMethod?
    @Published var cardData = PaymentCardData()
    
    var customerId: String?
    var amount: Int = 0
    
    func loadCustomerPaymentMethods(customerId: String?, amount: Int) async {
        self.amount = amount
        
        guard let customerId else { return }
        self.customerId = customerId
        
        let customer = try? await CustomersAPI.getCustomerWith(customerId: customerId)
        self.customerPaymentOptions = customer?.paymentMethods
        self.customerName = customer?.name ?? ""
        self.customerEmail = customer?.email ?? ""
    }
    
    //TODO: Integrate for Apple Pay and Google Pay
    func payWithApplePay() { }
    func payWithGooglePay() { }
    
    func checkoutWithSelectedPaymentMethod(saveMethod: Bool) async throws -> FrameObjects.ChargeIntent? {
        guard amount != 0 else { return nil }
        var paymentMethodId: String?
        
        if selectedCustomerPaymentOption == nil {
            guard customerZipCode.count == 5 else { return nil }
            let customerInfo = try? await createPaymentMethod(customerId: customerId)
            paymentMethodId = customerInfo?.paymentId
            customerId = customerInfo?.customerId
        } else {
            paymentMethodId = selectedCustomerPaymentOption?.id
        }
        guard paymentMethodId != nil else { return nil }
        
        //TODO: Allow developers to pass description here of charge.
        let request = ChargeIntentsRequests.CreateChargeIntentRequest(amount: amount,
                                                                      currency: "usd",
                                                                      customer: customerId,
                                                                      description: "",
                                                                      paymentMethod: paymentMethodId,
                                                                      confirm: true,
                                                                      receiptEmail: nil,
                                                                      authorizationMode: .automatic,
                                                                      customerData: nil,
                                                                      paymentMethodData: nil)
        
        // Create Charge Intent, return this on completion.
        return try? await ChargeIntentsAPI.createChargeIntent(request: request)
        
        //TODO: Show API error for charge intent, and why it failed.
    }
    
    func createPaymentMethod(customerId: String? = nil) async throws -> (paymentId: String?, customerId: String?)  {
        guard !customerAddressLine1.isEmpty, !customerCity.isEmpty, !customerState.isEmpty, !customerZipCode.isEmpty, cardData.isPotentiallyValid else { return (nil, nil) }
        let billingAddress = FrameObjects.BillingAddress(city: customerCity,
                                                         country: customerCountry.alpha2Code,
                                                         state: customerState,
                                                         postalCode: customerZipCode,
                                                         addressLine1: customerAddressLine1,
                                                         addressLine2: customerAddressLine2)
        
        var currentCustomerId: String = ""
        if customerId == nil {
            //1. Create the new user to assign the payment method to.
            let customerRequest = CustomerRequest.CreateCustomerRequest(billingAddress: billingAddress, name: customerName, email: customerEmail)
            let customer = try? await CustomersAPI.createCustomer(request: customerRequest)
            currentCustomerId = customer?.id ?? ""
            guard currentCustomerId != "" else { return (nil, nil) }
        } else if let customerId {
            currentCustomerId = customerId
        }
        
        //2. Create the payment method
        let request = PaymentMethodRequest.CreatePaymentMethodRequest(type: "card",
                                                                      cardNumber: cardData.card.number,
                                                                      expMonth: cardData.card.expMonth,
                                                                      expYear: cardData.card.expYear,
                                                                      cvc: cardData.card.cvc,
                                                                      customer: nil,
                                                                      billing: billingAddress)
        let paymentMethod = try? await PaymentMethodsAPI.createPaymentMethod(request: request, encryptData: false)
        guard let paymentMethodId = paymentMethod?.id else { return (nil, nil) }
        
        //3. Attach the new payment method to the customer.
        let attachRequest = PaymentMethodRequest.AttachPaymentMethodRequest(customer: currentCustomerId)
        let method = try? await PaymentMethodsAPI.attachPaymentMethodWith(paymentMethodId: paymentMethodId, request: attachRequest)
        return (method?.id, currentCustomerId)
    }
}

public enum AvailableCountries: String, CaseIterable {
    case AF, AX, AL, DZ, AS, AD, AO, AI, AQ, AG
    case AR, AM, AW, AU, AT, AZ, BS, BH, BD, BB
    case BY, BE, BZ, BJ, BM, BT, BO, BQ, BA, BW
    case BV, BR, IO, BN, BG, BF, BI, KH, CM, CA
    case CV, KY, CF, TD, CL, CN, CX, CC, CO, KM
    case CG, CD, CK, CR, CI, HR, CU, CW, CY, CZ
    case DK, DJ, DM, DO, EC, EG, SV, GQ, ER, EE
    case SZ, ET, FK, FO, FJ, FI, FR, GF, PF, TF
    case GA, GM, GE, DE, GH, GI, GR, GL, GD, GP
    case GU, GT, GG, GN, GW, GY, HT, HM, VA, HN
    case HK, HU, IS, IN, ID, IR, IQ, IE, IM, IL
    case IT, JM, JP, JE, JO, KZ, KE, KI, KP, KR
    case KW, KG, LA, LV, LB, LS, LR, LY, LI, LT
    case LU, MO, MG, MW, MY, MV, ML, MT, MH, MQ
    case MR, MU, YT, MX, FM, MD, MC, MN, ME, MS
    case MA, MZ, MM, NA, NR, NP, NL, NC, NZ, NI
    case NE, NG, NU, NF, MK, MP, NO, OM, PK, PW
    case PS, PA, PG, PY, PE, PH, PN, PL, PT, PR
    case QA, RE, RO, RU, RW, BL, SH, KN, LC, MF
    case PM, VC, WS, SM, ST, SA, SN, RS, SC, SL
    case SG, SX, SK, SI, SB, SO, ZA, GS, SS, ES
    case LK, SD, SR, SJ, SE, CH, SY, TW, TJ, TZ
    case TH, TL, TG, TK, TO, TT, TN, TR, TM, TC
    case TV, UG, UA, AE, GB, US, UM, UY, UZ, VU
    case VE, VN, VG, VI, WF, EH, YE, ZM, ZW

    var alpha2Code: String {
        return self.rawValue
    }

    var countryName: String {
        let locale = Locale(identifier: "en_US")
        return locale.localizedString(forRegionCode: self.rawValue) ?? self.rawValue
    }
}
