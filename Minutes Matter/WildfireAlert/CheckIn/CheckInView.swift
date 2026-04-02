//
//  CheckInView.swift
//  Minutes Matter
//

import Combine
import SwiftUI

struct CheckInView: View {
    @EnvironmentObject private var authState: AuthState
    @StateObject private var viewModel = CheckInViewModel()

    var body: some View {
        ZStack {
            Color(hex: "#0f0f0f")
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    HomeStatusCard(viewModel: viewModel)
                    SafetyStatusCard(viewModel: viewModel)

                    saveConfirmationSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.bottom, 24)
            }
        }
        .onReceive(authState.$profile.compactMap { $0 }) { profile in
            viewModel.load(profile: profile)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Check In")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Text("Update your status so family and responders know you're safe")
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var saveConfirmationSection: some View {
        Group {
            if viewModel.homeSaveSuccess || viewModel.safetySaveSuccess {
                Text("✅ Saved")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#16a34a"))
                .frame(maxWidth: .infinity)
                .cardStyle()
            }
        }
    }
}
