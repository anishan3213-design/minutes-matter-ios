//
//  MapViewModel.swift
//  Minutes Matter
//

import Combine
import CoreLocation
import Foundation
import MapKit

enum MapPinItem: Identifiable {
    case fire(FirePoint)
    case shelter(ShelterPoint)

    var id: String {
        switch self {
        case let .fire(f): return "fire-\(f.id)"
        case let .shelter(s): return "shelter-\(s.id)"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case let .fire(f): return f.coordinate
        case let .shelter(s): return s.coordinate
        }
    }
}

@MainActor
final class MapViewModel: ObservableObject {
    @Published var fires: [FirePoint] = []
    @Published var shelters: [ShelterPoint] = []
    @Published var isLoading = false
    @Published var showShelters = false
    @Published var showHazards = false
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.5, longitude: -80.8),
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )

    var pins: [MapPinItem] {
        var items: [MapPinItem] = fires.map { .fire($0) }
        if showShelters {
            items += shelters.map { .shelter($0) }
        }
        return items
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        async let firesResult = APIService.shared.fetchActiveFires()
        async let sheltersResult = APIService.shared.fetchLiveShelters()
        fires = (try? await firesResult) ?? []
        shelters = (try? await sheltersResult) ?? []
    }

    func centerOnUser(_ coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.45, longitudeDelta: 0.45)
        )
    }
}
