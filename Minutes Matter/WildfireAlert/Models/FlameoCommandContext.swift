//
//  FlameoCommandContext.swift
//  Minutes Matter
//

import Foundation
import SwiftUI

struct FlameoCommandContext: Codable {
    var incidentSummary: IncidentSummary?
    var priorityAssignments: [PriorityAssignment]?
    var fireContext: FireContext?
    var fieldUnitsReporting: [FieldUnit]?
    var fieldUnitsWithoutPositionCount: Int?

    enum CodingKeys: String, CodingKey {
        case incidentSummary = "incident_summary"
        case priorityAssignments = "priority_assignments"
        case fireContext = "fire_context"
        case fieldUnitsReporting = "field_units_reporting"
        case fieldUnitsWithoutPositionCount = "field_units_without_position_count"
    }
}

struct IncidentSummary: Codable {
    var totalHouseholds: Int?
    var totalPeople: Int?
    var evacuated: Int?
    var needsHelp: Int?
    var completionRate: Double?

    enum CodingKeys: String, CodingKey {
        case totalHouseholds = "total_households"
        case totalPeople = "total_people"
        case evacuated
        case needsHelp = "needs_help"
        case completionRate = "completion_rate"
    }
}

struct PriorityAssignment: Codable, Identifiable {
    var rank: Int
    var address: String
    var lat: Double?
    var lng: Double?
    var reason: String?
    var actionRequired: String?
    var peopleCount: Int?
    var cannotEvacuateCount: Int?
    var mobilityFlags: [String]?
    var medicalFlags: [String]?
    var assignedTo: String?
    var targetUserId: String?

    var id: String { "\(rank)-\(address)" }

    var actionColor: Color {
        switch actionRequired?.uppercased() {
        case "EMS":
            return Color(hex: "#dc2626")
        case "TRANSPORT":
            return Color(hex: "#d97706")
        case "CHECK":
            return Color(hex: "#eab308")
        default:
            return Color(hex: "#6b7280")
        }
    }

    var actionLabel: String {
        switch actionRequired?.uppercased() {
        case "EMS":
            return "🚑 EMS Required"
        case "TRANSPORT":
            return "🚗 Transport Needed"
        case "CHECK":
            return "🏠 Check On Resident"
        default:
            return "✓ Clear"
        }
    }

    enum CodingKeys: String, CodingKey {
        case rank, address, lat, lng, reason
        case actionRequired = "action_required"
        case peopleCount = "people_count"
        case cannotEvacuateCount = "cannot_evacuate_count"
        case mobilityFlags = "mobility_flags"
        case medicalFlags = "medical_flags"
        case assignedTo = "assigned_to"
        case targetUserId = "target_user_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rank = try c.decodeIfPresent(Int.self, forKey: .rank) ?? 0
        address = try c.decodeIfPresent(String.self, forKey: .address) ?? ""
        lat = try c.decodeIfPresent(Double.self, forKey: .lat)
        lng = try c.decodeIfPresent(Double.self, forKey: .lng)
        reason = try c.decodeIfPresent(String.self, forKey: .reason)
        actionRequired = try c.decodeIfPresent(String.self, forKey: .actionRequired)
        peopleCount = try c.decodeIfPresent(Int.self, forKey: .peopleCount)
        cannotEvacuateCount = try c.decodeIfPresent(Int.self, forKey: .cannotEvacuateCount)
        mobilityFlags = try c.decodeIfPresent([String].self, forKey: .mobilityFlags)
        medicalFlags = try c.decodeIfPresent([String].self, forKey: .medicalFlags)
        assignedTo = try c.decodeIfPresent(String.self, forKey: .assignedTo)
        targetUserId = try c.decodeIfPresent(String.self, forKey: .targetUserId)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(rank, forKey: .rank)
        try c.encode(address, forKey: .address)
        try c.encodeIfPresent(lat, forKey: .lat)
        try c.encodeIfPresent(lng, forKey: .lng)
        try c.encodeIfPresent(reason, forKey: .reason)
        try c.encodeIfPresent(actionRequired, forKey: .actionRequired)
        try c.encodeIfPresent(peopleCount, forKey: .peopleCount)
        try c.encodeIfPresent(cannotEvacuateCount, forKey: .cannotEvacuateCount)
        try c.encodeIfPresent(mobilityFlags, forKey: .mobilityFlags)
        try c.encodeIfPresent(medicalFlags, forKey: .medicalFlags)
        try c.encodeIfPresent(assignedTo, forKey: .assignedTo)
        try c.encodeIfPresent(targetUserId, forKey: .targetUserId)
    }
}

struct FieldUnit: Codable, Identifiable {
    let id: String
    var name: String?
    var lat: Double?
    var lng: Double?
    var status: String?
    var assignment: String?
    var lastSeenAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, lat, lng, status, assignment
        case lastSeenAt = "last_seen_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try c.decodeIfPresent(String.self, forKey: .name)
        lat = try c.decodeIfPresent(Double.self, forKey: .lat)
        lng = try c.decodeIfPresent(Double.self, forKey: .lng)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        assignment = try c.decodeIfPresent(String.self, forKey: .assignment)
        lastSeenAt = try c.decodeIfPresent(String.self, forKey: .lastSeenAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(lat, forKey: .lat)
        try c.encodeIfPresent(lng, forKey: .lng)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(assignment, forKey: .assignment)
        try c.encodeIfPresent(lastSeenAt, forKey: .lastSeenAt)
    }
}

struct FireContext: Codable {
    var nearestFireMiles: Double?
    var windDir: String?
    var windMph: Double?
    var fireRisk: String?

    enum CodingKeys: String, CodingKey {
        case nearestFireMiles = "nearest_fire_miles"
        case windDir = "wind_dir"
        case windMph = "wind_mph"
        case fireRisk = "fire_risk"
    }
}
