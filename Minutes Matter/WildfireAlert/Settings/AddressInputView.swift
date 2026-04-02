//
//  AddressInputView.swift
//  Minutes Matter
//

import SwiftUI

struct AddressInputView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authState: AuthState
    @ObservedObject var viewModel: SettingsViewModel

    let userId: UUID

    @State private var addressText = ""
    @State private var localSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0f0f0f")
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Enter your home address")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        TextField(
                            "",
                            text: $addressText,
                            prompt: Text("123 Main St, City, State").foregroundColor(Color(hex: "#6b7280"))
                        )
                        .textContentType(.fullStreetAddress)
                        .inputFieldMultilineStyle(minHeight: 120)
                        .onSubmit { Task { await saveIfValid() } }

                        Text("Enter your full street address including city and state for best results.")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textMuted)
                            .fixedSize(horizontal: false, vertical: true)

                        if let err = viewModel.errorMessage {
                            Text(err)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.danger)
                        }

                        if localSuccess {
                            Text("✅ Address saved")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.primaryLight)
                        }

                        saveButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Home Address")
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
                addressText = viewModel.profile?.homeAddress ?? authState.profile?.homeAddress ?? ""
                viewModel.errorMessage = nil
            }
        }
    }

    private var trimmed: String {
        addressText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmed.isEmpty
    }

    @ViewBuilder
    private var saveButton: some View {
        Button {
            Task { await saveIfValid() }
        } label: {
            ZStack {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(Color(hex: "#ffffff"))
                } else {
                    Text("Save Address")
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!canSave || viewModel.isSaving)
        .opacity(canSave ? 1 : 0.45)
    }

    private func saveIfValid() async {
        guard canSave else { return }
        viewModel.errorMessage = nil
        await viewModel.saveAddress(
            userId: userId,
            address: trimmed,
            token: nil,
            auth: authState
        )
        if viewModel.errorMessage == nil {
            localSuccess = true
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        }
    }
}
