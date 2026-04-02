//
//  SignUpStep6Terms.swift
//  Minutes Matter
//

import Supabase
import SwiftUI

struct SignUpStep6Terms: View {
    @EnvironmentObject private var authState: AuthState

    @State private var consentLocation = false
    @State private var consentEvacuation = false
    @State private var consentHealth = false
    @State private var validationMessage: String?
    @State private var isSaving = false

    var onComplete: () -> Void

    private var allChecked: Bool {
        consentLocation && consentEvacuation && consentHealth
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            signUpScreenChrome(
                title: "Before you continue",
                subtitle: "Please review and agree to use Minutes Matter"
            )

            hipaaCard

            ConsentCheckbox(
                text: "I agree that my home address and general location will be shared with emergency responders during an active wildfire incident.",
                isChecked: $consentLocation,
                linkText: "View Terms of Service →",
                linkURL: AppConfig.termsURL
            )

            ConsentCheckbox(
                text: "I agree that my evacuation status will be visible to emergency responders during an active incident.",
                isChecked: $consentEvacuation
            )

            ConsentCheckbox(
                text: "I agree that any health or mobility information I choose to share will be visible to emergency responders to help them assist me safely.",
                isChecked: $consentHealth
            )

            termsFooter

            if let validationMessage {
                Text(validationMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.danger)
            }

                Button {
                    Task { await submit() }
                } label: {
                    ZStack {
                        if isSaving {
                            ProgressView()
                                .tint(Color(hex: "#ffffff"))
                        } else {
                            Text("Create Account")
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!allChecked || isSaving)
                .opacity(allChecked ? 1 : 0.45)
            .padding(.bottom, 32)
        }
    }

    private var hipaaCard: some View {
        Text("🔒 Your health information is encrypted and only shared with emergency responders during active incidents. You control what you share.")
            .font(.system(size: 15))
            .foregroundColor(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var termsFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By creating your account you agree to our")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 6) {
                Link("Terms of Service", destination: AppConfig.termsURL)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                Text("and")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                Link("Privacy Policy", destination: AppConfig.privacyURL)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primary)
            }
        }
    }

    private func submit() async {
        validationMessage = nil
        guard allChecked else {
            validationMessage = "Please agree to all terms to continue"
            return
        }
        guard let uid = authState.currentUser?.id else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await SupabaseService.shared.updateConsents(
                userId: uid,
                locationConsent: true,
                evacuationConsent: true,
                healthConsent: true
            )
            await authState.refreshProfile()
            authState.completeSignupWizard()
            onComplete()
        } catch {
            validationMessage = error.localizedDescription
        }
    }
}
