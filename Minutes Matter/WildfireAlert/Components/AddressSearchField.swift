//
//  AddressSearchField.swift
//  Minutes Matter
//

import SwiftUI

struct AddressSearchField: View {
    let placeholder: String
    let helperText: String
    @Binding var selectedAddress: String
    var onSelect: ((PlaceDetails) -> Void)?

    @StateObject private var places = PlacesService()
    @State private var query = ""
    @State private var showSuggestions = false
    @State private var loadingPlaceId: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(isFocused ? AppColors.primary : AppColors.textMuted)

                TextField(placeholder, text: $query)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textPrimary)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .onChange(of: query) { newValue in
                        showSuggestions = !newValue.isEmpty
                        places.search(query: newValue)
                    }

                if places.isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(AppColors.textMuted)
                } else if !query.isEmpty {
                    Button {
                        query = ""
                        selectedAddress = ""
                        places.suggestions = []
                        showSuggestions = false
                        places.clearSearchError()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textMuted)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(AppColors.surface)
            .cornerRadius(
                10,
                corners: showSuggestions && !places.suggestions.isEmpty
                    ? [.topLeft, .topRight]
                    : [.topLeft, .topRight, .bottomLeft, .bottomRight]
            )
            .overlay(
                Group {
                    if showSuggestions, !places.suggestions.isEmpty {
                        RoundedCornerShape(radius: 10, corners: [.topLeft, .topRight])
                            .stroke(isFocused ? AppColors.primary : AppColors.border, lineWidth: 1)
                    } else {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isFocused ? AppColors.primary : AppColors.border, lineWidth: 1)
                    }
                }
            )

            if showSuggestions, !places.suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(places.suggestions.enumerated()), id: \.element.id) { index, suggestion in
                        Button {
                            Task { await selectSuggestion(suggestion) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.primary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.mainText)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(AppColors.textPrimary)
                                        .lineLimit(1)

                                    if !suggestion.secondaryText.isEmpty {
                                        Text(suggestion.secondaryText)
                                            .font(.system(size: 13))
                                            .foregroundColor(AppColors.textSecondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer(minLength: 0)

                                if loadingPlaceId == suggestion.placeId {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.surface)
                        }
                        .buttonStyle(.plain)

                        if index < places.suggestions.count - 1 {
                            Divider()
                                .background(AppColors.border)
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(AppColors.surface)
                .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            if !helperText.isEmpty {
                Text(helperText)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textMuted)
                    .padding(.top, 6)
                    .padding(.horizontal, 4)
            }

            if let err = places.lastSearchError, !err.isEmpty, !query.isEmpty {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.warning)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .padding(.horizontal, 4)
            }

            if !selectedAddress.isEmpty, query == selectedAddress {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.primary)
                    Text("Address verified")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.primary)
                }
                .padding(.top, 6)
                .padding(.horizontal, 4)
            }
        }
        .onAppear {
            if !selectedAddress.isEmpty, query.isEmpty {
                query = selectedAddress
            }
        }
        .onChange(of: selectedAddress) { newValue in
            if !newValue.isEmpty, query != newValue {
                query = newValue
            }
        }
    }

    private func selectSuggestion(_ suggestion: PlaceSuggestion) async {
        loadingPlaceId = suggestion.placeId
        defer { loadingPlaceId = nil }

        if let details = await places.getDetails(placeId: suggestion.placeId) {
            query = details.formattedAddress
            selectedAddress = details.formattedAddress
            places.suggestions = []
            showSuggestions = false
            isFocused = false
            onSelect?(details)
        } else {
            let addr = suggestion.mainText
                + (suggestion.secondaryText.isEmpty ? "" : ", " + suggestion.secondaryText)
            query = addr
            selectedAddress = addr
            places.suggestions = []
            showSuggestions = false
            isFocused = false
        }
    }
}
