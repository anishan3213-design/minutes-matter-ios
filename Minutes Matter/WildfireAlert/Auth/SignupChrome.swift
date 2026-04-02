//
//  SignupChrome.swift
//  Minutes Matter
//

import SwiftUI

/// Title + subtitle only; step ribbon lives in `SignUpFlowView`.
func signUpScreenChrome(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(AppColors.textPrimary)
        Text(subtitle)
            .font(.system(size: 16))
            .foregroundColor(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
