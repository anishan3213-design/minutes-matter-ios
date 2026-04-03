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

    /// Same as `currentUser?.id`; use from views that should not import the Supabase `User` type.
    var currentUserId: UUID? { currentUser?.id }
    @Published private(set) var profile: UserProfile?
    @Published private(set) var isLoading = false
    @Published var configurationError: String?
    /// Authenticated profile is an emergency responder (firefighter) — use dedicated tabs and flows.
    @Published private(set) var isFirefighter = false
    /// Station / department name from profile (`org_name`).
    @Published private(set) var stationName: String?
    /// When non-nil, authenticated user is finishing multi-step signup (steps 2…6).
    @Published private(set) var signupWizardStep: Int?
    /// True while the user is actively completing the post-account signup wizard (steps 1→6). Prevents `ContentView` from swapping the tree to tabs mid-flow.
    @Published private(set) var signupInProgress = false

    private let service = SupabaseService.shared

    init() {
        if AppConfig.supabaseURL == nil || AppConfig.supabaseAnonKey == nil {
            configurationError = SupabaseConfigurationError.missingCredentials.localizedDescription
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

    /// Clears wizard state only (sign-in / responder flows that skip the civilian terms step).
    func completeSignupWizard() {
        print("[Signup] completeSignupWizard (sync clear)")
        if let uid = currentUser?.id {
            UserDefaults.standard.removeObject(forKey: wizardStorageKey(userId: uid))
        }
        signupWizardStep = nil
        signupInProgress = false
    }

    /// Step 6: persist consents, refresh profile, clear wizard so `ContentView` can show `MainTabView`.
    func completeSignupWizardSavingConsentFlags(
        locationConsent: Bool,
        evacuationConsent: Bool,
        healthConsent: Bool
    ) async {
        print("[Auth] completeSignupWizard called")
        print(
            "[Auth] routing state (before):",
            isAuthenticated,
            signupInProgress,
            signupWizardStep ?? -1
        )

        defer {
            signupWizardStep = nil
            signupInProgress = false
            if let u = currentUser?.id {
                UserDefaults.standard.removeObject(forKey: wizardStorageKey(userId: u))
            }
            print("[Auth] wizard cleared, routing to main")
            print(
                "[Auth] routing state (after defer):",
                isAuthenticated,
                signupInProgress,
                signupWizardStep ?? -1
            )
        }

        guard let uid = currentUser?.id else {
            print("[Auth] no currentUser — clearing wizard anyway")
            return
        }

        do {
            try await service.updateConsents(
                userId: uid,
                locationConsent: locationConsent,
                evacuationConsent: evacuationConsent,
                healthConsent: healthConsent
            )
            print("[Auth] consents saved successfully")
        } catch {
            print("[Auth] consent save failed:", error)
        }

        await refreshProfile()
        print("[Auth] signup complete, routing to main")
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
            signupInProgress = false
            return
        }
        if isFirefighter {
            UserDefaults.standard.removeObject(forKey: wizardStorageKey(userId: uid))
            signupWizardStep = nil
            signupInProgress = false
            return
        }
        if profile?.termsAcceptedAt != nil {
            UserDefaults.standard.removeObject(forKey: wizardStorageKey(userId: uid))
            signupWizardStep = nil
            signupInProgress = false
            return
        }
        let step = UserDefaults.standard.integer(forKey: wizardStorageKey(userId: uid))
        if step >= 2, step <= 6 {
            signupWizardStep = step
        } else {
            signupWizardStep = nil
        }
        if signupWizardStep == nil {
            signupInProgress = false
        }
    }

    func checkSession() async {
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
            if let user = currentUser {
                isAuthenticated = true
                profile = try? await service.fetchProfile(userId: user.id)
                applyRoleFromProfile()
                restoreSignupWizardIfNeeded()
            } else {
                isAuthenticated = false
                profile = nil
                signupWizardStep = nil
                signupInProgress = false
                isFirefighter = false
                stationName = nil
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        if configurationError != nil { throw SupabaseConfigurationError.missingCredentials }
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
        if configurationError != nil { throw SupabaseConfigurationError.missingCredentials }
        signupInProgress = true
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
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
            signupInProgress = false
            return .confirmEmail(address: trimmedEmail)
        } catch {
            signupInProgress = false
            throw error
        }
    }

    func refreshProfile() async {
        guard let uid = currentUser?.id else { return }
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
        if configurationError != nil { throw SupabaseConfigurationError.missingCredentials }
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let response = try await service.signUpResponder(
            email: trimmedEmail,
            password: password,
            fullName: trimmedName
        )
        if let session = response.session {
            currentUser = session.user
            try await service.createResponderProfile(
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
            let inviteOk = await APIService.shared.verifyInviteCode(
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
        signupInProgress = false
        isFirefighter = false
        stationName = nil
    }

    func accessToken() async throws -> String {
        if configurationError != nil { throw SupabaseConfigurationError.missingCredentials }
        let session = try await service.supabase.auth.session
        return session.accessToken
    }

    func fetchCaregiverFamilyLinks() async throws -> [CaregiverFamilyLink] {
        guard let userId = currentUser?.id else { return [] }
        return try await service.fetchCaregiverFamilyLinks(caregiverId: userId)
    }
}
