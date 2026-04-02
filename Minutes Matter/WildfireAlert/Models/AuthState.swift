//
//  AuthState.swift
//  Minutes Matter
//

import Combine
import Foundation
import Supabase

enum SignUpResult: Sendable {
    case signedIn
    case confirmEmail(address: String)
}

@MainActor
final class AuthState: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?
    @Published private(set) var profile: UserProfile?
    @Published private(set) var isLoading = false
    @Published var configurationError: String?
    /// Authenticated profile is an emergency responder (firefighter) — use dedicated tabs and flows.
    @Published private(set) var isFirefighter = false
    /// Station / department name from profile (`org_name`).
    @Published private(set) var stationName: String?
    /// When non-nil, authenticated user is finishing multi-step signup (steps 2…6).
    @Published private(set) var signupWizardStep: Int?

    private var service: SupabaseService?

    init() {
        do {
            service = try SupabaseService()
        } catch {
            configurationError = error.localizedDescription
            service = nil
        }
    }

    private func wizardStorageKey(userId: UUID) -> String {
        "mm_signup_wizard_step_\(userId.uuidString)"
    }

    func persistSignupWizard(step: Int) {
        guard let uid = currentUser?.id else { return }
        signupWizardStep = step
        UserDefaults.standard.set(step, forKey: wizardStorageKey(userId: uid))
    }

    func completeSignupWizard() {
        if let uid = currentUser?.id {
            UserDefaults.standard.removeObject(forKey: wizardStorageKey(userId: uid))
        }
        signupWizardStep = nil
    }

    func applyRoleFromProfile() {
        guard let p = profile else {
            isFirefighter = false
            stationName = nil
            return
        }
        let er =
            p.role == "emergency_responder"
            || (p.roles?.contains("emergency_responder") == true)
        isFirefighter = er
        stationName = p.orgName
    }

    private func restoreSignupWizardIfNeeded() {
        guard let uid = currentUser?.id else {
            signupWizardStep = nil
            return
        }
        if isFirefighter {
            UserDefaults.standard.removeObject(forKey: wizardStorageKey(userId: uid))
            signupWizardStep = nil
            return
        }
        if profile?.termsAcceptedAt != nil {
            UserDefaults.standard.removeObject(forKey: wizardStorageKey(userId: uid))
            signupWizardStep = nil
            return
        }
        let step = UserDefaults.standard.integer(forKey: wizardStorageKey(userId: uid))
        if step >= 2, step <= 6 {
            signupWizardStep = step
        } else {
            signupWizardStep = nil
        }
    }

    func checkSession() async {
        guard let service else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await service.supabase.auth.session
            currentUser = session.user
            profile = try await service.fetchProfile(userId: session.user.id)
            isAuthenticated = true
            applyRoleFromProfile()
            restoreSignupWizardIfNeeded()
        } catch {
            currentUser = service.getCurrentUser()
            if currentUser != nil {
                isAuthenticated = true
                profile = try? await service.fetchProfile(userId: currentUser!.id)
                applyRoleFromProfile()
                restoreSignupWizardIfNeeded()
            } else {
                isAuthenticated = false
                profile = nil
                signupWizardStep = nil
                isFirefighter = false
                stationName = nil
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        guard let service else { throw SupabaseConfigurationError.missingCredentials }
        try await service.signIn(email: email, password: password)
        let session = try await service.supabase.auth.session
        currentUser = session.user
        profile = try await service.fetchProfile(userId: session.user.id)
        isAuthenticated = true
        applyRoleFromProfile()
        completeSignupWizard()
    }

    /// Step 1: Supabase auth + profile upsert; persists wizard step 2 when session exists.
    func registerNewAccount(email: String, password: String, fullName: String) async throws -> SignUpResult {
        guard let service else { throw SupabaseConfigurationError.missingCredentials }
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let response = try await service.signUp(
            email: trimmedEmail,
            password: password,
            fullName: trimmedName,
            role: "user"
        )
        if let session = response.session {
            currentUser = session.user
            try await service.createProfile(userId: session.user.id, fullName: trimmedName, email: trimmedEmail)
            profile = try await service.fetchProfile(userId: session.user.id)
            isAuthenticated = true
            applyRoleFromProfile()
            persistSignupWizard(step: 2)
            return .signedIn
        }
        currentUser = nil
        profile = nil
        isAuthenticated = false
        signupWizardStep = nil
        return .confirmEmail(address: trimmedEmail)
    }

    func refreshProfile() async {
        guard let service, let uid = currentUser?.id else { return }
        profile = try? await service.fetchProfile(userId: uid)
        applyRoleFromProfile()
    }

    /// Responder signup: Supabase account + profile, then org access code verification on the API.
    func registerResponderAccount(
        email: String,
        password: String,
        fullName: String,
        orgName: String,
        stationAddress: String,
        phone: String?,
        orgAccessCode: String
    ) async throws -> SignUpResult {
        guard let service else { throw SupabaseConfigurationError.missingCredentials }
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let response = try await service.signUpResponder(
            email: trimmedEmail,
            password: password,
            fullName: trimmedName
        )
        if let session = response.session {
            currentUser = session.user
            try await service.upsertResponderProfile(
                userId: session.user.id,
                fullName: trimmedName,
                email: trimmedEmail,
                orgName: orgName,
                stationAddress: stationAddress,
                phone: phone
            )
            profile = try await service.fetchProfile(userId: session.user.id)
            isAuthenticated = true
            applyRoleFromProfile()
            completeSignupWizard()
            let token = session.accessToken
            let inviteOk = try await APIService.shared.verifyInviteCode(
                code: orgAccessCode,
                role: "emergency_responder",
                token: token
            )
            guard inviteOk else {
                throw NSError(
                    domain: "ResponderRegistration",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Organization code could not be applied. Contact your administrator."]
                )
            }
            await refreshProfile()
            return .signedIn
        }
        currentUser = nil
        profile = nil
        isAuthenticated = false
        signupWizardStep = nil
        isFirefighter = false
        stationName = nil
        return .confirmEmail(address: trimmedEmail)
    }

    func signOut() async {
        guard let service else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await service.signOut()
        } catch {
            // Still clear local UI state.
        }
        currentUser = nil
        profile = nil
        isAuthenticated = false
        signupWizardStep = nil
        isFirefighter = false
        stationName = nil
    }

    func accessToken() async throws -> String {
        guard let service else { throw SupabaseConfigurationError.missingCredentials }
        let session = try await service.supabase.auth.session
        return session.accessToken
    }

    func fetchCaregiverFamilyLinks() async throws -> [CaregiverFamilyLink] {
        guard let service, let userId = currentUser?.id else { return [] }
        return try await service.fetchCaregiverFamilyLinks(caregiverId: userId)
    }
}
