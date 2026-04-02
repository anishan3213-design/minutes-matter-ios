//
//  HomeScreen.swift
//  Minutes Matter
//

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject private var authState: AuthState

    var body: some View {
        ZStack {
            Color(hex: "#0f0f0f")
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    topSection
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)
                        .padding(.bottom, 28)

                    featureSection
                        .padding(.bottom, 32)

                    ctaSection
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var topSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#f97316"), Color(hex: "#dc2626")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text("Minutes Matter")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Color(hex: "#ffffff"))
            Text("Every minute matters.")
                .font(.system(size: 20, weight: .regular))
                .italic()
                .foregroundColor(Color(hex: "#16a34a"))
            Text(
                "Real-time wildfire alerts for you, your family, and everyone you're watching out for — before it's too late."
            )
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "#9ca3af"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 300)
        }
        .padding(.horizontal, 20)
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            featureRow(
                icon: "🔥",
                title: "Fire Alerts Before Orders",
                description: "Get notified the moment satellite data detects a fire near your location."
            )
            featureRow(
                icon: "✅",
                title: "Safe Check-Ins",
                description: "Tap once to confirm you're safe. Your family sees it instantly."
            )
            featureRow(
                icon: "🗺",
                title: "Clear Evacuation Routes",
                description: "Step-by-step guidance to safely leave your area with nearest open shelters."
            )
        }
        .padding(.horizontal, 16)
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 28))
                .frame(width: 36, alignment: .center)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#ffffff"))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#9ca3af"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var ctaSection: some View {
        VStack(spacing: 16) {
            NavigationLink {
                SignUpFlowView(isResumeWizard: false)
            } label: {
                Text("Get Started Free")
            }
            .buttonStyle(PrimaryButtonStyle())

            NavigationLink {
                LoginFormView()
            } label: {
                Text("Sign In")
            }
            .buttonStyle(OutlineButtonStyle())

            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color(hex: "#2a2a2a"))
                    .frame(height: 1)
                Text("OR")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#6b7280"))
                Rectangle()
                    .fill(Color(hex: "#2a2a2a"))
                    .frame(height: 1)
            }
            .padding(.vertical, 4)

            NavigationLink {
                ResponderSignupFlow()
                    .environmentObject(authState)
            } label: {
                Text("Join as Emergency Responder")
            }
            .buttonStyle(PrimaryButtonStyle(color: Color(hex: "#d97706")))

            Text("Free to sign up — no add-on fees")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#6b7280"))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }
}
