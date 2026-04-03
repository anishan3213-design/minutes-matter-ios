//
//  ShelterRouteCard.swift
//  Minutes Matter
//

import SwiftUI

struct ShelterRouteCard: View {
    let shelter: FlameoShelter
    let onOpenMaps: () -> Void
    var onSeeAllShelters: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECOMMENDED SHELTER")
                .authSectionLabelStyle()

            Text(shelter.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            if let minutes = shelter.travelMinutes {
                Text("About \(Int(minutes.rounded())) min")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
            } else if let mi = shelter.distanceMiles {
                Text(String(format: "%.1f mi", mi))
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
            }

            if let summary = shelter.routeSummary, !summary.isEmpty {
                Text("via \(summary)")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if shelter.routeAvoidsFire == true {
                Label("Route avoids fire", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.primaryLight)
            } else if shelter.routeAvoidsFire == false {
                Label("Near fire zone", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.warning)
            }

            if shelter.verified == true {
                Text("Verified shelter")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.primaryLight)
            }

            HStack(spacing: 12) {
                Button(action: onOpenMaps) {
                    Text("🗺  Get Directions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Button {
                    onSeeAllShelters?()
                } label: {
                    Text("See all shelters →")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(AppColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .hubCardStyle()
    }
}
