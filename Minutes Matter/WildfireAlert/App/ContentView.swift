//
//  ContentView.swift
//  Minutes Matter
//

import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var authState: AuthState

    var body: some View {
        Group {
            if authState.isLoading {
                ZStack {
                    Color(hex: "#0f0f0f").ignoresSafeArea()
                    ProgressView()
                        .tint(Color(hex: "#16a34a"))
                }
            } else if authState.isAuthenticated {
                if authState.signupInProgress {
                    SignUpFlowView(isResumeWizard: false)
                        .environmentObject(authState)
                } else if authState.signupWizardStep != nil {
                    SignUpFlowView(isResumeWizard: true)
                        .environmentObject(authState)
                } else if authState.isFirefighter {
                    FirefighterTabView()
                        .environmentObject(authState)
                } else {
                    MainTabView()
                        .environmentObject(authState)
                }
            } else {
                HomeScreen()
                    .environmentObject(authState)
            }
        }
        .task {
            await authState.checkSession()
        }
    }
}

private struct MainTabView: View {
    @EnvironmentObject private var authState: AuthState
    @State private var selectedTab: AppMainTab = .hub

    var body: some View {
        TabView(selection: $selectedTab) {
            HubView(selectedTab: $selectedTab)
                .environmentObject(authState)
                .tabItem {
                    Label("Hub", systemImage: "house.fill")
                }
                .tag(AppMainTab.hub)

            CheckInView()
                .environmentObject(authState)
                .tabItem {
                    Label("Check In", systemImage: "checkmark.circle.fill")
                }
                .tag(AppMainTab.checkIn)

            MapView()
                .environmentObject(authState)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(AppMainTab.map)

            PeopleView()
                .environmentObject(authState)
                .tabItem {
                    Label("People", systemImage: "person.2.fill")
                }
                .tag(AppMainTab.people)

            SettingsView()
                .environmentObject(authState)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppMainTab.settings)
        }
        .tint(AppColors.primary)
        .toolbarBackground(AppColors.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear(perform: applyTabBarAppearance)
    }
}

private func applyTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(red: 26 / 255, green: 26 / 255, blue: 26 / 255, alpha: 1)
    appearance.shadowColor = UIColor(red: 42 / 255, green: 42 / 255, blue: 42 / 255, alpha: 1)

    let item = UITabBarItemAppearance()
    let inactive = UIColor(red: 107 / 255, green: 114 / 255, blue: 128 / 255, alpha: 1)
    let active = UIColor(red: 22 / 255, green: 163 / 255, blue: 74 / 255, alpha: 1)
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

#Preview {
    ContentView()
        .environmentObject(AuthState())
        .environmentObject(AppearanceController())
}
