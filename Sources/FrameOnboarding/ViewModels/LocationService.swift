//
//  File.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 1/21/26.
//

import Foundation
import CoreLocation

final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var onUpdate: ((CLLocationCoordinate2D) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation(_ completion: @escaping (CLLocationCoordinate2D) -> Void) {
        onUpdate = completion
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.first?.coordinate else { return }
        onUpdate?(coord)
        onUpdate = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error)
        onUpdate = nil
    }
}
