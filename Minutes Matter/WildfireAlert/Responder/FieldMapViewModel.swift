//
//  FieldMapViewModel.swift
//  Minutes Matter
//

import Combine
import CoreLocation
import Foundation
import MapKit

@MainActor
final class FieldMapViewModel: ObservableObject {
    @Published var households: [HouseholdPin] = []
    @Published var isLoading = false
    @Published var selectedHousehold: HouseholdPin?
    @Published var currentAssignment: String?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.5, longitude: -80.8),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var loadError: String?

    private let priorityOrder = ["CRITICAL": 0, "HIGH": 1, "MONITOR": 2, "CLEAR": 3]

    func load(token: String?) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            let result = try await APIService.shared.fetchHouseholds(token: token)
            households = result.sorted { a, b in
                (priorityOrder[a.priority.uppercased()] ?? 4) < (priorityOrder[b.priority.uppercased()] ?? 4)
            }
            fitRegionIfNeeded()
        } catch {
            households = []
            loadError = error.localizedDescription
        }

        do {
            let ctx = try await APIService.shared.fetchCommandContext(token: token)
            if let sorted = ctx.priorityAssignments?.sorted(by: { $0.rank < $1.rank }), let first = sorted.first {
                currentAssignment = "\(first.actionLabel) — \(first.address)"
            } else if let rate = ctx.incidentSummary?.completionRate {
                currentAssignment = "Zone: \(Int(rate))% evacuated"
            } else {
                currentAssignment = nil
            }
        } catch {
            currentAssignment = nil
        }
    }

    private func fitRegionIfNeeded() {
        guard !households.isEmpty else { return }
        let coords = households.map(\.coordinate)
        var minLat = coords[0].latitude
        var maxLat = coords[0].latitude
        var minLon = coords[0].longitude
        var maxLon = coords[0].longitude
        for c in coords.dropFirst() {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.02),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.02)
        )
        region = MKCoordinateRegion(center: center, span: span)
    }

    func clearHouse(
        household: HouseholdPin,
        member: HouseholdMember?,
        status: String,
        token: String?
    ) async throws {
        let targetId = member?.id ?? household.members.compactMap(\.id).first
        try await APIService.shared.clearHouse(
            userId: targetId,
            address: household.address,
            clearedStatus: status,
            token: token
        )
        if let idx = households.firstIndex(where: { $0.id == household.id }) {
            households.remove(at: idx)
        }
        selectedHousehold = nil
    }
}
