//
//  PersonRowView.swift
//  Minutes Matter
//

import SwiftUI

struct PersonRowView: View {
    let person: CaregiverFamilyLink

    private var isEvacuated: Bool {
        person.homeEvacuationStatus == "evacuated"
    }

    private var needsHelp: Bool {
        person.homeEvacuationStatus == "cannot_evacuate"
    }

    var body: some View {
        HStack(spacing: 0) {
            if needsHelp {
                Rectangle()
                    .fill(AppColors.danger)
                    .frame(width: 4)
            }

            HStack(alignment: .center, spacing: 14) {
                Text(person.peopleRowEmoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(person.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text(person.evacuationLabel)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                    if needsHelp {
                        Text("⚠️ Needs help")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.danger)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textMuted)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                AppColors.card
                if isEvacuated {
                    AppColors.primary.opacity(0.12)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var borderColor: Color {
        if needsHelp {
            return AppColors.danger.opacity(0.85)
        }
        if isEvacuated {
            return AppColors.primary.opacity(0.45)
        }
        return AppColors.border
    }
}
