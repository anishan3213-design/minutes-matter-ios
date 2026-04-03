//
//  MapViewModel.swift
//  Minutes Matter
//

import Combine
import CoreLocation
import Foundation
import MapKit

@MainActor
final class MapViewModel: ObservableObject {
    @Published var fires: [FirePoint] = []
    @Published var shelters: [ShelterPoint] = []
    @Published var isLoading = false
    @Published var fireError: String?
    @Published var showShelters = false
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5, longitude: -119.0),
        span: MKCoordinateSpan(latitudeDelta: 10.0, longitudeDelta: 10.0)
    )

    func load(accessToken: String?) async {
        isLoading = true
        fireError = nil

        #if DEBUG
        print("[Map] load token:", accessToken != nil ? "present" : "nil")
        #endif

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                let result = await APIService.shared.fetchActiveFires(accessToken: accessToken)
                await MainActor.run {
                    self.fires = result
                    #if DEBUG
                    print("[Map] Loaded \(result.count) fires")
                    #endif
                }
            }
            group.addTask {
                do {
                    let result = try await APIService.shared.fetchLiveShelters(accessToken: accessToken)
                    await MainActor.run {
                        self.shelters = result
                        #if DEBUG
                        print("[Map] Loaded \(result.count) shelters")
                        #endif
                    }
                } catch {
                    #if DEBUG
                    print("[Map] Shelter fetch error:", error)
                    #endif
                }
            }
        }

        centerOnFires()

        isLoading = false
    }

    func centerOnFires() {
        guard !fires.isEmpty else { return }
        let avgLat = fires.map(\.lat).reduce(0, +) / Double(fires.count)
        let avgLon = fires.map(\.lon).reduce(0, +) / Double(fires.count)
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
            span: MKCoordinateSpan(latitudeDelta: 8.0, longitudeDelta: 8.0)
        )
    }

    func centerOnUser(_ coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        )
    }
}
