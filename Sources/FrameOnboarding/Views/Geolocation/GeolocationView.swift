//
//  SwiftUIView.swift
//  Frame-iOS
//
//  Created by Frame Payments on 1/21/26.
//

import SwiftUI
import Frame
import Foundation
import CFNetwork
import CoreLocation
import Network

public struct GeolocationView: View {
    enum GeolocationState {
        case checking, verified, vpn
        
        var stateImage: String {
            switch self {
            case .checking:
                return "checking-location"
            case .verified:
                return "verified-location"
            case .vpn:
                return "vpn-detected"
            }
        }
        
        var stateTitle: String {
            switch self {
            case .checking:
                return "Checking your location"
            case .verified:
                return "Location verified"
            case .vpn:
                return "VPN Detected"
            }
        }
    }
    
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel
    @Binding var continueToNextStep: Bool
    @State var geolocationState: GeolocationState = .checking
    
    public var body: some View {
        GeolocationStateView
            .onAppear {
                //1. Get IP Address
                onboardingContainerViewModel.ipAddress = getIPAddress()
                //2. Check for VPN
                guard hasVPNInterface() == false && hasSystemProxyEnabled() == false else {
                    self.geolocationState = .vpn
                    return
                }
                
                let locationService = LocationService()
                locationService.requestLocation { coordinates in
                    onboardingContainerViewModel.userCoordinates = coordinates
                }
            }
    }
    
    var GeolocationStateView: some View {
        VStack(spacing: 10.0) {
            if geolocationState == .vpn {
                Spacer()
            }
            Image(geolocationState.stateImage, bundle: FrameResources.module)
            Text(geolocationState.stateTitle)
                .font(.headline)
            Text("This will only take a moment..")
                .font(.caption)
                .foregroundColor(FrameColors.secondaryTextColor)
            if geolocationState == .vpn {
                Spacer()
                ContinueButton(buttonText: "Continue Anyway", enabled: .constant(true)) {
                    self.continueToNextStep = true
                }
                .padding(.bottom, -25.0)
                ContinueButton(buttonColor: .white, buttonText: "Disable VPN", buttonTextColor: FrameColors.mainButtonColor, enabled: .constant(true)) {
                    self.continueToNextStep = true
                }
            }
        }
    }
    
    func getIPAddress() -> String? {
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
    
    func hasVPNInterface() -> Bool {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrs) == 0, let first = addrs else { return false }
        defer { freeifaddrs(addrs) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let p = ptr {
            let name = String(cString: p.pointee.ifa_name)
            if name.hasPrefix("utun") || name.hasPrefix("ppp") || name.hasPrefix("ipsec") || name.hasPrefix("tun") || name.hasPrefix("tap") {
                return true
            }
            ptr = p.pointee.ifa_next
        }
        return false
    }
    
    func hasSystemProxyEnabled() -> Bool {
        guard let dict = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            return false
        }

        // Use string keys to avoid unavailable CFNetwork constants on iOS
        func bool(for key: String) -> Bool {
            if let num = dict[key] as? NSNumber { return num.boolValue }
            if let b = dict[key] as? Bool { return b }
            if let s = dict[key] as? String { return (s as NSString).boolValue }
            return false
        }

        let httpEnabled  = bool(for: "HTTPEnable")
        let httpsEnabled = bool(for: "HTTPSEnable")
        let socksEnabled = bool(for: "SOCKSEnable")

        return httpEnabled || httpsEnabled || socksEnabled
    }
    
//    func currentNetworkSummary(using monitor: NWPathMonitor,
//                               queue: DispatchQueue = .global(qos: .background),
//                               onUpdate: @escaping (_ isWifi: Bool, _ isCellular: Bool, _ isExpensive: Bool) -> Void) {
//        monitor.pathUpdateHandler = { path in
//            onUpdate(
//                path.usesInterfaceType(.wifi),
//                path.usesInterfaceType(.cellular),
//                path.isExpensive
//            )
//        }
//        monitor.start(queue: queue)
//    }
}

#Preview {
    GeolocationView(onboardingContainerViewModel: OnboardingContainerViewModel(customerId: ""),
                    continueToNextStep: .constant(false))
}
