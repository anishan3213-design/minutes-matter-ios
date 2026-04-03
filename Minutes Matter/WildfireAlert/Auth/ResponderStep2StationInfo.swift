//
//  ResponderStep2StationInfo.swift
//  Minutes Matter
//

import SwiftUI

struct ResponderStep2StationInfo: View {
    @ObservedObject var draft: ResponderSignupDraft
    var onContinue: () -> Void

    private var canContinue: Bool {
        !draft.stationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.stationAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your Station")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Tell us about your department")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)

                Text("Station / Department name")
                    .authSectionLabelStyle()
                TextField("e.g. Clayton Fire Station #1", text: $draft.stationName)
                    .authInputFieldStyle()

                AddressSearchField(
                    placeholder: "Search station or command post address",
                    helperText: "Enter the address of your fire station or command post",
                    selectedAddress: $draft.stationAddress,
                    onSelect: { details in
                        draft.stationAddress = details.formattedAddress
                        draft.addressVerified = true
                    }
                )

                Text("Used to anchor your command map")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textMuted)

                if draft.addressVerified, !draft.stationAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("✅ Address verified")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }

                Text("Phone (optional)")
                    .authSectionLabelStyle()
                TextField("+1 (555) 000-0000", text: $draft.phone)
                    .keyboardType(.phonePad)
                    .authInputFieldStyle()

                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "#d97706"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.45)
            }
            .padding(20)
        }
    }
}
