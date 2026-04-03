//
//  UserProfile.swift
//  Minutes Matter
//

import Foundation

struct UserProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var fullName: String?
    var email: String?
    var role: String?
    /// App-specific roles list when present (e.g. emergency responder).
    var roles: [String]?
    /// Station / department display name.
    var orgName: String?
    /// Home address (civilians) or station / command address (responders); DB column `address`.
    var address: String?
    var phone: String?
    var workAddress: String?
    var workBuildingType: String?
    var workFloorNumber: String?
    var workLocationNote: String?
    var homeEvacuationStatus: String?
    var personSafetyStatus: String?
    var communicationNeeds: [String]?
    var mobilityNeeds: [String]?
    var disabilityNeeds: [String]?
    var disabilityOther: String?
    var medicalNeeds: [String]?
    var medicalOther: String?
    var emergencyContactName: String?
    var emergencyContactPhone: String?
    var locationSharingConsent: Bool?
    var evacuationStatusConsent: Bool?
    var healthDataConsent: Bool?
    var termsAcceptedAt: String?
    var safetyShelterName: String?
    var safetyLocationNote: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case role
        case roles
        case orgName = "org_name"
        case address
        case phone
        case workAddress = "work_address"
        case workBuildingType = "work_building_type"
        case workFloorNumber = "work_floor_number"
        case workLocationNote = "work_location_note"
        case homeEvacuationStatus = "home_evacuation_status"
        case personSafetyStatus = "person_safety_status"
        case communicationNeeds = "communication_needs"
        case mobilityNeeds = "mobility_needs"
        case disabilityNeeds = "disability_needs"
        case disabilityOther = "disability_other"
        case medicalNeeds = "medical_needs"
        case medicalOther = "medical_other"
        case emergencyContactName = "emergency_contact_name"
        case emergencyContactPhone = "emergency_contact_phone"
        case locationSharingConsent = "location_sharing_consent"
        case evacuationStatusConsent = "evacuation_status_consent"
        case healthDataConsent = "health_data_consent"
        case termsAcceptedAt = "terms_accepted_at"
        case safetyShelterName = "safety_shelter_name"
        case safetyLocationNote = "safety_location_note"
    }
}
