//
//  MapView.swift
//

import Combine
import CoreLocation
import MapKit
import SwiftUI
import UIKit

// MARK: - Annotation bridge (stable IDs for SwiftUI `Map`)

struct MapAnnotationItem: Identifiable {
    enum AnnotationType {
        case fire(FirePoint)
        case shelter(ShelterPoint)
    }

    let type: AnnotationType

    var id: String {
        switch type {
        case let .fire(f): return "fire-\(f.id)"
        case let .shelter(s): return "shelter-\(s.id)"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch type {
        case let .fire(f): return f.coordinate
        case let .shelter(s): return s.coordinate
        }
    }
}

// MARK: - Location

final class MapLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var coordinate: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        if manager.authorizationStatus == .authorizedWhenInUse
            || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinate = locations.last?.coordinate
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse
            || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

// MARK: - Map screen

struct MapView: View {
    @EnvironmentObject private var authState: AuthState
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationMgr = MapLocationManager()
    @State private var selectedFire: FirePoint?
    @State private var selectedShelter: ShelterPoint?

    var body: some View {
        ZStack {
            Map(
                coordinateRegion: $viewModel.region,
                interactionModes: [.pan, .zoom],
                showsUserLocation: true,
                annotationItems: mapAnnotations
            ) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    switch item.type {
                    case let .fire(fire):
                        FireAnnotation(fire: fire, isSelected: selectedFire?.id == fire.id) {
                            selectedFire = fire
                            selectedShelter = nil
                        }
                    case let .shelter(shelter):
                        ShelterAnnotation(shelter: shelter, isSelected: selectedShelter?.id == shelter.id) {
                            selectedShelter = shelter
                            selectedFire = nil
                        }
                    }
                }
            }

            if viewModel.isLoading {
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Loading fire data...")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(Color(hex: "#1a1a1a").opacity(0.9))
                    .cornerRadius(10)
                    .padding(.bottom, 100)
                }
            }

            if let error = viewModel.fireError {
                VStack {
                    Spacer()
                    Text("⚠️ \(error)")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#fbbf24"))
                        .padding(12)
                        .background(Color(hex: "#1a1a1a").opacity(0.9))
                        .cornerRadius(10)
                        .padding(.bottom, 100)
                }
            }

            VStack {
                HStack {
                    Text("Map")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        viewModel.showShelters.toggle()
                    } label: {
                        Text("Shelters")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(viewModel.showShelters ? Color(hex: "#16a34a") : Color(hex: "#1a1a1a"))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        viewModel.showShelters ? Color(hex: "#16a34a") : Color(hex: "#2a2a2a"),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        locationMgr.requestPermission()
                        if let coord = locationMgr.coordinate {
                            viewModel.centerOnUser(coord)
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#16a34a"))
                            .padding(8)
                            .background(Color(hex: "#1a1a1a"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await loadMapData() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#9ca3af"))
                            .padding(8)
                            .background(Color(hex: "#1a1a1a"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "#1a1a1a"))

                Spacer()

                legendView
                    .padding(.bottom, 90)
                    .padding(.horizontal, 16)
            }

            if let fire = selectedFire {
                fireCallout(fire: fire)
            }

            if let shelter = selectedShelter {
                shelterCallout(shelter: shelter)
            }
        }
        .background(Color(hex: "#0f0f0f"))
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            Task { await loadMapData() }
            locationMgr.requestPermission()
        }
        .refreshable {
            await loadMapData()
        }
    }

    private func loadMapData() async {
        let token = try? await authState.accessToken()
        #if DEBUG
        print("[Map] loadMapData token:", token != nil ? "present" : "nil")
        #endif
        await viewModel.load(accessToken: token)
    }

    private var mapAnnotations: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = viewModel.fires.map { MapAnnotationItem(type: .fire($0)) }
        if viewModel.showShelters {
            items += viewModel.shelters.map { MapAnnotationItem(type: .shelter($0)) }
        }
        return items
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LEGEND")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "#6b7280"))
                .tracking(1)

            legendRow(color: "#dc2626", label: "Active threat (<25%)")
            legendRow(color: "#f97316", label: "Spreading (25-50%)")
            legendRow(color: "#eab308", label: "Controlled (50-75%)")
            legendRow(color: "#22c55e", label: "Contained (75%+)")
            if viewModel.showShelters {
                legendRow(color: "#16a34a", label: "Open shelter ✅", shape: "heart.fill")
                legendRow(color: "#6b7280", label: "Pre-identified 📍", shape: "heart")
            }
        }
        .padding(12)
        .background(Color(hex: "#1a1a1a").opacity(0.92))
        .cornerRadius(10)
        .frame(maxWidth: 200, alignment: .leading)
    }

    private func legendRow(color: String, label: String, shape: String = "circle.fill") -> some View {
        HStack(spacing: 6) {
            Image(systemName: shape)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: color))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#9ca3af"))
        }
    }

    private func fireCallout(fire: FirePoint) -> some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(fire.name ?? "Active Fire")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        selectedFire = nil
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(hex: "#6b7280"))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 16) {
                    if let pct = fire.containmentPct {
                        Label("\(Int(pct))% contained", systemImage: "flame")
                            .font(.system(size: 14))
                            .foregroundColor(fire.containmentColor)
                    } else {
                        Label("Containment unknown", systemImage: "flame")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#dc2626"))
                    }

                    if let acres = fire.acresBurned {
                        Text("\(Int(acres)) acres")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#9ca3af"))
                    }
                }

                if let source = fire.source {
                    Text("Source: \(source.uppercased())")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#6b7280"))
                }
            }
            .padding(16)
            .background(Color(hex: "#1a1a1a"))
            .cornerRadius(12, corners: [.topLeft, .topRight])
        }
        .ignoresSafeArea(edges: .bottom)
        .transition(.move(edge: .bottom))
        .animation(.spring(), value: selectedFire?.id)
    }

    private func shelterCallout(shelter: ShelterPoint) -> some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(shelter.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        selectedShelter = nil
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(hex: "#6b7280"))
                    }
                    .buttonStyle(.plain)
                }

                if shelter.verified == true {
                    Label("OPEN — Verified by FEMA", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#16a34a"))
                } else {
                    Label("Pre-identified location — call ahead to confirm", systemImage: "questionmark.circle")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#d97706"))
                }

                if let capacity = shelter.capacity {
                    let occ = shelter.currentOccupancy ?? 0
                    Text("\(occ) / \(capacity) capacity")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#9ca3af"))
                }

                Button {
                    let urlString = "maps://?daddr=\(shelter.lat),\(shelter.lng)&dirflg=d"
                    if let url = URL(string: urlString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Get Directions", systemImage: "map.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#1d4ed8"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(hex: "#1a1a1a"))
            .cornerRadius(12, corners: [.topLeft, .topRight])
        }
        .ignoresSafeArea(edges: .bottom)
        .transition(.move(edge: .bottom))
    }
}
