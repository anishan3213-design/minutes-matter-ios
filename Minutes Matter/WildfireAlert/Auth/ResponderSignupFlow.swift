//
//  ResponderSignupFlow.swift
//  Minutes Matter
//

import SwiftUI

struct ResponderSignupFlow: View {
    @EnvironmentObject private var authState: AuthState
    @StateObject private var draft = ResponderSignupDraft()
    @State private var step = 1

    var body: some View {
        VStack(spacing: 0) {
            Text("Step \(step) of 3")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppColors.surface)

            Group {
                switch step {
                case 1:
                    ResponderStep1OrgCode(draft: draft) {
                        step = 2
                    }
                case 2:
                    ResponderStep2StationInfo(draft: draft) {
                        step = 3
                    }
                case 3:
                    ResponderStep3Account(draft: draft)
                        .environmentObject(authState)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hex: "#0f0f0f").ignoresSafeArea())
        .navigationTitle("Responder Sign Up")
        .mmNavigationChrome()
    }
}
