//
//  CaregiverFamilyLink.swift
//  Minutes Matter
//

import Foundation

/// Row from `caregiver_family_links`. Column names vary by schema; unknown keys are ignored by `JSONDecoder`.
struct CaregiverFamilyLink: Codable, Identifiable {
    let id: UUID
    var fullName: String?
    var name: String?
    var homeEvacuationStatus: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case name
        case homeEvacuationStatus = "home_evacuation_status"
    }

    var displayName: String {
        if let n = fullName?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty { return n }
        if let n = name?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty { return n }
        return "Family member"
    }

    var evacuationLabel: String {
        switch homeEvacuationStatus {
        case "evacuated":
            return "Evacuated"
        case "cannot_evacuate":
            return "Cannot evacuate"
        case "not_evacuated", nil:
            return "Not evacuated"
        default:
            return homeEvacuationStatus?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Unknown"
        }
    }

    var statusEmoji: String {
        switch homeEvacuationStatus {
        case "evacuated":
            return "🚗"
        case "cannot_evacuate":
            return "⚠️"
        default:
            return "🏠"
        }
    }

    /// Hub / list row: nil or unknown → ❓; explicit DB values use fixed emoji.
    var peopleRowEmoji: String {
        switch homeEvacuationStatus {
        case "not_evacuated":
            return "🏠"
        case "evacuated":
            return "🚗"
        case "cannot_evacuate":
            return "⚠️"
        case nil:
            return "❓"
        default:
            return "❓"
        }
    }
}
