//
//  SignUpStep3WorkLocation.swift
//  Minutes Matter
//

import SwiftUI

private enum WorkBuilding: String, CaseIterable, Identifiable {
    case house
    case apartment
    case office
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .house: return "House"
        case .apartment: return "Apartment"
        case .office: return "Office"
        case .other: return "Other"
        }
    }
}

struct SignUpStep3WorkLocation: View {
    @EnvironmentObject private var authState: AuthState

    @State private var wantsWorkAddress = false
    @State private var workAddress = ""
    @State private var building: WorkBuilding?
    @State private var floorNumber = ""
    @State private var mobilityNote = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var onContinue: () -> Void
    var onSkip: () -> Void

    private var showFloor: Bool {
        building == .apartment || building == .office
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            signUpScreenChrome(
                title: "Add a work location?",
                subtitle: "Optional — we'll alert you based on where you're most likely to be during the day."
            )

            if !wantsWorkAddress {
                VStack(spacing: 16) {
                    Text(
                        "If you work outside your home, add your work address so we can alert you when a fire is nearby — wherever you are."
                    )
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                    Button {
                        wantsWorkAddress = true
                    } label: {
                        Text("+ Add work location")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
                .padding(20)
                .cardStyle()
            } else {
                fieldLabel("Work address")
                AddressSearchField(
                    placeholder: "Search your work address",
                    helperText: "Enter your work address",
                    selectedAddress: $workAddress,
                    onSelect: { details in
                        workAddress = details.formattedAddress
                        let detected = details.buildingType
                        if let w = WorkBuilding(rawValue: detected), detected != "other" {
                            building = w
                        }
                    }
                )

                if !workAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    fieldLabel("Building type")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                        ForEach(WorkBuilding.allCases) { b in
                            ChipView(label: b.label, isSelected: building == b) {
                                building = b
                            }
                        }
                    }

                    if showFloor {
                        fieldLabel("What floor are you on?")
                        TextField("", text: $floorNumber, prompt: Text("Floor number").foregroundColor(AppColors.textMuted))
                            .keyboardType(.numberPad)
                            .foregroundColor(AppColors.textPrimary)
                            .authInputFieldStyle()
                    }

                    fieldLabel("Mobility note at this location (optional)")
                    TextField(
                        "",
                        text: $mobilityNote,
                        prompt: Text("e.g. Wheelchair user, 6th floor").foregroundColor(AppColors.textMuted)
                    )
                    .foregroundColor(AppColors.textPrimary)
                    .authInputFieldStyle()
                    .onChange(of: mobilityNote) { newValue in
                        if newValue.count > 100 {
                            mobilityNote = String(newValue.prefix(100))
                        }
                    }

                    Button {
                        wantsWorkAddress = false
                        workAddress = ""
                        building = nil
                        floorNumber = ""
                        mobilityNote = ""
                    } label: {
                        Text("Remove work location")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.danger)
            }

            Spacer(minLength: 24)

            Button {
                Task { await save(advance: true) }
            } label: {
                ZStack {
                    if isSaving {
                        ProgressView()
                            .tint(Color(hex: "#ffffff"))
                    } else {
                        Text("Continue")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isSaving)

            Button {
                onSkip()
            } label: {
                Text("Skip — I work from home")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#9ca3af"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            if let p = authState.profile {
                let addr = p.workAddress ?? ""
                if !addr.isEmpty {
                    wantsWorkAddress = true
                    if workAddress.isEmpty { workAddress = addr }
                }
                if let t = p.workBuildingType, let w = WorkBuilding(rawValue: t) {
                    building = w
                }
                if floorNumber.isEmpty { floorNumber = p.workFloorNumber ?? "" }
                if mobilityNote.isEmpty { mobilityNote = p.workLocationNote ?? "" }
            }
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .authSectionLabelStyle()
    }

    private func save(advance: Bool) async {
        errorMessage = nil
        guard let uid = authState.currentUserId else {
            errorMessage = "Session error. Please try again."
            return
        }
        if wantsWorkAddress {
            let addr = workAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            if addr.isEmpty {
                errorMessage = "Enter your work address or tap Skip."
                return
            }
        } else {
            if advance { onContinue() }
            return
        }
        isSaving = true
        defer { isSaving = false }
        let addr = workAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await SupabaseService.shared.updateWorkLocation(
                userId: uid,
                workAddress: addr.isEmpty ? nil : addr,
                workBuildingType: building?.rawValue,
                workFloorNumber: showFloor ? floorNumber.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty : nil,
                workLocationNote: mobilityNote.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            )
            await authState.refreshProfile()
            if advance { onContinue() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
