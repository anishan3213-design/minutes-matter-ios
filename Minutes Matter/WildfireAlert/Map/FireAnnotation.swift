//
//  FireAnnotation.swift
//  Minutes Matter
//

import SwiftUI

struct FireAnnotation: View {
    let fire: FirePoint
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isSelected {
                    Circle()
                        .stroke(AppColors.primary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
                Circle()
                    .fill(fire.containmentColor)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1)
                    )
            }
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fire.name ?? "Fire")
    }
}
