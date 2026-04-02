//
//  PeopleViewModel.swift
//  Minutes Matter
//

import Combine
import Foundation

@MainActor
final class PeopleViewModel: ObservableObject {
    enum InviteStatus: Equatable {
        case idle
        case sending
        case sent(String)
        case failed(String)
    }

    @Published var people: [CaregiverFamilyLink] = []
    @Published var isLoading = false
    @Published var showInviteSheet = false
    @Published var inviteEmail = ""
    @Published var inviteStatus: InviteStatus = .idle
    @Published var errorMessage: String?

    static func isValidInviteEmail(_ raw: String) -> Bool {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.contains("@") && t.contains(".")
    }

    func load(userId: UUID) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            people = try await SupabaseService.shared.fetchCaregiverFamilyLinks(caregiverId: userId)
        } catch {
            errorMessage = "Could not load your people."
        }
    }

    func sendInvite(userId: UUID, token: String?) async {
        let trimmed = inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, Self.isValidInviteEmail(trimmed) else { return }
        inviteStatus = .sending
        do {
            try await APIService.shared.sendFamilyInvite(email: trimmed, token: token)
            inviteStatus = .sent(trimmed)
            inviteEmail = ""
            await load(userId: userId)
        } catch {
            inviteStatus = .failed("Could not send invite. Try again.")
        }
    }

    func resetInviteFlow() {
        inviteStatus = .idle
        inviteEmail = ""
    }
}
