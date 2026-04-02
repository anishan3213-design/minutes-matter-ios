//
//  Colors.swift
//  Minutes Matter
//

import SwiftUI

struct AppColors {
    static let primary = Color(hex: "#16a34a")
    static let primaryLight = Color(hex: "#22c55e")
    static let background = Color(hex: "#0f0f0f")
    static let surface = Color(hex: "#1a1a1a")
    static let card = Color(hex: "#242424")
    static let border = Color(hex: "#2a2a2a")
    static let textPrimary = Color(hex: "#ffffff")
    static let textSecondary = Color(hex: "#9ca3af")
    static let textMuted = Color(hex: "#6b7280")
    static let accent = Color(hex: "#d97706")
    static let danger = Color(hex: "#dc2626")
    /// Same as web accent / ember.
    static let warning = Color(hex: "#d97706")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Text {
    /// Prefer `SectionLabel` for new layouts; kept for inline `Text` chains.
    func authSectionLabelStyle() -> some View {
        self
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(AppColors.textMuted)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}
