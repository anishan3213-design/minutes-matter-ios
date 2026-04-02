//
//  SettingsViewModel.swift
//  Minutes Matter
//

import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isSaving = false
    @Published var errorMessage: String?

    func load(profile: UserProfile) {
        self.profile = profile
        errorMessage = nil
    }

    func saveAddress(userId: UUID, address: String, token _: String?, auth: AuthState) async {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            try await SupabaseService.shared.updateAddress(userId: userId, address: trimmed)
            await auth.checkSession()
        } catch {
            errorMessage = "Could not save address."
        }
    }

    func signOut(auth: AuthState) async {
        await auth.signOut()
    }
}
