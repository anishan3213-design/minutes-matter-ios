//
//  FirefighterTabView.swift
//  Minutes Matter
//

import SwiftUI
import UIKit

private enum FirefighterTab: Hashable {
    case fieldMap
    case assignments
    case settings
}

struct FirefighterTabView: View {
    @State private var selected: FirefighterTab = .fieldMap

    var body: some View {
        TabView(selection: $selected) {
            FieldMapView()
                .tabItem {
                    Label("Field Map", systemImage: "map.fill")
                }
                .tag(FirefighterTab.fieldMap)

            NavigationStack {
                AssignmentsView()
            }
            .tabItem {
                Label("Assignments", systemImage: "list.bullet.clipboard")
            }
            .tag(FirefighterTab.assignments)

            NavigationStack {
                ResponderSettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(FirefighterTab.settings)
        }
        .tint(AppColors.accent)
        .toolbarBackground(Color(hex: "#1a1a1a"), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear(perform: applyFirefighterTabBarAppearance)
    }
}

private func applyFirefighterTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(red: 26 / 255, green: 26 / 255, blue: 26 / 255, alpha: 1)
    appearance.shadowColor = UIColor(red: 42 / 255, green: 42 / 255, blue: 42 / 255, alpha: 1)

    let item = UITabBarItemAppearance()
    let inactive = UIColor(red: 107 / 255, green: 114 / 255, blue: 128 / 255, alpha: 1)
    let active = UIColor(red: 217 / 255, green: 119 / 255, blue: 6 / 255, alpha: 1)
    item.normal.iconColor = inactive
    item.normal.titleTextAttributes = [.foregroundColor: inactive]
    item.selected.iconColor = active
    item.selected.titleTextAttributes = [.foregroundColor: active]

    appearance.stackedLayoutAppearance = item
    appearance.inlineLayoutAppearance = item
    appearance.compactInlineLayoutAppearance = item

    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
}
