//
//  AssignmentsViewModel.swift
//  Minutes Matter
//

import Combine
import Foundation

@MainActor
final class AssignmentsViewModel: ObservableObject {
    @Published var commandContext: FlameoCommandContext?
    @Published var briefing: String?
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var loadError: String?

    func load(token: String?) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            let ctx = try await APIService.shared.fetchCommandContext(token: token)
            commandContext = ctx
            lastUpdated = Date()
            let brief = try await APIService.shared.fetchCommandBriefing(context: ctx, token: token)
            briefing = brief
        } catch {
            loadError = error.localizedDescription
        }
    }

    var topAssignments: [PriorityAssignment] {
        guard let list = commandContext?.priorityAssignments else { return [] }
        return Array(list.sorted { $0.rank < $1.rank }.prefix(5))
    }

    func normalizedCompletionRate(_ summary: IncidentSummary) -> Double {
        guard let r = summary.completionRate else { return 0 }
        return r > 1 ? r / 100 : r
    }
}
