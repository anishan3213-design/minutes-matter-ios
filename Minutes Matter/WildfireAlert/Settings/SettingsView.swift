//
//  SettingsView.swift
//  Minutes Matter
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authState: AuthState
    @EnvironmentObject private var appearance: AppearanceController
    @Environment(\.openURL) private var openURL

    @StateObject private var viewModel = SettingsViewModel()

    @AppStorage("wfa_fire_alerts_near_address") private var fireAlertsNearAddress = true

    @State private var showAddressSheet = false
    @State private var showMobilitySheet = false
    @State private var showSignOutConfirm = false

    private let termsURL = URL(string: "https://wildfire-app-layesh1s-projects.vercel.app/terms")!
    private let privacyURL = URL(string: "https://wildfire-app-layesh1s-projects.vercel.app/privacy")!

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0f0f0f")
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        profileSection
                        homeAddressSection
                        appearanceSection
                        notificationsSection
                        privacySection
                        accountSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Settings")
            .mmNavigationChrome()
            .onAppear {
                if let p = authState.profile {
                    viewModel.load(profile: p)
                }
            }
            .onChange(of: authState.profile) { profile in
                if let p = profile {
                    viewModel.load(profile: p)
                }
            }
            .sheet(isPresented: $showAddressSheet) {
                if let id = authState.profile?.id {
                    AddressInputView(viewModel: viewModel, userId: id)
                        .environmentObject(authState)
                }
            }
            .sheet(isPresented: $showMobilitySheet) {
                if let id = authState.profile?.id {
                    MobilitySettingsView(
                        userId: id,
                        initialMobility: authState.profile?.mobilityNeeds ?? [],
                        initialMedical: authState.profile?.medicalNeeds ?? []
                    )
                    .environmentObject(authState)
                }
            }
            .alert("Sign out?", isPresented: $showSignOutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        await viewModel.signOut(auth: authState)
                    }
                }
            } message: {
                Text("You will need to sign in again to use the app.")
            }
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "PROFILE")
            VStack(spacing: 0) {
                settingsValueRow(label: "Name", value: displayName)
                rowDivider()
                settingsValueRow(label: "Email", value: displayEmail)
                rowDivider()
                settingsRow(label: "Role") {
                    roleBadge
                }
                rowDivider()
                settingsNavigationRow(label: "Mobility & health") {
                    showMobilitySheet = true
                }
            }
            .background(Color(hex: "#1a1a1a"))
        }
    }

    private var homeAddressSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "HOME ADDRESS")
            VStack(alignment: .leading, spacing: 0) {
                settingsValueRow(label: "Current", value: addressLine)
                rowDivider()
                Button {
                    showAddressSheet = true
                } label: {
                    HStack {
                        Text("Update Address")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primaryLight)
                        Spacer()
                    }
                    .frame(height: 52)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
                rowDivider()
                Text("Emergency responders use this for door-to-door safety checks.")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .background(Color(hex: "#1a1a1a"))
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "APPEARANCE")
            VStack(spacing: 0) {
                HStack {
                    Text("Theme")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#ffffff"))
                    Spacer()
                    AppearanceThemeSegmented(selection: $appearance.appearance)
                }
                .frame(minHeight: 52)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color(hex: "#1a1a1a"))
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "NOTIFICATIONS")
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Fire alerts near my address")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#ffffff"))
                    Spacer()
                    Toggle("", isOn: $fireAlertsNearAddress)
                        .labelsHidden()
                        .tint(AppColors.primary)
                }
                .frame(height: 52)
                .padding(.horizontal, 16)
                rowDivider()
                Text("Alert range: 50 miles")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .background(Color(hex: "#1a1a1a"))
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "PRIVACY & DATA")
            VStack(spacing: 0) {
                settingsNavigationRow(label: "View Terms of Service") {
                    openURL(termsURL)
                }
                rowDivider()
                settingsNavigationRow(label: "View Privacy Policy") {
                    openURL(privacyURL)
                }
            }
            .background(Color(hex: "#1a1a1a"))
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "ACCOUNT")
            VStack(spacing: 0) {
                Button {
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
            .background(Color(hex: "#1a1a1a"))
        }
    }

    // MARK: - Rows & chrome

    private func settingsValueRow(label: String, value: String) -> some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#ffffff"))
            Spacer()
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#9ca3af"))
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 52)
        .padding(.horizontal, 16)
    }

    private func settingsRow<Trailing: View>(label: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#ffffff"))
            Spacer()
            trailing()
        }
        .frame(minHeight: 52)
        .padding(.horizontal, 16)
    }

    private func settingsNavigationRow(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#ffffff"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#6b7280"))
            }
            .frame(minHeight: 52)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func rowDivider() -> some View {
        Rectangle()
            .fill(Color(hex: "#2a2a2a"))
            .frame(height: 1)
            .padding(.leading, 16)
    }

    @ViewBuilder
    private var roleBadge: some View {
        let role = (viewModel.profile?.role ?? authState.profile?.role ?? "—").trimmingCharacters(in: .whitespacesAndNewlines)
        Text(role.isEmpty ? "—" : role.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(AppColors.primaryLight)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.primary.opacity(0.2))
            .clipShape(Capsule())
    }

    private var displayName: String {
        let n = viewModel.profile?.fullName ?? authState.profile?.fullName
        let s = n?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return s.isEmpty ? "—" : s
    }

    private var displayEmail: String {
        let e = viewModel.profile?.email ?? authState.profile?.email
        let s = e?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return s.isEmpty ? "—" : s
    }

    private var addressLine: String {
        let a = viewModel.profile?.homeAddress ?? authState.profile?.homeAddress
        let s = a?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return s.isEmpty ? "Not set" : s
    }
}

private struct AppearanceThemeSegmented: View {
    @Binding var selection: String

    private let options: [(label: String, key: String)] = [
        ("Light", "light"),
        ("Dark", "dark"),
        ("System", "system"),
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.key) { opt in
                Button {
                    selection = opt.key
                } label: {
                    Text(opt.label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selection == opt.key ? Color(hex: "#ffffff") : Color(hex: "#6b7280"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == opt.key ? Color(hex: "#242424") : Color.clear)
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
        .frame(maxWidth: 240)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthState())
        .environmentObject(AppearanceController())
}
