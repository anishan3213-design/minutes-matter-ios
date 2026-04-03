//
//  SignUpStep1Account.swift
//  Minutes Matter
//

import SwiftUI

struct SignUpStep1Account: View {
    @EnvironmentObject private var authState: AuthState

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var onSignedIn: () -> Void
    var onConfirmEmail: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            signUpScreenChrome(
                title: "Create your account",
                subtitle: "Minutes Matter is free — no credit card needed"
            )

            fieldLabel("Full name")
            TextField("", text: $fullName, prompt: Text("Your name").foregroundColor(AppColors.textMuted))
                .textContentType(.name)
                .foregroundColor(AppColors.textPrimary)
                .authInputFieldStyle()

            fieldLabel("Email")
            TextField("", text: $email, prompt: Text("you@example.com").foregroundColor(AppColors.textMuted))
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundColor(AppColors.textPrimary)
                .authInputFieldStyle()

            fieldLabel("Password")
            SecureField("", text: $password, prompt: Text("Password").foregroundColor(AppColors.textMuted))
                .textContentType(.newPassword)
                .foregroundColor(AppColors.textPrimary)
                .authInputFieldStyle()

            fieldLabel("Confirm password")
            SecureField("", text: $confirmPassword, prompt: Text("Confirm password").foregroundColor(AppColors.textMuted))
                .textContentType(.newPassword)
                .foregroundColor(AppColors.textPrimary)
                .authInputFieldStyle()

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.danger)
            }

            Spacer(minLength: 24)

            Button {
                Task { await submit() }
            } label: {
                ZStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(Color(hex: "#ffffff"))
                    } else {
                        Text("Continue")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isSubmitting || !canSubmit)
            .opacity(canSubmit || isSubmitting ? 1 : 0.55)
        }
    }

    private var canSubmit: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !email.isEmpty
            && !password.isEmpty
            && !confirmPassword.isEmpty
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .authSectionLabelStyle()
    }

    private func submit() async {
        errorMessage = nil
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            errorMessage = "Please enter your name."
            return
        }
        let em = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard em.contains("@"), em.contains(".") else {
            errorMessage = "Enter a valid email address."
            return
        }
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
        do {
            let result = try await authState.registerNewAccount(email: em, password: password, fullName: name)
            switch result {
            case .signedIn:
                onSignedIn()
            case let .confirmEmail(address):
                onConfirmEmail(address)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
