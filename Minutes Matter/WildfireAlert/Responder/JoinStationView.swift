//
//  JoinStationView.swift
//  Minutes Matter
//

import SwiftUI

struct JoinStationView: View {
    @EnvironmentObject private var authState: AuthState
    @Environment(\.dismiss) private var dismiss

    @State private var codeInput = ""
    @State private var isValidating = false
    @State private var validation: StationInviteValidation?
    @State private var validatedCode = ""
    @State private var isJoining = false
    @State private var joinedName: String?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(hex: "#0f0f0f")
                .ignoresSafeArea()
            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Join a Station")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Enter the STATION-XXXXXX code shared by your incident commander")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)

                TextField("STATION-XXXXXX", text: $codeInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 22, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .authInputFieldStyle()

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.danger)
                }

                if validation?.isValid != true {
                    Button {
                        Task { await validate() }
                    } label: {
                        Group {
                            if isValidating {
                                ProgressView()
                                    .tint(Color(hex: "#ffffff"))
                            } else {
                                Text("Validate Station Code")
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Color(hex: "#d97706")))
                    .disabled(isValidating || codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let v = validation, !isValidating {
                    if v.isValid {
                        successCard(v)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("❌ Invalid or expired code")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.danger)
                            Text("Ask your commander to check the code or generate a new one")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                    }
                }

                if let joinedName {
                    Text("✅ Joined \(joinedName)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(20)
            }
        }
        .navigationTitle("Join station")
        .mmNavigationChrome()
    }

    @ViewBuilder
    private func successCard(_ v: StationInviteValidation) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("✅ Station found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.primary)

            VStack(alignment: .leading, spacing: 8) {
                Text(v.resolvedStationName ?? "Station")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#ffffff"))
                if let inc = v.resolvedIncidentName, !inc.isEmpty {
                    Text(inc)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#9ca3af"))
                }
                Text("You will join this station's field operations")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#6b7280"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()

            Button {
                Task { await joinStation() }
            } label: {
                Group {
                    if isJoining {
                        ProgressView()
                            .tint(Color(hex: "#ffffff"))
                    } else {
                        Text("Join Station")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isJoining)
        }
    }

    private func validate() async {
        let trimmed = codeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return }
        isValidating = true
        errorMessage = nil
        validation = nil
        joinedName = nil
        defer { isValidating = false }
        do {
            let token = try await authState.accessToken()
            let v = try await APIService.shared.validateStationInvite(code: trimmed, token: token)
            validation = v
            if v.isValid {
                validatedCode = trimmed
            }
        } catch {
            errorMessage = error.localizedDescription
            validation = nil
        }
    }

    private func joinStation() async {
        isJoining = true
        defer { isJoining = false }
        do {
            let token = try await authState.accessToken()
            let name = try await APIService.shared.acceptStationInvite(code: validatedCode, token: token)
            joinedName = name
            await authState.refreshProfile()
            try? await Task.sleep(nanoseconds: 600_000_000)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
