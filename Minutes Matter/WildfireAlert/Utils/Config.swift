//
//  Config.swift
//  Minutes Matter
//

import Foundation

enum AppConfig {
    /// Public Vercel deployment (no secret).
    private static let bundledWebURL: URL = {
        guard let u = URL(string: "https://wildfire-app-layesh1s-projects.vercel.app") else {
            preconditionFailure("Invalid bundled web URL")
        }
        return u
    }()

    static let apiBaseURL = bundledWebURL

    static let termsURL =
        URL(string: "https://wildfire-app-layesh1s-projects.vercel.app/terms") ?? bundledWebURL

    static let privacyURL =
        URL(string: "https://wildfire-app-layesh1s-projects.vercel.app/privacy") ?? bundledWebURL

    // MARK: - Info.plist (client-safe keys only)

    /// Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in the target Info.plist (see repo root `Info.plist`).
    static var supabaseURL: URL? {
        guard let trimmed = infoString("SUPABASE_URL") else { return nil }
        return URL(string: trimmed)
    }

    static var supabaseAnonKey: String? {
        infoString("SUPABASE_ANON_KEY")
    }

    /// Google Places Web Service (autocomplete/details). Prefer `GOOGLE_PLACES_KEY`, else `GOOGLE_PLACES_API_KEY`.
    static var googlePlacesAPIKey: String? {
        if let k = infoString("GOOGLE_PLACES_KEY") { return k }
        if let k = infoString("GOOGLE_PLACES_API_KEY") { return k }
        return nil
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
