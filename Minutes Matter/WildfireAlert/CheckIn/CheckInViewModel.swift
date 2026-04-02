//
//  CheckInViewModel.swift
//  Minutes Matter
//

import Combine
import Foundation

@MainActor
final class CheckInViewModel: ObservableObject {
    @Published var homeStatus: String = "not_evacuated"
    @Published var safetyStatus: String?
    @Published var shelterName: String = ""
    @Published var locationNote: String = ""
    @Published var isSavingHome = false
    @Published var isSavingSafety = false
    @Published var homeSaveSuccess = false
    @Published var safetySaveSuccess = false
    @Published var homeErrorMessage: String?
    @Published var safetyErrorMessage: String?

    func load(profile: UserProfile) {
        homeStatus = profile.homeEvacuationStatus ?? "not_evacuated"
        safetyStatus = profile.personSafetyStatus
        shelterName = profile.safetyShelterName ?? ""
        locationNote = profile.safetyLocationNote ?? ""
        homeErrorMessage = nil
        safetyErrorMessage = nil
    }

    func saveHomeStatus(userId: UUID, token _: String?, auth: AuthState) async {
        homeErrorMessage = nil
        isSavingHome = true
        defer { isSavingHome = false }
        do {
            try await SupabaseService.shared.updateHomeEvacuationStatus(userId: userId, status: homeStatus)
            homeSaveSuccess = true
            await auth.checkSession()
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            homeSaveSuccess = false
        } catch {
            homeErrorMessage = "Failed to save. Try again."
        }
    }

    func saveSafetyStatus(userId: UUID, token _: String?, auth: AuthState) async {
        safetyErrorMessage = nil
        isSavingSafety = true
        defer { isSavingSafety = false }
        do {
            try await SupabaseService.shared.updatePersonSafetyStatus(
                userId: userId,
                status: safetyStatus,
                shelterName: shelterName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : shelterName,
                locationNote: locationNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : locationNote
            )
            safetySaveSuccess = true
            await auth.checkSession()
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            safetySaveSuccess = false
        } catch {
            safetyErrorMessage = "Failed to save. Try again."
        }
    }
}
