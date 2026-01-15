//
//  SiftManager.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/3/25.
//

import Foundation
import Sift

class SiftManager {
    enum SiftTransactionType: String {
        case sale = "$sale"
        case authorize = "$authorize"
        case capture = "$capture"
        case refund = "$refund"
    }
    
    class func initializeSift() async {
        guard let sift = Sift.sharedInstance() else { return }
        
        do {
            if let configResponse = try await ConfigurationAPI.getSiftConfiguration() {
                sift.accountId = configResponse.accountId
                sift.beaconKey = configResponse.beaconKey
            } else if let data = ConfigurationAPI.retrieveFromKeychain(key: ConfigurationKeys.sift.rawValue) {
                let response = try FrameNetworking.shared.jsonDecoder.decode(ConfigurationResponses.GetSiftConfigurationResponse.self, from: data)
                sift.accountId = response.accountId
                sift.beaconKey = response.beaconKey
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    //Set the login event the first chance you get customer details.
    class func collectLoginEvent(customerId: String, email: String) {
        guard let sift = Sift.sharedInstance(), sift.userId.isEmpty else { return }
        sift.userId = customerId
        
        let event = SiftEvent()
        event.type = "$login"
        event.fields = ["$ip": getIPAddress() ?? "", "$user_email": email]
        
        // Added event to queue and collect data
        sift.append(event)
        sift.collect()
        sift.upload()
    }
    
    class func getIPAddress() -> String? {
        var address : String?

        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                let name = String(cString: interface.ifa_name)
                if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }
}
