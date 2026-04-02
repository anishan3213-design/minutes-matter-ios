//
//  FieldMapView.swift
//  Minutes Matter
//

import MapKit
import SwiftUI
import UIKit

struct FieldMapView: View {
    @StateObject private var mapVM = FieldMapViewModel()
    @StateObject private var locationMgr = FirefighterLocationManager()
    @EnvironmentObject private var authState: AuthState

    @State private var showClearConfirm = false
    @State private var pendingClearStatus = ""
    @State private var pendingHousehold: HouseholdPin?
    @State private var clearError: String?
    @State private var showClearError = false

    var body: some View {
        ZStack {
            Color(hex: "#0f0f0f")
                .ignoresSafeArea()
            Map(
                coordinateRegion: $mapVM.region,
                interactionModes: [.pan, .zoom],
                showsUserLocation: true,
                annotationItems: mapVM.households
            ) { household in
                MapAnnotation(coordinate: household.coordinate) {
                    HouseholdAnnotation(
                        household: household,
                        isSelected: mapVM.selectedHousehold?.id == household.id
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            mapVM.selectedHousehold = household
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            VStack {
                if let assignment = mapVM.currentAssignment {
                    FlameoAssignmentBanner(text: assignment)
                        .padding(.top, 8)
                }
                Spacer(minLength: 0)
            }

            VStack {
                Spacer(minLength: 0)
                if let h = mapVM.selectedHousehold {
                    HouseholdDetailSheet(
                        household: h,
                        onEvacuated: {
                            queueClear(h, status: "evacuated")
                        },
                        onEMS: {
                            queueClear(h, status: "needs_ems")
                        },
                        onNoAnswer: {
                            queueClear(h, status: "no_answer")
                        },
                        onNavigate: {
                            openMaps(lat: h.lat, lng: h.lng, address: h.address)
                        },
                        onDismiss: {
                            withAnimation {
                                mapVM.selectedHousehold = nil
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.spring(), value: mapVM.selectedHousehold?.id)
        }
        .ignoresSafeArea()
        .alert("Confirm update", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {
                pendingHousehold = nil
                pendingClearStatus = ""
            }
            Button("Send") {
                Task { await performClear() }
            }
        } message: {
            Text("Report this address to command as \"\(humanReadableClearStatus(pendingClearStatus))\"?")
        }
        .alert("Could not update", isPresented: $showClearError) {
            Button("OK") {
                clearError = nil
            }
        } message: {
            Text(clearError ?? "")
        }
        .onAppear {
            Task {
                let token = try? await authState.accessToken()
                await mapVM.load(token: token)
            }
            locationMgr.onUpdate = { lat, lng in
                Task {
                    let token = try? await authState.accessToken()
                    await APIService.shared.updateFirefighterLocation(lat: lat, lng: lng, token: token)
                }
            }
            locationMgr.startTracking()
        }
        .onDisappear {
            locationMgr.stopTracking()
        }
        .refreshable {
            let token = try? await authState.accessToken()
            await mapVM.load(token: token)
        }
    }

    private func queueClear(_ h: HouseholdPin, status: String) {
        pendingHousehold = h
        pendingClearStatus = status
        showClearConfirm = true
    }

    private func humanReadableClearStatus(_ raw: String) -> String {
        switch raw {
        case "evacuated": return "evacuated"
        case "needs_ems": return "needs EMS"
        case "no_answer": return "no answer"
        default: return raw
        }
    }

    private func performClear() async {
        guard let h = pendingHousehold else { return }
        let status = pendingClearStatus
        pendingHousehold = nil
        pendingClearStatus = ""
        do {
            let token = try await authState.accessToken()
            try await mapVM.clearHouse(
                household: h,
                member: nil,
                status: status,
                token: token
            )
        } catch {
            clearError = error.localizedDescription
            showClearError = true
        }
    }

    private func openMaps(lat: Double, lng: Double, address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(lat),\(lng)"
        if let url = URL(string: "maps://?daddr=\(encoded)&dirflg=d") {
            UIApplication.shared.open(url)
        }
    }
}
