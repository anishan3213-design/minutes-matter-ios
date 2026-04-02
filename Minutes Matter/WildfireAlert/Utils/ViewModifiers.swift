//
//  ViewModifiers.swift
//  Minutes Matter
//
//  Design system: cards, inputs, primary/outline buttons, navigation chrome.
//

import SwiftUI

// MARK: - Card

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color(hex: "#242424"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#2a2a2a"), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    /// Full-width hub/check-in cards (same fill/stroke as `cardStyle`).
    func hubCardStyle() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .modifier(CardStyle())
    }
}

// MARK: - Text fields

struct InputFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color(hex: "#1a1a1a"))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "#2a2a2a"), lineWidth: 1)
            )
            .foregroundColor(Color(hex: "#ffffff"))
            .font(.system(size: 16))
    }
}

extension View {
    func inputFieldStyle() -> some View {
        modifier(InputFieldStyle())
    }

    /// Alias used across auth/responder flows.
    func authInputFieldStyle() -> some View {
        inputFieldStyle()
    }

    /// Multiline address / notes (same chrome as single-line inputs).
    func inputFieldMultilineStyle(minHeight: CGFloat = 120) -> some View {
        padding(16)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .background(Color(hex: "#1a1a1a"))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "#2a2a2a"), lineWidth: 1)
            )
            .foregroundColor(Color(hex: "#ffffff"))
            .font(.system(size: 16))
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Color(hex: "#16a34a")

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(configuration.isPressed ? color.opacity(0.8) : color)
            .foregroundColor(Color(hex: "#ffffff"))
            .font(.system(size: 16, weight: .semibold))
            .cornerRadius(10)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    var color: Color = Color(hex: "#16a34a")

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.clear)
            .foregroundColor(color)
            .font(.system(size: 16, weight: .semibold))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: 1.5)
            )
    }
}

// MARK: - Navigation

extension View {
    /// Dark navigation bar matching web chrome (`#1a1a1a`).
    func mmNavigationChrome(
        titleDisplayMode: NavigationBarItem.TitleDisplayMode = .inline
    ) -> some View {
        navigationBarTitleDisplayMode(titleDisplayMode)
            .toolbarBackground(Color(hex: "#1a1a1a"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
