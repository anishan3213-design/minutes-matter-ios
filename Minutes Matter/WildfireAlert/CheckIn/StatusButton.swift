//
//  StatusButton.swift
//  Minutes Matter
//

import SwiftUI

struct StatusButton: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let isDanger: Bool
    let action: () -> Void

    private var borderColor: Color {
        if isSelected {
            return isDanger ? AppColors.danger : AppColors.primary
        }
        return AppColors.border
    }

    private var checkTint: Color {
        isSelected ? (isDanger ? AppColors.danger : AppColors.primary) : Color.clear
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Text(emoji)
                    .font(.system(size: 28))
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(checkTint)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
