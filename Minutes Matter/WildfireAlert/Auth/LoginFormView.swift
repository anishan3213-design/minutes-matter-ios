//
//  LoginFormView.swift
//  Minutes Matter
//

import SwiftUI

struct LoginFormView: View {
    @EnvironmentObject private var authState: AuthState
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isSigningIn = false
    @State private var isSendingReset = false

    var body: some View {
        ZStack {
            Color(hex: "#0f0f0f")
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Minutes Matter")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "#ffffff"))
                        .padding(.top, 8)

                    Text("Sign in to your account")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#9ca3af"))

                    if let configError = authState.configurationError {
                        Text(configError)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#dc2626"))
                    }

                    fieldLabel("Email")
                    TextField("", text: $email, prompt: Text("you@example.com").foregroundColor(Color(hex: "#6b7280")))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .inputFieldStyle()

                    fieldLabel("Password")
                    SecureField("", text: $password, prompt: Text("Password").foregroundColor(Color(hex: "#6b7280")))
                        .textContentType(.password)
                        .inputFieldStyle()

                    Button {
                        Task { await sendPasswordReset() }
                    } label: {
                        if isSendingReset {
                            ProgressView()
                                .scaleEffect(0.85)
                                .tint(Color(hex: "#6b7280"))
                        } else {
                            Text("Forgot password?")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#6b7280"))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isSendingReset)

                    Button {
                        Task { await signIn() }
                    } label: {
                        ZStack {
                            if isSigningIn {
                                ProgressView()
                                    .tint(Color(hex: "#ffffff"))
                            } else {
                                Text("Sign In")
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isSigningIn || email.isEmpty || password.isEmpty)
                    .opacity((email.isEmpty || password.isEmpty) && !isSigningIn ? 0.55 : 1)

                    if let successMessage {
                        Text(successMessage)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#16a34a"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#dc2626"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    NavigationLink {
                        SignUpFlowView(isResumeWizard: false)
                            .environmentObject(authState)
                    } label: {
                        Text("Create account")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#16a34a"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
        }
        .navigationTitle("Sign in")
        .mmNavigationChrome()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    dismiss()
                }
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#16a34a"))
            }
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(hex: "#6b7280"))
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private func signIn() async {
        errorMessage = nil
        successMessage = nil
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            try await authState.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sendPasswordReset() async {
        errorMessage = nil
        successMessage = nil
        let addr = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !addr.isEmpty else {
            errorMessage = "Enter your email first"
            return
        }
        if let configError = authState.configurationError {
            errorMessage = configError
            return
        }
        isSendingReset = true
        defer { isSendingReset = false }
        do {
            try await SupabaseService.shared.resetPasswordForEmail(addr)
            successMessage = "Check your email for a reset link"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        LoginFormView()
            .environmentObject(AuthState())
    }
}
