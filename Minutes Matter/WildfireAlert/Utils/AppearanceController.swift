//
//  AppearanceController.swift
//  Minutes Matter
//

import Combine
import SwiftUI

/// Backed by `UserDefaults` key `wfa_appearance`: `"light"` | `"dark"` | `"system"`.
final class AppearanceController: ObservableObject {
    static let userDefaultsKey = "wfa_appearance"

    @Published var appearance: String {
        didSet {
            UserDefaults.standard.set(appearance, forKey: Self.userDefaultsKey)
        }
    }

    init() {
        appearance = UserDefaults.standard.string(forKey: Self.userDefaultsKey) ?? "dark"
    }

    var colorScheme: ColorScheme? {
        switch appearance {
        case "light":
            return .light
        case "dark":
            return .dark
        case "system":
            return nil
        default:
            return nil
        }
    }
}
