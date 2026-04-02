//
//  InvitePersonView.swift
//  Minutes Matter
//

import SwiftUI

struct InvitePersonView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authState: AuthState
    @ObservedObject var viewModel: PeopleViewModel
    let userId: UUID

    private var trimmedEmail: String {
        viewModel.inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        !trimmedEmail.isEmpty && PeopleViewModel.isValidInviteEmail(trimmedEmail)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1a1a1a")
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Add Someone")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#ffffff"))

                        Text("They'll get an email to join Minutes Matter. Once they sign up, you'll see their status here.")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#9ca3af"))
                            .fixedSize(horizontal: false, vertical: true)

                        TextField(
                            "",
                            text: $viewModel.inviteEmail,
                            prompt: Text("Enter their email address").foregroundColor(Color(hex: "#6b7280"))
                        )
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .inputFieldStyle()

                        consentCard

                        if case let .sent(email) = viewModel.inviteStatus {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "#16a34a"))
                                Text("Invite sent to \(email)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "#16a34a"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        inviteButton

                        if case let .failed(message) = viewModel.inviteStatus {
                            Text(message)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#dc2626"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .mmNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetInviteFlow()
                        dismiss()
                    }
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#9ca3af"))
                }
            }
        }
    }

    private var consentCard: some View {
        Text("When they join your My People, you'll each be able to see the other's safety status during an active incident.")
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "#9ca3af"))
            .fixedSize(horizontal: false, vertical: true)
            .cardStyle()
    }

    @ViewBuilder
    private var inviteButton: some View {
        switch viewModel.inviteStatus {
        case .sent:
            Button {
                viewModel.resetInviteFlow()
            } label: {
                Text("Send Another")
            }
            .buttonStyle(PrimaryButtonStyle())
        default:
            Button {
                Task {
                    let token = try? await authState.accessToken()
                    await viewModel.sendInvite(userId: userId, token: token)
                }
            } label: {
                ZStack {
                    if case .sending = viewModel.inviteStatus {
                        ProgressView()
                            .tint(Color(hex: "#ffffff"))
                    } else {
                        Text("Send Invite")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canSend || viewModel.inviteStatus == .sending)
            .opacity((!canSend && viewModel.inviteStatus != .sending) ? 0.45 : 1)
        }
    }
}
