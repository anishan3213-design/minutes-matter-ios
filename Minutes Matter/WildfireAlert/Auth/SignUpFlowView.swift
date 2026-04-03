//
//  SignUpFlowView.swift
//  Minutes Matter
//

import SwiftUI

/// Full signup: step 1 from marketing (`isResumeWizard == false`), steps 2–6 after auth (`isResumeWizard == true`).
struct SignUpFlowView: View {
    @EnvironmentObject private var authState: AuthState
    @Environment(\.dismiss) private var dismiss

    var isResumeWizard: Bool

    @State private var step: Int
    @State private var showEmailConfirmation = false
    @State private var pendingConfirmationEmail = ""

    private static let signupStepTitles = [
        "Account",
        "Home Address",
        "Work Location",
        "Emergency Info",
        "Accessibility",
        "Terms",
    ]

    init(isResumeWizard: Bool = false) {
        self.isResumeWizard = isResumeWizard
        _step = State(initialValue: isResumeWizard ? 2 : 1)
    }

    var body: some View {
        Group {
            if showEmailConfirmation {
                emailConfirmationContent
            } else {
                stepContent
            }
        }
        .background(Color(hex: "#0f0f0f").ignoresSafeArea())
        .navigationTitle("Sign up")
        .mmNavigationChrome()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if showEmailConfirmation {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                } else if isResumeWizard, step > 2 {
                    Button("Back") {
                        step -= 1
                        authState.persistSignupWizard(step: step)
                    }
                    .foregroundColor(AppColors.primary)
                } else if !isResumeWizard, !authState.signupInProgress {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .onAppear {
            syncStepFromWizardState()
        }
        .onChange(of: authState.signupWizardStep) { _ in
            syncStepFromWizardState()
        }
    }

    private func syncStepFromWizardState() {
        if let s = authState.signupWizardStep, (2 ... 6).contains(s) {
            let restored = min(max(s, isResumeWizard ? 2 : 1), 6)
            step = restored
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: 0) {
            signupProgressRibbon
            ScrollView {
                Group {
                    switch step {
                    case 1:
                        SignUpStep1Account(
                            onSignedIn: { goTo(2) },
                            onConfirmEmail: { addr in
                                pendingConfirmationEmail = addr
                                showEmailConfirmation = true
                            }
                        )
                    case 2:
                        SignUpStep2HomeAddress(
                            onContinue: { goTo(3) },
                            onSkip: { goTo(3) }
                        )
                    case 3:
                        SignUpStep3WorkLocation(
                            onContinue: { goTo(4) },
                            onSkip: { goTo(4) }
                        )
                    case 4:
                        SignUpStep4Contacts(
                            onContinue: { goTo(5) },
                            onSkip: { goTo(5) }
                        )
                    case 5:
                        SignUpStep5Accessibility(onContinue: { goTo(6) })
                    case 6:
                        SignUpStep6Terms(onComplete: {})
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(hex: "#0f0f0f"))
        }
    }

    private var signupProgressRibbon: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "#2a2a2a"))
                        .frame(height: 3)
                    Rectangle()
                        .fill(Color(hex: "#16a34a"))
                        .frame(width: max(0, geo.size.width * CGFloat(step) / 6.0), height: 3)
                }
            }
            .frame(height: 3)
            let title = (1 ... 6).contains(step)
                ? Self.signupStepTitles[step - 1]
                : ""
            Text("Step \(step) of 6: \(title)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#6b7280"))
                .textCase(.uppercase)
                .tracking(0.8)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }

    private var emailConfirmationContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Confirm your email")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(
                    "We sent a confirmation link to \(pendingConfirmationEmail). After you verify, sign in from the home screen."
                )
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                Button {
                    dismiss()
                } label: {
                    Text("Back to home")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Color(hex: "#0f0f0f"))
    }

    private func goTo(_ newStep: Int) {
        guard (1 ... 6).contains(newStep) else { return }
        step = newStep
        authState.persistSignupWizard(step: newStep)
    }
}
