//
//  ChipView.swift
//  Minutes Matter
//

import SwiftUI

struct ChipView: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary.opacity(0.2) : AppColors.surface)
                .foregroundColor(isSelected ? AppColors.primary : AppColors.textPrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
