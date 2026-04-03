//
//  SupabaseService.swift
//  Minutes Matter
//

import Foundation
import Supabase

enum SupabaseConfigurationError: LocalizedError {
    case missingCredentials

    var errorDescription: String? {
        "Add SUPABASE_URL and SUPABASE_ANON_KEY to Info.plist."
    }
}

final class SupabaseService {
    static let shared: SupabaseService = {
        if let url = AppConfig.supabaseURL, let key = AppConfig.supabaseAnonKey {
            return SupabaseService(url: url, supabaseKey: key)
        }
        print("[SupabaseService] WARNING: Missing SUPABASE_URL or SUPABASE_ANON_KEY — using placeholder client.")
        guard let placeholderURL = URL(string: "https://placeholder.supabase.co") else {
            preconditionFailure("Invalid placeholder Supabase URL")
        }
        return SupabaseService(url: placeholderURL, supabaseKey: "placeholder")
    }()

    private let client: SupabaseClient

    private init(url: URL, supabaseKey: String) {
        client = SupabaseClient(supabaseURL: url, supabaseKey: supabaseKey)
    }

    var supabase: SupabaseClient { client }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    /// Sign-up metadata for `profiles` / triggers (`full_name`, `role` e.g. `user`).
    func signUp(email: String, password: String, fullName: String, role: String) async throws -> AuthResponse {
        let data: [String: AnyJSON] = [
            "full_name": .string(fullName),
            "role": .string(role),
        ]
        return try await client.auth.signUp(email: email, password: password, data: data)
    }

    /// Emergency responder sign-up metadata (`emergency_responder` role + roles array).
    func signUpResponder(email: String, password: String, fullName: String) async throws -> AuthResponse {
        let data: [String: AnyJSON] = [
            "full_name": .string(fullName),
            "role": .string("emergency_responder"),
            "roles": .array([.string("emergency_responder")]),
        ]
        return try await client.auth.signUp(email: email, password: password, data: data)
    }

    func upsertResponderProfile(
        userId: UUID,
        fullName: String,
        email: String,
        orgName: String,
        stationAddress: String,
        phone: String?
    ) async throws {
        let row = ResponderProfileUpsert(
            id: userId.uuidString,
            full_name: fullName,
            email: email,
            role: "emergency_responder",
            org_name: orgName,
            address: stationAddress,
            phone: phone,
            roles: ["emergency_responder"]
        )
        try await client.from("profiles").upsert(row).execute()
    }

    /// Single-call responder profile upsert (same payload as `upsertResponderProfile`).
    func createResponderProfile(
        userId: UUID,
        fullName: String,
        email: String,
        orgName: String,
        stationAddress: String,
        phone: String?
    ) async throws {
        try await upsertResponderProfile(
            userId: userId,
            fullName: fullName,
            email: email,
            orgName: orgName,
            stationAddress: stationAddress,
            phone: phone
        )
    }

    func createProfile(userId: UUID, fullName: String, email: String) async throws {
        let row = CreateProfileUpsert(
            id: userId.uuidString,
            full_name: fullName,
            email: email,
            role: "user"
        )
        try await client.from("profiles").upsert(row).execute()
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetPasswordForEmail(_ email: String) async throws {
        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: AppConfig.apiBaseURL
        )
    }

    func fetchProfile(userId: UUID) async throws -> UserProfile {
        try await client
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func getCurrentUser() -> User? {
        client.auth.currentUser
    }

    func fetchCaregiverFamilyLinks(caregiverId: UUID) async throws -> [CaregiverFamilyLink] {
        try await client
            .from("caregiver_family_links")
            .select()
            .eq("caregiver_id", value: caregiverId.uuidString)
            .limit(25)
            .execute()
            .value
    }

    func updateProfileInfo(
        userId: UUID,
        phone: String?,
        emergencyContactName: String?,
        emergencyContactPhone: String?
    ) async throws {
        var o: JSONObject = [:]
        if let phone {
            o["phone"] = .string(phone)
        }
        if let emergencyContactName {
            o["emergency_contact_name"] = .string(emergencyContactName)
        }
        if let emergencyContactPhone {
            o["emergency_contact_phone"] = .string(emergencyContactPhone)
        }
        guard !o.isEmpty else { return }
        try await client
            .from("profiles")
            .update(o)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func updateWorkLocation(
        userId: UUID,
        workAddress: String?,
        workBuildingType: String?,
        workFloorNumber: String?,
        workLocationNote: String?
    ) async throws {
        var o: JSONObject = [:]
        if let workAddress {
            o["work_address"] = .string(workAddress)
        }
        if let workBuildingType {
            o["work_building_type"] = .string(workBuildingType)
        }
        if let workFloorNumber {
            o["work_floor_number"] = .string(workFloorNumber)
        }
        if let workLocationNote {
            o["work_location_note"] = .string(workLocationNote)
        }
        guard !o.isEmpty else { return }
        try await client
            .from("profiles")
            .update(o)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func updateMobilityPreferences(
        userId: UUID,
        communicationNeeds: [String],
        mobilityNeeds: [String],
        disabilityNeeds: [String],
        disabilityOther: String?,
        medicalNeeds: [String],
        medicalOther: String?
    ) async throws {
        let patch = MobilityPreferencesPatch(
            communication_needs: communicationNeeds,
            mobility_needs: mobilityNeeds,
            disability_needs: disabilityNeeds,
            disability_other: disabilityOther,
            medical_needs: medicalNeeds,
            medical_other: medicalOther
        )
        try await client
            .from("profiles")
            .update(patch)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func updateConsents(
        userId: UUID,
        locationConsent: Bool,
        evacuationConsent: Bool,
        healthConsent: Bool
    ) async throws {
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())
        let patch = ConsentsPatch(
            location_sharing_consent: locationConsent,
            evacuation_status_consent: evacuationConsent,
            health_data_consent: healthConsent,
            terms_accepted_at: now,
            responder_data_consent: locationConsent && evacuationConsent
        )
        do {
            try await client
                .from("profiles")
                .update(patch)
                .eq("id", value: userId.uuidString)
                .execute()
            print("[Supabase] consents saved successfully")
        } catch {
            print("[Supabase] consent save error:", error)
            throw error
        }
    }

    func updateHomeEvacuationStatus(userId: UUID, status: String) async throws {
        let ts = ISO8601DateFormatter().string(from: Date())
        let patch = HomeEvacuationStatusPatch(
            home_evacuation_status: status,
            home_status_updated_at: ts
        )
        try await client
            .from("profiles")
            .update(patch)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func updatePersonSafetyStatus(
        userId: UUID,
        status: String?,
        shelterName: String?,
        locationNote: String?
    ) async throws {
        var update: JSONObject = [
            "safety_status_updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        if let status {
            update["person_safety_status"] = .string(status)
        }
        if let shelter = shelterName {
            update["safety_shelter_name"] = .string(shelter)
        }
        if let note = locationNote {
            update["safety_location_note"] = .string(note)
        }
        try await client
            .from("profiles")
            .update(update)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func updateAddress(userId: UUID, address: String) async throws {
        let patch = ProfileAddressPatch(address: address)
        try await client
            .from("profiles")
            .update(patch)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func updateMobilityAndMedical(userId: UUID, mobilityNeeds: [String], medicalNeeds: [String]) async throws {
        let patch = MobilityMedicalPatch(
            mobility_needs: mobilityNeeds,
            medical_needs: medicalNeeds
        )
        try await client
            .from("profiles")
            .update(patch)
            .eq("id", value: userId.uuidString)
            .execute()
    }
}

private struct CreateProfileUpsert: Encodable {
    let id: String
    let full_name: String
    let email: String
    let role: String
}

private struct ResponderProfileUpsert: Encodable {
    let id: String
    let full_name: String
    let email: String
    let role: String
    let org_name: String
    let address: String
    let phone: String?
    let roles: [String]
}

private struct MobilityPreferencesPatch: Encodable {
    let communication_needs: [String]
    let mobility_needs: [String]
    let disability_needs: [String]
    let disability_other: String?
    let medical_needs: [String]
    let medical_other: String?
}

private struct ConsentsPatch: Encodable {
    let location_sharing_consent: Bool
    let evacuation_status_consent: Bool
    let health_data_consent: Bool
    let terms_accepted_at: String
    let responder_data_consent: Bool
}

private struct ProfileAddressPatch: Encodable {
    let address: String
}

private struct MobilityMedicalPatch: Encodable {
    let mobility_needs: [String]
    let medical_needs: [String]
}

private struct HomeEvacuationStatusPatch: Encodable {
    let home_evacuation_status: String
    let home_status_updated_at: String
}
