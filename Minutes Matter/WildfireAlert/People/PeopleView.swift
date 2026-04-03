//
//  PeopleView.swift
//  Minutes Matter
//

import SwiftUI

struct PeopleView: View {
    @EnvironmentObject private var authState: AuthState
    @StateObject private var viewModel = PeopleViewModel()

    var body: some View {
        ZStack {
            Color(hex: "#0f0f0f")
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if viewModel.isLoading && viewModel.people.isEmpty {
                        ProgressView()
                            .tint(AppColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if viewModel.people.isEmpty {
                        emptyState
                    } else {
                        peopleList
                    }

                    addSomeoneButton
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.bottom, 24)
            }
        }
        .refreshable {
            if let id = authState.currentUserId {
                await viewModel.load(userId: id)
            }
        }
        .task {
            if let id = authState.currentUserId {
                await viewModel.load(userId: id)
            }
        }
        .sheet(isPresented: $viewModel.showInviteSheet) {
            if let id = authState.currentUserId {
                InvitePersonView(viewModel: viewModel, userId: id)
                    .environmentObject(authState)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My People")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Text("Family and anyone you're watching out for")
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("👥")
                .font(.system(size: 48))
            Text("No one added yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#ffffff"))
            Text("Add family members or anyone you're looking out for.")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#9ca3af"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var peopleList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.people) { person in
                PersonRowView(person: person)
            }
        }
    }

    private var addSomeoneButton: some View {
        Button {
            viewModel.resetInviteFlow()
            viewModel.showInviteSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text("Add Someone")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}
