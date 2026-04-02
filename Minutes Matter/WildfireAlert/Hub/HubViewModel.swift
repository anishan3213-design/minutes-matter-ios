//
//  HubViewModel.swift
//  Minutes Matter
//

import Combine
import Foundation

@MainActor
final class HubViewModel: ObservableObject {
    @Published var context: FlameoContext?
    @Published var people: [CaregiverFamilyLink] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(auth: AuthState) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let token = try await auth.accessToken()
            context = try await APIService.shared.fetchFlameoContext(accessToken: token)
            errorMessage = nil
        } catch {
            if context == nil {
                errorMessage = "Unable to load fire data. Pull to refresh."
            } else {
                errorMessage = "Unable to refresh. Pull to try again."
            }
            return
        }

        if let links = try? await auth.fetchCaregiverFamilyLinks() {
            people = links
        }
    }
}
