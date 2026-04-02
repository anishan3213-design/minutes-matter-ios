//
//  HouseholdPin.swift
//  Minutes Matter
//

import CoreLocation
import Foundation
import SwiftUI

struct HouseholdMember: Decodable {
    let id: String?
    let name: String?
    let homeEvacuationStatus: String?
    let mobilityNeeds: [String]?
    let medicalNeeds: [String]?
    let disabilityOther: String?
    let medicalOther: String?
    let phone: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case phone
        case homeEvacuationStatus = "home_evacuation_status"
        case mobilityNeeds = "mobility_needs"
        case medicalNeeds = "medical_needs"
        case disabilityOther = "disability_other"
        case medicalOther = "medical_other"
    }
}

struct HouseholdPin: Identifiable, Decodable {
    let id: String
    let address: String
    let lat: Double
    let lng: Double
    let totalPeople: Int
    let evacuated: Int
    let needsHelp: Int
    let notEvacuated: Int
    let priority: String
    let mobilityFlags: [String]
    let medicalFlags: [String]
    let members: [HouseholdMember]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var priorityColor: Color {
        switch priority.uppercased() {
        case "CRITICAL":
            return Color(hex: "#dc2626")
        case "HIGH":
            return Color(hex: "#d97706")
        case "MONITOR":
            return Color(hex: "#eab308")
        default:
            return Color(hex: "#6b7280")
        }
    }

    var evacuationRatio: String {
        "\(evacuated)/\(totalPeople)"
    }

    enum CodingKeys: String, CodingKey {
        case id, address, lat, lng, priority
        case totalPeople = "total_people"
        case evacuated
        case needsHelp = "needs_help"
        case notEvacuated = "not_evacuated"
        case mobilityFlags = "mobility_flags"
        case medicalFlags = "medical_flags"
        case members
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        address = try c.decodeIfPresent(String.self, forKey: .address) ?? ""
        lat = try c.decodeIfPresent(Double.self, forKey: .lat) ?? 0
        lng = try c.decodeIfPresent(Double.self, forKey: .lng) ?? 0
        totalPeople = try c.decodeIfPresent(Int.self, forKey: .totalPeople) ?? 0
        evacuated = try c.decodeIfPresent(Int.self, forKey: .evacuated) ?? 0
        needsHelp = try c.decodeIfPresent(Int.self, forKey: .needsHelp) ?? 0
        notEvacuated = try c.decodeIfPresent(Int.self, forKey: .notEvacuated) ?? 0
        priority = try c.decodeIfPresent(String.self, forKey: .priority) ?? "MONITOR"
        mobilityFlags = try c.decodeIfPresent([String].self, forKey: .mobilityFlags) ?? []
        medicalFlags = try c.decodeIfPresent([String].self, forKey: .medicalFlags) ?? []
        members = try c.decodeIfPresent([HouseholdMember].self, forKey: .members) ?? []
    }
}
