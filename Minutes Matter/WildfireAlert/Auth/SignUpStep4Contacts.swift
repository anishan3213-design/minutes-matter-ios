//
//  SignUpStep4Contacts.swift
//  Minutes Matter
//

import SwiftUI

struct SignUpStep4Contacts: View {
    @EnvironmentObject private var authState: AuthState

    @State private var phone = ""
    @State private var emergencyName = ""
    @State private var emergencyPhone = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var onContinue: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            signUpScreenChrome(
                title: "Emergency contacts",
                subtitle: "Optional — who should we contact in an emergency?"
            )

            fieldLabel("Phone number (optional)")
            TextField("", text: $phone, prompt: Text("+1 (555) 000-0000").foregroundColor(AppColors.textMuted))
                .keyboardType(.phonePad)
                .foregroundColor(AppColors.textPrimary)
                .authInputFieldStyle()

            fieldLabel("Emergency contact name (optional)")
            TextField("", text: $emergencyName, prompt: Text("Contact name").foregroundColor(AppColors.textMuted))
                .foregroundColor(AppColors.textPrimary)
                .authInputFieldStyle()

            fieldLabel("Emergency contact phone (optional)")
            TextField("", text: $emergencyPhone, prompt: Text("Contact phone").foregroundColor(AppColors.textMuted))
                .keyboardType(.phonePad)
                .foregroundColor(AppColors.textPrimary)
                .authInputFieldStyle()

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
            .disabled(isSaving)

            Button {
                onSkip()
            } label: {
                Text("Skip for now")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#9ca3af"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .authSectionLabelStyle()
    }

    private func save(advance: Bool) async {
        errorMessage = nil
        guard let uid = authState.currentUserId else {
            errorMessage = "Session error. Please try again."
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            let p = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            let en = emergencyName.trimmingCharacters(in: .whitespacesAndNewlines)
            let ep = emergencyPhone.trimmingCharacters(in: .whitespacesAndNewlines)
            try await SupabaseService.shared.updateProfileInfo(
                userId: uid,
                phone: p.isEmpty ? nil : p,
                emergencyContactName: en.isEmpty ? nil : en,
                emergencyContactPhone: ep.isEmpty ? nil : ep
            )
            await authState.refreshProfile()
            if advance { onContinue() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
