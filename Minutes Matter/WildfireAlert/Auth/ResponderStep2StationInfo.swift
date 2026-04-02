//
//  ResponderStep2StationInfo.swift
//  Minutes Matter
//

import SwiftUI

struct ResponderStep2StationInfo: View {
    @ObservedObject var draft: ResponderSignupDraft
    var onContinue: () -> Void

    @State private var showAddressConfirm = false
    @State private var formattedPreview: String = ""

    private var canContinue: Bool {
        !draft.stationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.stationAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft.addressVerified
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

                Text("Station or command post address")
                    .authSectionLabelStyle()
                TextField("123 Station Rd, City, State", text: $draft.stationAddress, axis: .vertical)
                    .lineLimit(3 ... 6)
                    .authInputFieldStyle()

                Text("Used to anchor your command map")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textMuted)

                if !draft.stationAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        let t = draft.stationAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                        formattedPreview = "📍 \(t) — Is this correct?"
                        showAddressConfirm = true
                    } label: {
                        Text("Verify Address")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(hex: "#d97706"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                if draft.addressVerified {
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
        .alert("Verify address", isPresented: $showAddressConfirm) {
            Button("Not quite") {
                showAddressConfirm = false
            }
            Button("Yes, correct") {
                draft.addressVerified = true
                showAddressConfirm = false
            }
        } message: {
            Text(formattedPreview)
        }
    }
}
