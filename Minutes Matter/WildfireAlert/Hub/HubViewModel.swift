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
        errorMessage = nil

        let token: String?
        do {
            token = try await auth.accessToken()
        } catch {
            #if DEBUG
            print("[Hub] accessToken failed — still attempting Flameo request:", error)
            #endif
            token = nil
        }

        #if DEBUG
        print("[Hub] Loading flameo context")
        print("[Hub] Has token:", token != nil)
        print("[Hub] Profile address:", auth.profile?.address ?? "none")
        #endif

        do {
            let ctx = try await APIService.shared.fetchFlameoContext(accessToken: token)
            context = ctx
            #if DEBUG
            print("[Hub] Status:", ctx.status ?? "nil")
            print("[Hub] Threat:", ctx.flags?.hasConfirmedThreat ?? false)
            print("[Hub] Incidents:", ctx.incidentsNearby?.count ?? 0)
            print("[Hub] Shelters:", ctx.sheltersRanked?.count ?? 0)
            print("[Hub] Hazards:", ctx.hazardSitesNearby?.count ?? 0)
            #endif
        } catch {
            #if DEBUG
            print("[Hub] Flameo error:", error)
            #endif
            errorMessage = "Unable to load fire data. Pull to refresh."
        }

        if let uid = auth.currentUserId {
            do {
                people = try await SupabaseService.shared.fetchCaregiverFamilyLinks(caregiverId: uid)
                #if DEBUG
                print("[Hub] People:", people.count)
                #endif
            } catch {
                #if DEBUG
                print("[Hub] People error:", error)
                #endif
            }
        }

        isLoading = false
    }
}
