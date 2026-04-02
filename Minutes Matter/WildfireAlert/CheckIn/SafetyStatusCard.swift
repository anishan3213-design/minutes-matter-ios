//
//  SafetyStatusCard.swift
//  Minutes Matter
//

import Supabase
import SwiftUI

struct SafetyStatusCard: View {
    @EnvironmentObject private var authState: AuthState
    @ObservedObject var viewModel: CheckInViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "MY PERSONAL SAFETY", includeTopSpacing: false)
            Text("Shared with your family")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: 8) {
                StatusButton(
                    emoji: "✅",
                    label: "Safe",
                    isSelected: viewModel.safetyStatus == "safe",
                    isDanger: false
                ) {
                    viewModel.safetyStatus = "safe"
                }

                StatusButton(
                    emoji: "🏥",
                    label: "At a shelter",
                    isSelected: viewModel.safetyStatus == "at_shelter",
                    isDanger: false
                ) {
                    viewModel.safetyStatus = "at_shelter"
                }

                if viewModel.safetyStatus == "at_shelter" {
                    TextField(
                        "",
                        text: $viewModel.shelterName,
                        prompt: Text("Which shelter?").foregroundColor(AppColors.textMuted)
                    )
                    .inputFieldStyle()
                }

                StatusButton(
                    emoji: "📍",
                    label: "Safe elsewhere",
                    isSelected: viewModel.safetyStatus == "safe_elsewhere",
                    isDanger: false
                ) {
                    viewModel.safetyStatus = "safe_elsewhere"
                }

                if viewModel.safetyStatus == "safe_elsewhere" {
                    TextField(
                        "",
                        text: $viewModel.locationNote,
                        prompt: Text("Any details?").foregroundColor(AppColors.textMuted)
                    )
                    .inputFieldStyle()
                }

                StatusButton(
                    emoji: "🆘",
                    label: "Need help",
                    isSelected: viewModel.safetyStatus == "need_help",
                    isDanger: true
                ) {
                    viewModel.safetyStatus = "need_help"
                }
            }

            saveSafetyButton

            if let err = viewModel.safetyErrorMessage {
                Text(err)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .hubCardStyle()
    }

    @ViewBuilder
    private var saveSafetyButton: some View {
        Button {
            guard let id = authState.currentUser?.id else { return }
            Task {
                await viewModel.saveSafetyStatus(userId: id, token: nil, auth: authState)
            }
        } label: {
            ZStack {
                if viewModel.isSavingSafety {
                    ProgressView()
                        .tint(Color(hex: "#ffffff"))
                } else if viewModel.safetySaveSuccess {
                    Text("✅ Saved")
                } else {
                    Text("Save My Safety Status")
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.isSavingSafety)
        .opacity(viewModel.isSavingSafety ? 0.85 : 1)
    }
}
