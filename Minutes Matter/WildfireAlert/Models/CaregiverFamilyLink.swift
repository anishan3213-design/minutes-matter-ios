//
//  CaregiverFamilyLink.swift
//  Minutes Matter
//

import Foundation

/// Row from `profiles.monitored_persons` JSON — same shape the web app uses.
/// Columns of `caregiver_family_links` don't include display info, and RLS blocks
/// caregivers from reading the linked evacuee's profile row directly, so we rely
/// on the caregiver's own `monitored_persons` JSON (written server-side on link).
///
/// Unknown keys are ignored by `JSONDecoder`.
struct CaregiverFamilyLink: Codable, Identifiable, Hashable {
    let id: String
    var fullName: String?
    var name: String?
    var email: String?
    var phone: String?
    var relationship: String?
    var familyRelation: String?
    var mobility: String?
    var address: String?
    var notes: String?
    var homeEvacuationStatus: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case name
        case email
        case phone
        case relationship
        case familyRelation
        case mobility
        case address
        case notes
        case homeEvacuationStatus = "home_evacuation_status"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // `id` may arrive as a UUID string (linked account) or a local id (manual add)
        if let s = try? c.decode(String.self, forKey: .id) {
            id = s
        } else if let u = try? c.decode(UUID.self, forKey: .id) {
            id = u.uuidString
        } else {
            id = UUID().uuidString
        }
        fullName = try? c.decode(String.self, forKey: .fullName)
        name = try? c.decode(String.self, forKey: .name)
        email = try? c.decode(String.self, forKey: .email)
        phone = try? c.decode(String.self, forKey: .phone)
        relationship = try? c.decode(String.self, forKey: .relationship)
        familyRelation = try? c.decode(String.self, forKey: .familyRelation)
        mobility = try? c.decode(String.self, forKey: .mobility)
        address = try? c.decode(String.self, forKey: .address)
        notes = try? c.decode(String.self, forKey: .notes)
        homeEvacuationStatus = try? c.decode(String.self, forKey: .homeEvacuationStatus)
    }

    init(
        id: String,
        fullName: String? = nil,
        name: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        relationship: String? = nil,
        familyRelation: String? = nil,
        mobility: String? = nil,
        address: String? = nil,
        notes: String? = nil,
        homeEvacuationStatus: String? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.name = name
        self.email = email
        self.phone = phone
        self.relationship = relationship
        self.familyRelation = familyRelation
        self.mobility = mobility
        self.address = address
        self.notes = notes
        self.homeEvacuationStatus = homeEvacuationStatus
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
