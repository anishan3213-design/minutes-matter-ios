//
//  AssignmentsView.swift
//  Minutes Matter
//

import SwiftUI
import UIKit

struct AssignmentsView: View {
    @StateObject private var vm = AssignmentsViewModel()
    @EnvironmentObject private var authState: AuthState

    @State private var showClearConfirm = false
    @State private var pendingAssignment: PriorityAssignment?
    @State private var actionError: String?
    @State private var showActionError = false

    var body: some View {
        ZStack {
            Color(hex: "#0f0f0f")
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    briefingSection
                    zoneSection
                    prioritySection
                    fieldUnitsSection
                }
                .padding(16)
            }
            .refreshable {
                await refresh()
            }
        }
        .navigationTitle("Assignments")
        .mmNavigationChrome()
        .task {
            await refresh()
        }
        .alert("Mark cleared?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) { pendingAssignment = nil }
            Button("Confirm") {
                Task { await markCleared() }
            }
        } message: {
            if let a = pendingAssignment {
                Text("Report \(a.address) as cleared to command?")
            }
        }
        .alert("Action failed", isPresented: $showActionError) {
            Button("OK") { actionError = nil }
        } message: {
            Text(actionError ?? "")
        }
    }

    private var briefingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔥 FLAMEO COMMAND")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#d97706"))
                    .tracking(0.8)
                Spacer()
                Button {
                    Task { await refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Color(hex: "#9ca3af"))
                }
                .disabled(vm.isLoading)
            }

            if vm.isLoading, vm.briefing == nil {
                ProgressView()
                    .tint(AppColors.accent)
            } else if let b = vm.briefing {
                Text(b)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#ffffff"))
            } else {
                Text("Pull to refresh for the latest briefing.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textMuted)
            }

            if let t = vm.lastUpdated {
                Text("Last updated \(RelativeDateTimeFormatter().localizedString(for: t, relativeTo: Date()))")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#6b7280"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder
    private var zoneSection: some View {
        if let summary = vm.commandContext?.incidentSummary {
            let rate = vm.normalizedCompletionRate(summary)
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "ZONE STATUS", includeTopSpacing: false)

                ProgressView(value: rate)
                    .tint(zoneTint(rate: rate))

                Text("\(Int(rate * 100))% evacuated")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                let total = summary.totalPeople ?? 0
                let evac = summary.evacuated ?? 0
                Text("\(evac) of \(total) people")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)

                HStack(spacing: 20) {
                    Text("✅ \(summary.evacuated ?? 0)")
                    Text("⚠️ \(summary.needsHelp ?? 0)")
                    Text("🏠 \(max(0, total - (summary.evacuated ?? 0)))")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    private func zoneTint(rate: Double) -> Color {
        if rate < 0.5 { return Color(hex: "#dc2626") }
        if rate < 0.8 { return Color(hex: "#d97706") }
        return Color(hex: "#16a34a")
    }

    @ViewBuilder
    private var prioritySection: some View {
        if !vm.topAssignments.isEmpty {
            SectionLabel(text: "PRIORITY ASSIGNMENTS", includeTopSpacing: false)

            ForEach(vm.topAssignments) { assignment in
                priorityCard(assignment)
            }
        }
    }

    private func priorityCard(_ assignment: PriorityAssignment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(assignment.actionColor)
                        .frame(width: 26, height: 26)
                    Text("\(assignment.rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#ffffff"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.address)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "#ffffff"))
                    Text(assignment.actionLabel)
                        .font(.system(size: 13))
                        .foregroundColor(assignment.actionColor)
                    if let assigned = assignment.assignedTo {
                        Text("→ \(assigned)")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textMuted)
                    }
                }

                Spacer(minLength: 0)

                if let lat = assignment.lat, let lng = assignment.lng {
                    Button {
                        openMaps(lat: lat, lng: lng, address: assignment.address)
                    } label: {
                        Image(systemName: "map.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "#3b82f6"))
                    }
                }
            }

            let flags = (assignment.mobilityFlags ?? []) + (assignment.medicalFlags ?? [])
            if !flags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(flags, id: \.self) { flag in
                        Text(flag)
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#d97706").opacity(0.2))
                            .foregroundColor(Color(hex: "#d97706"))
                            .cornerRadius(12)
                    }
                }
            }

            if let reason = assignment.reason, !reason.isEmpty {
                Text(reason)
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(AppColors.textMuted)
            }

            Button {
                pendingAssignment = assignment
                showClearConfirm = true
            } label: {
                Text("✓ Mark Cleared")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#16a34a"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder
    private var fieldUnitsSection: some View {
        if let units = vm.commandContext?.fieldUnitsReporting, !units.isEmpty {
            SectionLabel(text: "FIELD UNITS", includeTopSpacing: false)

            ForEach(units) { unit in
                HStack(alignment: .top, spacing: 12) {
                    Text("🧑‍🚒")
                        .font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(unit.name ?? "Unit")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        if let a = unit.assignment, !a.isEmpty {
                            Text(a)
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(relativeFromISO(unit.lastSeenAt))
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textMuted)
                        if let st = unit.status, !st.isEmpty {
                            Text(st.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#ffffff"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(hex: "#374151"))
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
    }

    private func refresh() async {
        let token = try? await authState.accessToken()
        await vm.load(token: token)
    }

    private func markCleared() async {
        guard let a = pendingAssignment else { return }
        pendingAssignment = nil
        do {
            let token = try await authState.accessToken()
            try await APIService.shared.clearHouse(
                userId: a.targetUserId,
                address: a.address,
                clearedStatus: "cleared",
                token: token
            )
            await refresh()
        } catch {
            actionError = error.localizedDescription
            showActionError = true
        }
    }

    private func relativeFromISO(_ s: String?) -> String {
        guard let s, !s.isEmpty else { return "—" }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) {
            return RelativeDateTimeFormatter().localizedString(for: d, relativeTo: Date())
        }
        f.formatOptions = [.withInternetDateTime]
        if let d = f.date(from: s) {
            return RelativeDateTimeFormatter().localizedString(for: d, relativeTo: Date())
        }
        return s
    }

    private func openMaps(lat: Double, lng: Double, address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(lat),\(lng)"
        if let url = URL(string: "maps://?daddr=\(encoded)&dirflg=d") {
            UIApplication.shared.open(url)
        }
    }
}
