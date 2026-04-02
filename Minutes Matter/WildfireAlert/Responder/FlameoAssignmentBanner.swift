//
//  FlameoAssignmentBanner.swift
//  Minutes Matter
//

import SwiftUI

struct FlameoAssignmentBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Text("🔥")
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text("FLAMEO COMMAND")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#d97706"))
                    .tracking(1)
                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(hex: "#1a1a1a").opacity(0.95))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}
