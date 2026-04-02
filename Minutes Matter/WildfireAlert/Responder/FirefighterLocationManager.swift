//
//  FirefighterLocationManager.swift
//  Minutes Matter
//

import Combine
import CoreLocation
import Foundation

final class FirefighterLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var lastSentLocation: CLLocation?
    private var lastSentTime: Date?

    @Published var coordinate: CLLocationCoordinate2D?

    var onUpdate: ((Double, Double) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 50
    }

    func startTracking() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.coordinate = loc.coordinate

            let now = Date()
            let movedEnough = self.lastSentLocation.map { loc.distance(from: $0) > 50 } ?? true
            let timeEnough = self.lastSentTime.map { now.timeIntervalSince($0) > 120 } ?? true

            if movedEnough || timeEnough {
                self.lastSentLocation = loc
                self.lastSentTime = now
                self.onUpdate?(loc.coordinate.latitude, loc.coordinate.longitude)
            }
        }
    }
}
