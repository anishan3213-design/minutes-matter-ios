//
//  HouseholdAnnotation.swift
//  Minutes Matter
//

import SwiftUI

struct HouseholdAnnotation: View {
    let household: HouseholdPin
    let isSelected: Bool

    @State private var criticalShadowRadius: CGFloat = 4

    private var size: CGFloat { isSelected ? 50 : 38 }

    private var isCritical: Bool {
        household.priority.uppercased() == "CRITICAL"
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(household.priorityColor)
                    .frame(width: size, height: size)
                    .shadow(
                        color: household.priorityColor.opacity(isCritical ? 0.85 : 0.5),
                        radius: isCritical ? criticalShadowRadius : (isSelected ? 8 : 4)
                    )

                VStack(spacing: 0) {
                    Text(household.evacuationRatio)
                        .font(.system(size: isSelected ? 14 : 12, weight: .bold))
                        .foregroundColor(Color(hex: "#ffffff"))

                    if !household.mobilityFlags.isEmpty {
                        Text("♿")
                            .font(.system(size: 12))
                    }
                }
            }
            .onAppear {
                guard isCritical else { return }
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    criticalShadowRadius = 14
                }
            }

            if isSelected {
                Text(household.priority)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(household.priorityColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: "#1a1a1a"))
                    .cornerRadius(4)
            }
        }
    }
}
