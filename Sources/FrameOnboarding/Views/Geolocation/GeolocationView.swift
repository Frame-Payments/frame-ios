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

/// A SwiftUI view that checks the user's geolocation and detects VPN or proxy usage during onboarding.
///
/// `GeolocationView` resolves the device's IP address, inspects network interfaces for active
/// VPN tunnels, and checks system proxy settings. It displays a state-specific illustration and
/// title that updates as the check progresses. When a VPN or proxy is detected the view surfaces
/// action buttons so the user can continue anyway or disable the VPN before proceeding.
public struct GeolocationView: View {
    /// Represents the possible states of the geolocation check.
    enum GeolocationState {
        /// The geolocation check is currently in progress.
        case checking
        /// The geolocation check completed successfully with no VPN or proxy detected.
        case verified
        /// A VPN or system proxy was detected on the device.
        case vpn

        /// The name of the image asset that corresponds to the current state.
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

        /// The user-facing title string that describes the current state.
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

    @Environment(\.frameTheme) private var theme
    /// The shared view model that manages onboarding container state, including IP address and coordinates.
    @StateObject var onboardingContainerViewModel: OnboardingContainerViewModel
    /// A binding that, when set to `true`, advances the onboarding flow to the next step.
    @Binding var continueToNextStep: Bool
    /// The current geolocation check state, which drives the displayed illustration and title.
    @State var geolocationState: GeolocationState = .checking

    /// The root body of the view.
    public var body: some View {
        GeolocationStateView
            .onAppear {
                //1. Get IP Address
                onboardingContainerViewModel.ipAddress = SiftManager.getIPAddress()
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

    /// A state-driven view that renders the appropriate illustration, title, and action buttons for the current `geolocationState`.
    var GeolocationStateView: some View {
        VStack(spacing: 10.0) {
            if geolocationState == .vpn {
                Spacer()
            }
            Image(geolocationState.stateImage, bundle: FrameResources.module)
            Text(geolocationState.stateTitle)
                .font(theme.fonts.headline)
            Text("This will only take a moment..")
                .font(theme.fonts.caption)
                .foregroundColor(theme.colors.textSecondary)
            if geolocationState == .vpn {
                Spacer()
                ContinueButton(buttonText: "Continue Anyway") {
                    self.continueToNextStep = true
                }
                .padding(.bottom, -25.0)
                ContinueButton(buttonText: "Disable VPN", style: .secondary) {
                    self.continueToNextStep = true
                }
            }
        }
    }

    /// Returns `true` if any active network interface name indicates a VPN tunnel (utun, ppp, ipsec, tun, or tap prefix).
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

    /// Returns `true` if the system has an HTTP, HTTPS, or SOCKS proxy enabled in `CFNetworkCopySystemProxySettings`.
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
    GeolocationView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []),
                    continueToNextStep: .constant(false))
}

#Preview("Dark") {
    GeolocationView(onboardingContainerViewModel: OnboardingContainerViewModel(accountId: "", requiredCapabilities: []),
                    continueToNextStep: .constant(false))
        .preferredColorScheme(.dark)
}
