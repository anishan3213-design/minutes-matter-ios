//
//  ActiveSituationCard.swift
//  Minutes Matter
//

import SwiftUI

struct ActiveSituationCard: View {
    let context: FlameoContext?

    var body: some View {
        Group {
            if context?.status == "address_missing" {
                addressMissingCard
            } else if context?.flags?.hasConfirmedThreat == true {
                threatCard
            } else {
                allClearCard
            }
        }
        .hubCardStyle()
    }

    private var addressMissingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerBand(
                colors: [Color(hex: "#b45309"), Color(hex: "#d97706")],
                title: "📍 Add your address"
            )
            Text("Add your address in Settings to get personalized fire alerts and evacuation routes.")
                .font(.system(size: 16))
                .foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var threatCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerBand(
                colors: [Color(hex: "#b91c1c"), Color(hex: "#ea580c")],
                title: "🔥 Active Fire Nearby"
            )
            if let incident = context?.incidentsNearby?.first {
                Text("\(incident.name ?? "Active Fire") — \(formatMiles(incident.distanceMiles)) mi away")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            } else {
                Text("Active fire detected in your alert area.")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            if let w = context?.weatherSummary {
                if let mph = w.windMph, let dir = w.windDir, !dir.isEmpty {
                    Text("Wind: \(Int(mph.rounded())) mph \(dir)")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                } else if let mph = w.windMph {
                    Text("Wind: \(Int(mph.rounded())) mph")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                if let risk = w.fireRisk, !risk.isEmpty {
                    Text("Fire risk: \(risk)")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    private var allClearCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerBand(
                colors: [Color(hex: "#15803d"), AppColors.primary],
                title: "✅ No active fires near your location"
            )
            if let msg = context?.message, !msg.isEmpty {
                Text(msg)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if context?.flags?.noData == true {
                Text("Fire monitoring is updating. Pull to refresh.")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
            } else {
                Text("You’re clear within your alert radius.")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    private func headerBand(colors: [Color], title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func formatMiles(_ m: Double) -> String {
        String(format: "%.1f", m)
    }
}

#Preview {
    ActiveSituationCard(context: nil)
        .padding()
        .background(AppColors.background)
}
