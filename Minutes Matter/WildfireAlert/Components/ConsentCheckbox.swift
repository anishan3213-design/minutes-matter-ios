//
//  ConsentCheckbox.swift
//  Minutes Matter
//

import SwiftUI

struct ConsentCheckbox: View {
    let text: String
    @Binding var isChecked: Bool
    var linkText: String?
    var linkURL: URL?

    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isChecked ? AppColors.primary : AppColors.surface)
                        .frame(width: 22, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(isChecked ? AppColors.primary : AppColors.border, lineWidth: 1)
                        )
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let linkText, let linkURL {
                        Link(linkText, destination: linkURL)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.primary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}
