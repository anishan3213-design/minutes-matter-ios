//
//  MapView.swift
//  Minutes Matter
//

import Combine
import CoreLocation
import MapKit
import SwiftUI

struct MapUserCoord: Equatable {
    let lat: Double
    let lon: Double
}

final class MapLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userCoordinate: MapUserCoord?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestWhenInUseAndStart() {
        manager.requestWhenInUseAuthorization()
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .notDetermined:
            break
        default:
            break
        }
    }

    func startUpdatesIfAuthorized() {
        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let c = locations.last?.coordinate else { return }
        DispatchQueue.main.async { [weak self] in
            self?.userCoordinate = MapUserCoord(lat: c.latitude, lon: c.longitude)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        startUpdatesIfAuthorized()
    }
}

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationManager = MapLocationManager()
    @State private var selectedPin: MapPinItem?
    @State private var pendingLocate = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            ZStack {
                Map(
                    coordinateRegion: $viewModel.region,
                    interactionModes: [.pan, .zoom],
                    showsUserLocation: true,
                    annotationItems: viewModel.pins
                ) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        pinView(for: item)
                    }
                }

                if viewModel.showHazards {
                    VStack {
                        Text("Hazard layers coming soon.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(10)
                            .background(AppColors.card.opacity(0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        Spacer()
                    }
                    .padding(.top, 12)
                    .allowsHitTesting(false)
                }

                if !viewModel.isLoading, viewModel.fires.isEmpty,
                   !viewModel.showShelters || viewModel.shelters.isEmpty {
                    Text("No fires to show. Pull refresh or check back later.")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(20)
                        .background(AppColors.card.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        .padding(24)
                        .allowsHitTesting(false)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColors.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.15))
                        .allowsHitTesting(false)
                }

                VStack {
                    Spacer()
                    HStack(alignment: .bottom) {
                        legendCard
                        Spacer()
                        locateButton
                    }
                    .padding(12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hex: "#0f0f0f"))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let pin = selectedPin {
                calloutCard(for: pin)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
        .task {
            await viewModel.load()
        }
        .onChange(of: locationManager.userCoordinate) { newValue in
            guard pendingLocate, let c = newValue else { return }
            viewModel.centerOnUser(CLLocationCoordinate2D(latitude: c.lat, longitude: c.lon))
            pendingLocate = false
        }
    }

    private var toolbar: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("Map")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "#ffffff"))
            Spacer(minLength: 8)
            mapToolbarChip(title: "Shelters", isSelected: viewModel.showShelters) {
                viewModel.showShelters.toggle()
            }
            mapToolbarChip(title: "Hazards", isSelected: viewModel.showHazards) {
                viewModel.showHazards.toggle()
            }
            Button {
                Task { await viewModel.load() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#16a34a"))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#1a1a1a"))
    }

    private func mapToolbarChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#ffffff"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#16a34a") : Color(hex: "#1a1a1a"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.clear : Color(hex: "#2a2a2a"), lineWidth: 1)
                )
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var legendCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            legendRow(color: Color(hex: "#dc2626"), text: "Active threat")
            legendRow(color: Color(hex: "#f97316"), text: "Spreading")
            legendRow(color: Color(hex: "#eab308"), text: "Being controlled")
            legendRow(color: Color(hex: "#22c55e"), text: "Mostly contained")
            HStack(spacing: 6) {
                Text("♥")
                    .foregroundColor(AppColors.primary)
                Text("Open shelter (verified)")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#9ca3af"))
            }
        }
        .padding(12)
        .frame(maxWidth: 200, alignment: .leading)
        .background(Color(hex: "#1a1a1a"))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "#2a2a2a"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func legendRow(color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 0.5))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#9ca3af"))
        }
    }

    private var locateButton: some View {
        Button {
            pendingLocate = true
            locationManager.requestWhenInUseAndStart()
            if let c = locationManager.userCoordinate {
                viewModel.centerOnUser(CLLocationCoordinate2D(latitude: c.lat, longitude: c.lon))
                pendingLocate = false
            }
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "#ffffff"))
                .frame(width: 48, height: 48)
                .background(AppColors.primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Locate me")
    }

    @ViewBuilder
    private func pinView(for item: MapPinItem) -> some View {
        let selected = selectedPin?.id == item.id
        switch item {
        case let .fire(fire):
            FireAnnotation(fire: fire, isSelected: selected) {
                selectedPin = selected ? nil : item
            }
        case let .shelter(shelter):
            ShelterAnnotation(shelter: shelter, isSelected: selected) {
                selectedPin = selected ? nil : item
            }
        }
    }

    private func calloutCard(for item: MapPinItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                switch item {
                case let .fire(f):
                    Text(f.name ?? "Active fire")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                case let .shelter(s):
                    Text(s.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
                Spacer()
                Button {
                    selectedPin = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textMuted)
                }
                .buttonStyle(.plain)
            }
            switch item {
            case let .fire(f):
                if let pct = f.containmentPct {
                    Text(String(format: "Containment: %.0f%%", pct))
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    Text("Containment: unknown")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }
                if let src = f.source, !src.isEmpty {
                    Text(src)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textMuted)
                }
            case let .shelter(s):
                if s.verified == true {
                    Text("OPEN ✅")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.primaryLight)
                } else {
                    Text("Unverified")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
