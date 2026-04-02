//
//  SectionLabel.swift
//  Minutes Matter
//

import SwiftUI

struct SectionLabel: View {
    let text: String
    /// When `false`, omits top padding (e.g. first label inside a card).
    var includeTopSpacing: Bool = true
    var centered: Bool = false

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color(hex: "#6b7280"))
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
            .padding(.top, includeTopSpacing ? 24 : 0)
            .padding(.bottom, 8)
    }
}
