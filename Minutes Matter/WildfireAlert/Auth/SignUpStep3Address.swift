//
//  SignUpStep3Address.swift
//  Minutes Matter
//

import CoreLocation
import Supabase
import SwiftUI

struct SignUpStep3Address: View {
    @EnvironmentObject private var authState: AuthState
    @StateObject private var locationHelper = SignUpLocationHelper()

    @State private var address = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var onContinue: () -> Void
    var onSkip: () -> Void

    private var locationGranted: Bool {
        locationHelper.authorizationStatus == .authorizedAlways
            || locationHelper.authorizationStatus == .authorizedWhenInUse
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            signUpScreenChrome(
                title: "Where is your home?",
                subtitle: "Emergency responders use this for door-to-door safety checks"
            )

            TextField(
                "",
                text: $address,
                prompt: Text("123 Main St, City, State").foregroundColor(AppColors.textMuted)
            )
            .textContentType(.fullStreetAddress)
            .inputFieldMultilineStyle(minHeight: 120)

            Text("Enter your full street address")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textMuted)

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
        }
        .onAppear {
            if let existing = authState.profile?.homeAddress, address.isEmpty {
                address = existing
            }
        }
    }

    private var canContinue: Bool {
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("📍")
                    .font(.system(size: 24))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Allow location access")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("We use your location to detect fires near you and find evacuation routes.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if locationGranted {
                Text("✅ Location access granted")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.primaryLight)
            } else {
                Button {
                    locationHelper.requestWhenInUse()
                } label: {
                    Text("Allow Location Access")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .cardStyle()
    }

    private func save(advance: Bool) async {
        errorMessage = nil
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter your home address to continue."
            return
        }
        guard let uid = authState.currentUser?.id else { return }
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
