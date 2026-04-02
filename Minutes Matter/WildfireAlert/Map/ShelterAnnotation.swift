//
//  ShelterAnnotation.swift
//  Minutes Matter
//

import SwiftUI

struct ShelterAnnotation: View {
    let shelter: ShelterPoint
    let isSelected: Bool
    let onTap: () -> Void

    private var fillColor: Color {
        shelter.verified == true ? AppColors.primary : AppColors.textMuted
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isSelected {
                    Circle()
                        .stroke(AppColors.primaryLight, lineWidth: 2)
                        .frame(width: 32, height: 32)
                }
                Circle()
                    .fill(fillColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1)
                    )
                Text("♥")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(shelter.name)
    }
}
