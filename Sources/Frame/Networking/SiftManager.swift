//
//  SiftManager.swift
//  Frame-iOS
//
//  Created by Frame Payments on 3/3/25.
//

import Foundation
import Sift

/// Manages Sift Science fraud-detection integration for the Frame SDK.
///
/// `SiftManager` handles initialising the Sift SDK with credentials fetched from the
/// Frame configuration API, recording user-lifecycle events (e.g. login), and
/// collecting device signals that Sift uses to assess transaction risk.
public class SiftManager {
    /// Represents the type of a payment transaction reported to Sift.
    enum SiftTransactionType: String {
        /// A sale (authorise + capture in a single step).
        case sale = "$sale"
        /// An authorisation-only transaction.
        case authorize = "$authorize"
        /// A capture against a previously authorised transaction.
        case capture = "$capture"
        /// A refund against a previously settled transaction.
        case refund = "$refund"
    }

    /// Fetches Sift credentials from the Frame configuration API and initialises
    /// the shared `Sift` instance, falling back to keychain-cached credentials
    /// when the network request is unavailable.
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

    /// Records a Sift `$login` event for the given customer.
    ///
    /// Call this as soon as customer identity is known (e.g. after sign-in).
    /// The method is a no-op if a user ID has already been associated with the
    /// current Sift session.
    ///
    /// - Parameters:
    ///   - customerId: The unique identifier of the authenticated customer.
    ///   - email: The email address of the authenticated customer.
    //Set the login event the first chance you get customer details.
    class func collectLoginEvent(customerId: String, email: String) {
        guard let sift = Sift.sharedInstance(), sift.userId == nil else { return }
        sift.userId = customerId

        let event = SiftEvent()
        event.type = "$login"
        event.fields = ["$ip": getIPAddress() ?? "", "$user_email": email]

        // Added event to queue and collect data
        sift.append(event)
        sift.collect()
        sift.upload()
    }

    /// Returns the current device IP address by inspecting active network interfaces.
    ///
    /// Checks Wi-Fi (`en0`–`en4`) and cellular (`pdp_ip0`–`pdp_ip3`) interfaces for
    /// an IPv4 or IPv6 address and returns the last matching address found.
    ///
    /// - Returns: A human-readable IP address string, or `nil` if no suitable
    ///   interface is available.
    public class func getIPAddress() -> String? {
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
