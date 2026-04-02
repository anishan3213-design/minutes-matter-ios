//
//  FlameoSituationView.swift
//  Minutes Matter
//

import SwiftUI

struct FlameoSituationView: View {
    @Environment(\.dismiss) private var dismiss
    let context: FlameoContext?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0f0f0f")
                    .ignoresSafeArea()
                if context == nil {
                    Text("No situation data. Pull to refresh on the Hub.")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let role = context?.role, !role.isEmpty {
                                situationSection(title: "YOUR ROLE", body: role.replacingOccurrences(of: "_", with: " ").capitalized)
                            }
                            if let anchors = context?.anchors, !anchors.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("LOCATIONS")
                                        .authSectionLabelStyle()
                                    ForEach(anchors, id: \.id) { a in
                                        Text("• \(a.label)")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "#ffffff"))
                                    }
                                }
                                .hubCardStyle()
                            }
                            if let incidents = context?.incidentsNearby, !incidents.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("NEARBY INCIDENTS")
                                        .authSectionLabelStyle()
                                    ForEach(incidents, id: \.id) { i in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(i.name ?? "Fire")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(Color(hex: "#ffffff"))
                                            Text(String(format: "%.1f mi · %@", i.distanceMiles, i.source ?? "Unknown source"))
                                                .font(.system(size: 14))
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                }
                                .hubCardStyle()
                            }
                            if let w = context?.weatherSummary {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("WEATHER")
                                        .authSectionLabelStyle()
                                    if let t = w.tempF {
                                        Text("Temp: \(Int(t.rounded()))°F")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "#ffffff"))
                                    }
                                    if let mph = w.windMph {
                                        Text("Wind: \(Int(mph.rounded())) mph \(w.windDir ?? "")")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "#ffffff"))
                                    }
                                    if let r = w.fireRisk, !r.isEmpty {
                                        Text("Fire risk: \(r)")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "#ffffff"))
                                    }
                                }
                                .hubCardStyle()
                            }
                            if let hz = context?.hazardSitesNearby, !hz.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("HAZARDS")
                                        .authSectionLabelStyle()
                                    ForEach(hz, id: \.id) { h in
                                        Text("• \(h.name) (\(h.type)) — \(String(format: "%.1f", h.distanceMiles)) mi")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(hex: "#ffffff"))
                                    }
                                }
                                .hubCardStyle()
                            }
                            if let shelters = context?.sheltersRanked, !shelters.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("SHELTERS (ranked)")
                                        .authSectionLabelStyle()
                                    Text("\(shelters.count) shelter(s) in context.")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .hubCardStyle()
                            }
                            if let msg = context?.message, !msg.isEmpty {
                                situationSection(title: "STATUS", body: msg)
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Flameo")
            .mmNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#16a34a"))
                }
            }
        }
    }

    private func situationSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .authSectionLabelStyle()
            Text(body)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#ffffff"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .hubCardStyle()
    }
}

#Preview {
    FlameoSituationView(context: nil)
}
