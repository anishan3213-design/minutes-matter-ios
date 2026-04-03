//
//  SignUpStep2HomeAddress.swift
//  Minutes Matter
//

import Combine
import CoreLocation
import SwiftUI

struct SignUpStep2HomeAddress: View {
    @EnvironmentObject private var authState: AuthState
    @StateObject private var locationMgr = LocationPermissionManager()

    @State private var address = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var onContinue: () -> Void
    var onSkip: () -> Void

    private var canContinue: Bool {
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            signUpScreenChrome(
                title: "Where is your home?",
                subtitle: "Emergency responders use this to locate you during an evacuation."
            )

            SectionLabel(text: "HOME ADDRESS", includeTopSpacing: false)

            AddressSearchField(
                placeholder: "Search your home address",
                helperText: "Enter your full street address including city and state",
                selectedAddress: $address,
                onSelect: { details in
                    address = details.formattedAddress
                }
            )

            locationCard

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.danger)
            }

            Spacer(minLength: 24)

            Button {
                Task { await save(advance: true) }
            } label: {
                ZStack {
                    if isSaving {
                        ProgressView()
                            .tint(Color(hex: "#ffffff"))
                    } else {
                        Text("Continue")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isSaving || !canContinue)
            .opacity(canContinue ? 1 : 0.45)

            Button {
                onSkip()
            } label: {
                Text("Skip")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#9ca3af"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Text("Your address helps emergency responders find you during a wildfire evacuation.")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .onAppear {
            if let existing = authState.profile?.address, address.isEmpty {
                address = existing
            }
        }
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "LOCATION ACCESS", includeTopSpacing: false)
            VStack(alignment: .leading, spacing: 12) {
                if locationMgr.isGranted {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .foregroundColor(AppColors.primary)
                        Text("Location access enabled")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.primaryLight)
                    }
                } else if locationMgr.isDenied {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Location access denied")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Enable in Settings → Privacy → Location Services → Minutes Matter.")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📍 Allow location access")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("We use your location to detect fires near you and find evacuation routes.")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Button {
                            locationMgr.requestPermission()
                        } label: {
                            Text("Allow Location Access")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
            .padding(16)
            .cardStyle()
        }
    }

    private func save(advance: Bool) async {
        errorMessage = nil
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter your home address to continue."
            return
        }
        guard let uid = authState.currentUserId else {
            errorMessage = "Session error. Please try again."
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await SupabaseService.shared.updateAddress(userId: uid, address: trimmed)
            await authState.refreshProfile()
            if advance { onContinue() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Location permission

final class LocationPermissionManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    var isGranted: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }
}

extension LocationPermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
