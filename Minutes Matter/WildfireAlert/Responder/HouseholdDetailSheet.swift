//
//  HouseholdDetailSheet.swift
//  Minutes Matter
//

import SwiftUI

struct HouseholdDetailSheet: View {
    let household: HouseholdPin
    let onEvacuated: () -> Void
    let onEMS: () -> Void
    let onNoAnswer: () -> Void
    let onNavigate: () -> Void
    let onDismiss: () -> Void

    private var flagChips: [String] {
        household.mobilityFlags + household.medicalFlags
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(hex: "#2a2a2a"))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(household.priority)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#ffffff"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(household.priorityColor)
                                .cornerRadius(4)

                            Text(household.address)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Color(hex: "#ffffff"))

                            Text("\(household.evacuated) of \(household.totalPeople) people evacuated")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#9ca3af"))
                        }
                        Spacer(minLength: 0)
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "#6b7280"))
                        }
                    }

                    if !household.members.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RESIDENTS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "#6b7280"))
                                .tracking(1)

                            ForEach(Array(household.members.enumerated()), id: \.offset) { _, member in
                                MemberRow(member: member)
                            }
                        }
                    }

                    if !flagChips.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NEEDS ATTENTION")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "#6b7280"))
                                .tracking(1)

                            FlowLayout(spacing: 6) {
                                ForEach(flagChips, id: \.self) { flag in
                                    Text(flag)
                                        .font(.system(size: 12))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "#d97706").opacity(0.2))
                                        .foregroundColor(Color(hex: "#d97706"))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }

                    VStack(spacing: 8) {
                        Button(action: onNavigate) {
                            Label("Navigate There", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(hex: "#1d4ed8"))
                                .foregroundColor(Color(hex: "#ffffff"))
                                .cornerRadius(10)
                                .font(.system(size: 16, weight: .semibold))
                        }

                        HStack(spacing: 8) {
                            Button(action: onEvacuated) {
                                Label("Evacuated", systemImage: "checkmark.circle")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: "#16a34a"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .font(.system(size: 14, weight: .semibold))
                            }

                            Button(action: onEMS) {
                                Label("Needs EMS", systemImage: "cross.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: "#dc2626"))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }

                        Button(action: onNoAnswer) {
                            Label("No Answer", systemImage: "house.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "#374151"))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color(hex: "#1a1a1a"))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .frame(maxHeight: UIScreen.main.bounds.height * 0.65)
    }
}

struct MemberRow: View {
    let member: HouseholdMember

    private var statusEmoji: String {
        switch member.homeEvacuationStatus {
        case "evacuated":
            return "🚗"
        case "cannot_evacuate":
            return "⚠️"
        default:
            return "🏠"
        }
    }

    private var telURL: URL? {
        guard let phone = member.phone else { return nil }
        let digits = phone.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel:\(digits)")
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(statusEmoji)
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name ?? "Unknown")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                if let phone = member.phone, let url = telURL {
                    Link(phone, destination: url)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#16a34a"))
                }
            }

            Spacer(minLength: 0)

            if member.homeEvacuationStatus == "cannot_evacuate" {
                Text("PRIORITY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#dc2626"))
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .background(Color(hex: "#242424"))
        .cornerRadius(8)
    }
}
