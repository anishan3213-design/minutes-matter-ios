//
//  MobilitySettingsView.swift
//  Minutes Matter
//

import SwiftUI

private struct NeedChip: Hashable {
    let id: String
    let label: String
}

struct MobilitySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authState: AuthState

    let userId: UUID
    let initialMobility: [String]
    let initialMedical: [String]

    @State private var mobilitySelected: Set<String> = []
    @State private var medicalSelected: Set<String> = []
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var saveSuccess = false

    private let mobilityOptions: [NeedChip] = [
        NeedChip(id: "wheelchair", label: "Wheelchair"),
        NeedChip(id: "walker", label: "Walker / cane"),
        NeedChip(id: "hearing_impairment", label: "Hearing"),
        NeedChip(id: "vision_impairment", label: "Vision"),
        NeedChip(id: "oxygen_dependent", label: "Oxygen"),
        NeedChip(id: "needs_transportation", label: "Needs transport")
    ]

    private let medicalOptions: [NeedChip] = [
        NeedChip(id: "diabetes", label: "Diabetes"),
        NeedChip(id: "heart_condition", label: "Heart condition"),
        NeedChip(id: "respiratory", label: "Respiratory"),
        NeedChip(id: "other_chronic", label: "Other chronic")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0f0f0f")
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        sectionTitle("MOBILITY")
                        mobilityChipGrid

                        sectionTitle("MEDICAL")
                        medicalChipGrid

                        if let err = errorMessage {
                            Text(err)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.danger)
                        }

                        if saveSuccess {
                            Text("✅ Saved")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.primaryLight)
                        }

                        Button {
                            Task { await save() }
                        } label: {
                            ZStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(Color(hex: "#ffffff"))
                                } else {
                                    Text("Save")
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isSaving)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Mobility & health")
            .mmNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#16a34a"))
                }
            }
            .onAppear {
                mobilitySelected = Set(initialMobility)
                medicalSelected = Set(initialMedical)
            }
        }
    }

    private var mobilityChipGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
            ForEach(mobilityOptions, id: \.id) { chip in
                chipButton(chip: chip, isOn: mobilitySelected.contains(chip.id)) {
                    if mobilitySelected.contains(chip.id) {
                        mobilitySelected.remove(chip.id)
                    } else {
                        mobilitySelected.insert(chip.id)
                    }
                }
            }
        }
    }

    private var medicalChipGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
            ForEach(medicalOptions, id: \.id) { chip in
                chipButton(chip: chip, isOn: medicalSelected.contains(chip.id)) {
                    if medicalSelected.contains(chip.id) {
                        medicalSelected.remove(chip.id)
                    } else {
                        medicalSelected.insert(chip.id)
                    }
                }
            }
        }
    }

    private func chipButton(chip: NeedChip, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(chip.label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isOn ? Color(hex: "#ffffff") : Color(hex: "#9ca3af"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(isOn ? AppColors.primary : AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isOn ? AppColors.primary : AppColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(AppColors.textMuted)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            try await SupabaseService.shared.updateMobilityAndMedical(
                userId: userId,
                mobilityNeeds: Array(mobilitySelected).sorted(),
                medicalNeeds: Array(medicalSelected).sorted()
            )
            saveSuccess = true
            await authState.checkSession()
            try? await Task.sleep(nanoseconds: 800_000_000)
            dismiss()
        } catch {
            errorMessage = "Could not save. Try again."
        }
    }
}
