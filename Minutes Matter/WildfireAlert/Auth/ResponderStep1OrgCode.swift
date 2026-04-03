//
//  ResponderStep1OrgCode.swift
//  Minutes Matter
//

import SwiftUI

struct ResponderStep1OrgCode: View {
    @ObservedObject var draft: ResponderSignupDraft
    var onContinue: () -> Void

    @State private var codeInput = ""
    @State private var isVerifying = false
    @State private var verifySucceeded: Bool?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Emergency Responder Access")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Enter your organization access code provided by your department or agency")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        Text("ℹ️")
                        Text(
                            "This is your organization access code — not a STATION-XXXXXX join code. Your department admin provides this code to authorize responder accounts."
                        )
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#d97706").opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(hex: "#d97706").opacity(0.5), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                TextField("Enter organization code", text: $codeInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .authInputFieldStyle()

                if let verifySucceeded {
                    if verifySucceeded {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("✅ Code verified")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                            Text("You're authorized as an Emergency Responder")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                            Button {
                                onContinue()
                            } label: {
                                Text("Continue")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(AppColors.primary)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("❌ Invalid code")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.danger)
                            Text("Contact your department administrator")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.danger)
                }

                if verifySucceeded != true {
                    Button {
                        Task { await validateCode() }
                    } label: {
                        Group {
                            if isVerifying {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Validate Code")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "#d97706"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isVerifying || codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(20)
        }
    }

    private func validateCode() async {
        let trimmed = codeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return }
        isVerifying = true
        errorMessage = nil
        verifySucceeded = nil
        defer { isVerifying = false }
        let ok = await APIService.shared.verifyInviteCode(
            code: trimmed,
            role: "emergency_responder",
            token: nil
        )
        verifySucceeded = ok
        if ok {
            draft.orgAccessCode = trimmed
            draft.orgCodeVerified = true
        }
    }
}
