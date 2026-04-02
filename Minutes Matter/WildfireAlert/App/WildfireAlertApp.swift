//
//  WildfireAlertApp.swift
//  Minutes Matter
//

import SwiftUI
import UIKit

@main
struct WildfireAlertApp: App {
    @StateObject private var authState = AuthState()
    @StateObject private var appearance = AppearanceController()

    init() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(red: 26 / 255, green: 26 / 255, blue: 26 / 255, alpha: 1)
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .environmentObject(authState)
                    .environmentObject(appearance)
                    .mmNavigationChrome()
            }
            .preferredColorScheme(appearance.colorScheme)
        }
    }
}
