//
//  ResponderSettingsView.swift
//  Minutes Matter
//

import SwiftUI

private enum DutySegment: Int, CaseIterable {
    case onDuty
    case offDuty
    case unavailable

    var title: String {
        switch self {
        case .onDuty: return "On Duty"
        case .offDuty: return "Off Duty"
        case .unavailable: return "Unavailable"
        }
    }

    var apiValue: String {
        switch self {
        case .onDuty: return "on_duty"
        case .offDuty: return "off_duty"
        case .unavailable: return "unavailable"
        }
    }

    var selectedBackground: Color {
        switch self {
        case .onDuty: return Color(hex: "#16a34a").opacity(0.35)
        case .offDuty: return Color(hex: "#4b5563").opacity(0.55)
        case .unavailable: return Color(hex: "#dc2626").opacity(0.35)
        }
    }
}

struct ResponderSettingsView: View {
    @EnvironmentObject private var authState: AuthState

    @State private var dutySegment: DutySegment = .onDuty
    @State private var showJoinStation = false
    @State private var showSignOutConfirm = false
    @State private var statusError: String?
    @State private var showStatusError = false
    @State private var isUpdatingStatus = false

    var body: some View {
        ZStack {
            Color(hex: "#0f0f0f")
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SectionLabel(text: "STATION")
                    stationBlock

                    SectionLabel(text: "MY STATUS")
                    dutyBlock

                    SectionLabel(text: "ACCOUNT")
                    accountBlock
                }
                .padding(16)
            }
        }
        .navigationTitle("Settings")
        .mmNavigationChrome()
        .sheet(isPresented: $showJoinStation) {
            NavigationStack {
                JoinStationView()
                    .environmentObject(authState)
                    .mmNavigationChrome()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showJoinStation = false }
                                .foregroundColor(Color(hex: "#9ca3af"))
                        }
                    }
            }
        }
        .alert("Sign out?", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task { await authState.signOut() }
            }
        } message: {
            Text("You will need to sign in again to access field tools.")
        }
        .alert("Status update failed", isPresented: $showStatusError) {
            Button("OK") { statusError = nil }
        } message: {
            Text(statusError ?? "")
        }
    }

    private var stationBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            row(title: "Department", value: authState.profile?.orgName ?? "—")
            row(title: "Station address", value: authState.profile?.address ?? "—")
            HStack {
                Text("Incident status")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#9ca3af"))
                Spacer()
                Text("Active")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#ffffff"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#16a34a"))
                    .cornerRadius(6)
            }
            .padding(.vertical, 4)

            Button {
                showJoinStation = true
            } label: {
                Text("Join a Station")
            }
            .buttonStyle(PrimaryButtonStyle(color: Color(hex: "#d97706")))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var dutyBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                ForEach(DutySegment.allCases, id: \.rawValue) { seg in
                    Button {
                        dutySegment = seg
                        Task { await pushDutyStatus(seg) }
                    } label: {
                        Text(seg.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(dutySegment == seg ? Color(hex: "#ffffff") : Color(hex: "#6b7280"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(dutySegment == seg ? seg.selectedBackground : Color.clear)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color(hex: "#1a1a1a"))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "#2a2a2a"), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var accountBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            row(title: "Name", value: authState.profile?.fullName ?? "—")
            row(title: "Email", value: authState.profile?.email ?? "—")

            Button(role: .destructive) {
                showSignOutConfirm = true
            } label: {
                Text("Sign Out")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#dc2626"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func row(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#6b7280"))
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#ffffff"))
        }
    }

    private func pushDutyStatus(_ segment: DutySegment) async {
        guard !isUpdatingStatus else { return }
        isUpdatingStatus = true
        defer { isUpdatingStatus = false }
        do {
            let token = try await authState.accessToken()
            try await APIService.shared.updateResponderFieldStatus(segment.apiValue, token: token)
        } catch {
            statusError = error.localizedDescription
            showStatusError = true
        }
    }
}
