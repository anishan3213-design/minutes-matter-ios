//
//  HubView.swift
//  Minutes Matter
//

import SwiftUI

enum AppMainTab: Hashable {
    case hub
    case checkIn
    case map
    case people
    case settings
}

struct HubView: View {
    @EnvironmentObject private var authState: AuthState
    @Environment(\.openURL) private var openURL
    @Binding var selectedTab: AppMainTab
    @StateObject private var viewModel = HubViewModel()
    @State private var showFlameo = false

    private var isHomeAddressMissing: Bool {
        let trimmed = authState.profile?.address?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty
    }

    private var showShelterCard: Bool {
        guard let c = viewModel.context else { return false }
        return c.flags?.hasConfirmedThreat == true && !(c.sheltersRanked?.isEmpty ?? true)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                if viewModel.isLoading && viewModel.context == nil {
                    Spacer()
                    ProgressView()
                        .tint(AppColors.primary)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if let err = viewModel.errorMessage {
                                errorStrip(err)
                            }
                            if isHomeAddressMissing {
                                addressBanner
                            }
                            if let ctx = viewModel.context {
                                ActiveSituationCard(context: ctx)
                            } else if !viewModel.isLoading {
                                Text("No fire data loaded.")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                            }
                            if showShelterCard, let top = viewModel.context?.sheltersRanked?.first {
                                ShelterRouteCard(
                                    shelter: top,
                                    onOpenMaps: {
                                        openDirections(lat: top.lat, lon: top.lon)
                                    },
                                    onSeeAllShelters: {
                                        selectedTab = .map
                                    }
                                )
                            }
                            if !viewModel.people.isEmpty {
                                MyPeopleStatusCard(people: viewModel.people) {
                                    selectedTab = .people
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .refreshable {
                        await viewModel.load(auth: authState)
                    }
                }
            }
        }
        .task {
            await viewModel.load(auth: authState)
        }
        .sheet(isPresented: $showFlameo) {
            FlameoSituationView(context: viewModel.context)
                .environmentObject(authState)
        }
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            Text("My Hub")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button {
                showFlameo = true
            } label: {
                HStack(spacing: 6) {
                    Text("🔥")
                    Text("Flameo")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(AppColors.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func openDirections(lat: Double, lon: Double) {
        let s = String(format: "maps://?daddr=%f,%f&dirflg=d", lat, lon)
        guard let url = URL(string: s) else { return }
        openURL(url)
    }

    private func errorStrip(_ message: String) -> some View {
        VStack(spacing: 10) {
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(AppColors.danger)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Retry") {
                Task { await viewModel.load(auth: authState) }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppColors.primary)
        }
        .frame(maxWidth: .infinity)
        .hubCardStyle()
    }

    private var addressBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add your home address to get personalized fire alerts")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open Settings") {
                selectedTab = .settings
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.accent, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
