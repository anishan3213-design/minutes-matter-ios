//
//  SignUpStep5Accessibility.swift
//  Minutes Matter
//

import SwiftUI

struct SignUpStep5Accessibility: View {
    @EnvironmentObject private var authState: AuthState

    @State private var communication = Set<String>()
    @State private var mobility = Set<String>()
    @State private var disability = Set<String>()
    @State private var medical = Set<String>()
    @State private var disabilityOther = ""
    @State private var medicalOther = ""
    @State private var emergencyName = ""
    @State private var emergencyPhone = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var onContinue: () -> Void

    private let communicationOptions: [(String, String)] = [
        ("screen_reader", "Screen reader"),
        ("large_text", "Large text"),
        ("translation_needed", "Translation needed"),
        ("deaf_hard_hearing", "Deaf / hard of hearing"),
        ("limited_english", "Limited English"),
    ]

    private let mobilityOptions: [(String, String)] = [
        ("wheelchair_device", "Uses wheelchair or mobility device"),
        ("walker_cane", "Uses walker or cane"),
        ("cannot_climb_stairs", "Cannot climb stairs"),
        ("cannot_walk_long", "Cannot walk long distances"),
        ("requires_assistance_evac", "Requires assistance to evacuate"),
        ("bedridden_limited", "Bedridden or limited mobility"),
    ]

    private let disabilityOptions: [(String, String)] = [
        ("visual_impairment", "Visual impairment or blind"),
        ("hearing_impairment", "Hearing impairment or deaf"),
        ("cognitive_disability", "Cognitive or developmental disability"),
        ("mental_health", "Mental health condition"),
        ("other", "Other"),
    ]

    private let medicalOptions: [(String, String)] = [
        ("oxygen_ventilator", "Requires oxygen or ventilator"),
        ("dialysis", "Requires dialysis"),
        ("pacemaker", "Has pacemaker or cardiac device"),
        ("diabetes_insulin", "Diabetes — insulin dependent"),
        ("severe_allergies", "Severe allergies"),
        ("other", "Other"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            signUpScreenChrome(
                title: "Accessibility needs",
                subtitle: "Helps emergency responders reach you first. Completely optional."
            )

            hipaaCard

            chipSection(title: "COMMUNICATION NEEDS", options: communicationOptions, selection: $communication)

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("MOBILITY & MOVEMENT")
                Text("Helps responders reach you first")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textMuted)
                chipGrid(options: mobilityOptions, selection: $mobility)
            }

            chipSection(title: "DISABILITIES", options: disabilityOptions, selection: $disability)
            if disability.contains("other") {
                otherWordLimitedField(text: $disabilityOther, prompt: "Describe briefly (10 words max)")
            }

            chipSection(title: "MEDICAL CONDITIONS", options: medicalOptions, selection: $medical)
            if medical.contains("other") {
                otherWordLimitedField(text: $medicalOther, prompt: "Describe briefly (10 words max)")
            }

            sectionLabel("EMERGENCY CONTACT (optional)")
            TextField("", text: $emergencyName, prompt: Text("Name").foregroundColor(AppColors.textMuted))
                .foregroundColor(AppColors.textPrimary)
                .authInputFieldStyle()
            TextField("", text: $emergencyPhone, prompt: Text("Phone").foregroundColor(AppColors.textMuted))
                .keyboardType(.phonePad)
                .foregroundColor(AppColors.textPrimary)
                .authInputFieldStyle()

            Text("💡 You can update this anytime in Settings.")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.danger)
            }

            Button {
                Task { await save() }
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
            .padding(.bottom, 32)

            Button {
                Task { await saveSkippingOptionalFields() }
            } label: {
                Text("Skip for now")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#9ca3af"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            syncFromProfile()
        }
    }

    private var hipaaCard: some View {
        Text("🔒 Your health information is encrypted and only shared with emergency responders during active incidents. You control what you share.")
            .font(.system(size: 15))
            .foregroundColor(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(AppColors.textMuted)
            .textCase(.uppercase)
            .tracking(0.6)
    }

    private func chipSection(title: String, options: [(String, String)], selection: Binding<Set<String>>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(title)
            chipGrid(options: options, selection: selection)
        }
    }

    private func chipGrid(options: [(String, String)], selection: Binding<Set<String>>) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
            ForEach(options, id: \.0) { id, label in
                ChipView(label: label, isSelected: selection.wrappedValue.contains(id)) {
                    var s = selection.wrappedValue
                    if s.contains(id) {
                        s.remove(id)
                    } else {
                        s.insert(id)
                    }
                    selection.wrappedValue = s
                }
            }
        }
    }

    private func wordCount(_ text: String) -> Int {
        text.split(separator: " ")
            .filter { !$0.isEmpty }.count
    }

    private func enforceWordLimit(_ text: String, max: Int = 10) -> String {
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        if words.count > max {
            return words.prefix(max).joined(separator: " ")
        }
        return text
    }

    private func otherWordLimitedField(text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("", text: text, prompt: Text(prompt).foregroundColor(AppColors.textMuted))
                .foregroundColor(AppColors.textPrimary)
                .authInputFieldStyle()
                .onChange(of: text.wrappedValue) { newValue in
                    let limited = enforceWordLimit(newValue, max: 10)
                    if limited != newValue {
                        text.wrappedValue = limited
                    }
                }
            Text("\(wordCount(text.wrappedValue)) / 10 words")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textMuted)
        }
    }

    private func syncFromProfile() {
        guard let p = authState.profile else { return }
        if let a = p.communicationNeeds { communication = Set(a) }
        if let a = p.mobilityNeeds { mobility = Set(a) }
        if let a = p.disabilityNeeds { disability = Set(a) }
        if let a = p.medicalNeeds { medical = Set(a) }
        disabilityOther = p.disabilityOther ?? ""
        medicalOther = p.medicalOther ?? ""
        emergencyName = p.emergencyContactName ?? ""
        emergencyPhone = p.emergencyContactPhone ?? ""
    }

    private func saveSkippingOptionalFields() async {
        let hasSelections = !communication.isEmpty
            || !mobility.isEmpty
            || !disability.isEmpty
            || !medical.isEmpty

        if hasSelections, let uid = authState.currentUserId {
            let dOther = disability.contains("other")
                ? disabilityOther.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                : nil
            let mOther = medical.contains("other")
                ? medicalOther.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                : nil
            do {
                try await SupabaseService.shared.updateMobilityPreferences(
                    userId: uid,
                    communicationNeeds: Array(communication).sorted(),
                    mobilityNeeds: Array(mobility).sorted(),
                    disabilityNeeds: Array(disability).sorted(),
                    disabilityOther: dOther,
                    medicalNeeds: Array(medical).sorted(),
                    medicalOther: mOther
                )
            } catch {
                #if DEBUG
                print("[Step5] skip save failed:", error)
                #endif
            }
        }

        onContinue()
    }

    private func save() async {
        errorMessage = nil
        guard let uid = authState.currentUserId else {
            errorMessage = "Session error. Please try again."
            return
        }
        isSaving = true
        defer { isSaving = false }
        let dOther = disability.contains("other")
            ? disabilityOther.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            : nil
        let mOther = medical.contains("other")
            ? medicalOther.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            : nil
        do {
            try await SupabaseService.shared.updateMobilityPreferences(
                userId: uid,
                communicationNeeds: Array(communication).sorted(),
                mobilityNeeds: Array(mobility).sorted(),
                disabilityNeeds: Array(disability).sorted(),
                disabilityOther: dOther,
                medicalNeeds: Array(medical).sorted(),
                medicalOther: mOther
            )
            let en = emergencyName.trimmingCharacters(in: .whitespacesAndNewlines)
            let ep = emergencyPhone.trimmingCharacters(in: .whitespacesAndNewlines)
            try await SupabaseService.shared.updateProfileInfo(
                userId: uid,
                phone: nil,
                emergencyContactName: en.isEmpty ? nil : en,
                emergencyContactPhone: ep.isEmpty ? nil : ep
            )
            await authState.refreshProfile()
            onContinue()
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
