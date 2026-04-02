//
//  Config.swift
//  Minutes Matter
//

import Foundation

enum AppConfig {
    /// Public Vercel deployment (no secret).
    static let apiBaseURL = URL(string: "https://wildfire-app-layesh1s-projects.vercel.app")!

    static let termsURL = URL(string: "https://wildfire-app-layesh1s-projects.vercel.app/terms")!
    static let privacyURL = URL(string: "https://wildfire-app-layesh1s-projects.vercel.app/privacy")!

    // MARK: - Info.plist (client-safe keys only)

    /// Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in the target Info.plist (see repo root `Info.plist`).
    static var supabaseURL: URL? {
        guard let trimmed = infoString("SUPABASE_URL") else { return nil }
        return URL(string: trimmed)
    }

    static var supabaseAnonKey: String? {
        infoString("SUPABASE_ANON_KEY")
    }

    /// For Places / address features when wired up; restrict keys by bundle ID in Google Cloud.
    static var googlePlacesAPIKey: String? {
        infoString("GOOGLE_PLACES_API_KEY")
    }

    static var googleGeocodingAPIKey: String? {
        infoString("GOOGLE_GEOCODING_API_KEY")
    }

    static var googleRoutesAPIKey: String? {
        infoString("GOOGLE_ROUTES_API_KEY")
    }

    private static func infoString(_ key: String) -> String? {
        let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
