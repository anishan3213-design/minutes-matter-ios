//
//  ResponderStep3Account.swift
//  Minutes Matter
//

import SwiftUI

struct ResponderStep3Account: View {
    @ObservedObject var draft: ResponderSignupDraft
    @EnvironmentObject private var authState: AuthState

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showConfirmEmail = false
    @State private var pendingEmail = ""

    private var canSubmit: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && password.count >= 8
            && password == confirmPassword
            && draft.orgCodeVerified
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Create Your Account")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Set up your login credentials")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)

                Text("Full name")
                    .authSectionLabelStyle()
                TextField("Full name", text: $fullName)
                    .authInputFieldStyle()

                Text("Email")
                    .authSectionLabelStyle()
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .authInputFieldStyle()

                Text("Password (8+ characters)")
                    .authSectionLabelStyle()
                SecureField("Password", text: $password)
                    .authInputFieldStyle()

                Text("Confirm password")
                    .authSectionLabelStyle()
                SecureField("Confirm password", text: $confirmPassword)
                    .authInputFieldStyle()

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.danger)
                }

                Button {
                    Task { await submit() }
                } label: {
                    Group {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Responder Account")
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
                .disabled(!canSubmit || isSubmitting)

                Text(
                    "After signup, your commander can share a STATION-XXXXXX code to join their station in Settings."
                )
                .font(.system(size: 13))
                .foregroundColor(AppColors.textMuted)
            }
            .padding(20)
        }
        .alert("Check your email", isPresented: $showConfirmEmail) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("We sent a confirmation link to \(pendingEmail).")
        }
    }

    private func submit() async {
        errorMessage = nil
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        let phoneOpt: String? = {
            let p = draft.phone.trimmingCharacters(in: .whitespacesAndNewlines)
            return p.isEmpty ? nil : p
        }()
        do {
            let result = try await authState.registerResponderAccount(
                email: email,
                password: password,
                fullName: fullName,
                orgName: draft.stationName.trimmingCharacters(in: .whitespacesAndNewlines),
                stationAddress: draft.stationAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phoneOpt,
                orgAccessCode: draft.orgAccessCode
            )
            switch result {
            case .signedIn:
                break
            case let .confirmEmail(address):
                pendingEmail = address
                showConfirmEmail = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
