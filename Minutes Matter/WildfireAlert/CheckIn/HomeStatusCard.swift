//
//  HomeStatusCard.swift
//  Minutes Matter
//

import SwiftUI

struct HomeStatusCard: View {
    @EnvironmentObject private var authState: AuthState
    @ObservedObject var viewModel: CheckInViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "MY HOME STATUS", includeTopSpacing: false)
            Text("Visible to emergency responders")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: 8) {
                StatusButton(
                    emoji: "🏠",
                    label: "Home, not evacuated",
                    isSelected: viewModel.homeStatus == "not_evacuated",
                    isDanger: false
                ) {
                    viewModel.homeStatus = "not_evacuated"
                }

                StatusButton(
                    emoji: "🚗",
                    label: "Evacuated — I left",
                    isSelected: viewModel.homeStatus == "evacuated",
                    isDanger: false
                ) {
                    viewModel.homeStatus = "evacuated"
                }

                StatusButton(
                    emoji: "⚠️",
                    label: "Cannot evacuate — need help",
                    isSelected: viewModel.homeStatus == "cannot_evacuate",
                    isDanger: true
                ) {
                    viewModel.homeStatus = "cannot_evacuate"
                }
            }

            saveHomeButton

            if let err = viewModel.homeErrorMessage {
                Text(err)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .hubCardStyle()
    }

    @ViewBuilder
    private var saveHomeButton: some View {
        Button {
            guard let id = authState.currentUserId else { return }
            Task {
                await viewModel.saveHomeStatus(userId: id, token: nil, auth: authState)
            }
        } label: {
            ZStack {
                if viewModel.isSavingHome {
                    ProgressView()
                        .tint(Color(hex: "#ffffff"))
                } else if viewModel.homeSaveSuccess {
                    Text("✅ Saved")
                } else {
                    Text("Save Home Status")
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.isSavingHome)
        .opacity(viewModel.isSavingHome ? 0.85 : 1)
    }
}
