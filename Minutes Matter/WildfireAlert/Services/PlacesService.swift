//
//  PlacesService.swift
//  Minutes Matter
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class PlacesService: ObservableObject {
    @Published var suggestions: [PlaceSuggestion] = []
    @Published private(set) var isSearching = false
    /// User-visible hint when autocomplete returns nothing (missing key, billing, restrictions, decode error).
    @Published private(set) var lastSearchError: String?

    private var searchTask: Task<Void, Never>?

    private var apiKey: String {
        AppConfig.googlePlacesAPIKey ?? ""
    }

    func clearSearchError() {
        lastSearchError = nil
    }

    func search(query: String) {
        guard query.count >= 2 else {
            suggestions = []
            lastSearchError = nil
            return
        }
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(query: query)
        }
    }

    private func performSearch(query: String) async {
        guard !apiKey.isEmpty else {
            lastSearchError = "Add GOOGLE_PLACES_KEY to Info.plist and enable Places API in Google Cloud."
            print("[Places] Missing API key (GOOGLE_PLACES_KEY / GOOGLE_PLACES_API_KEY)")
            suggestions = []
            return
        }
        isSearching = true
        defer { isSearching = false }
        lastSearchError = nil

        // Omit `types` — `types=address` often yields ZERO_RESULTS for partial input. Bias to US addresses.
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json")!
        components.queryItems = [
            URLQueryItem(name: "input", value: query),
            URLQueryItem(name: "components", value: "country:us"),
            URLQueryItem(name: "key", value: apiKey),
        ]
        guard let url = components.url else {
            lastSearchError = "Invalid Places URL."
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                lastSearchError = "Places request failed (HTTP \(http.statusCode))."
                #if DEBUG
                print("[Places] Autocomplete HTTP:", http.statusCode)
                if let s = String(data: data, encoding: .utf8) {
                    print("[Places] body:", String(s.prefix(500)))
                }
                #endif
                suggestions = []
                return
            }

            let decoded: PlacesAutocompleteResponse
            do {
                decoded = try JSONDecoder().decode(PlacesAutocompleteResponse.self, from: data)
            } catch {
                lastSearchError = "Could not read address suggestions."
                #if DEBUG
                print("[Places] Autocomplete decode error:", error)
                if let s = String(data: data, encoding: .utf8) {
                    print("[Places] raw:", String(s.prefix(500)))
                }
                #endif
                suggestions = []
                return
            }

            if decoded.status == "OK" || decoded.status == "ZERO_RESULTS" {
                lastSearchError = decoded.status == "ZERO_RESULTS" && decoded.predictions.isEmpty
                    ? "No matches — try street number and city."
                    : nil
            } else {
                let detail = decoded.errorMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
                lastSearchError = detail?.isEmpty == false
                    ? detail
                    : "Places error: \(decoded.status). Check API key restrictions and billing."
                #if DEBUG
                print("[Places] Autocomplete status:", decoded.status, decoded.errorMessage ?? "")
                #endif
            }

            suggestions = Array(decoded.predictions.prefix(8)).map { PlaceSuggestion(prediction: $0) }
            if decoded.status == "OK", suggestions.isEmpty {
                lastSearchError = "No suggestions returned."
            }
        } catch {
            lastSearchError = "Network error loading addresses."
            print("[Places] Search error:", error)
            suggestions = []
        }
    }

    func getDetails(placeId: String) async -> PlaceDetails? {
        guard !apiKey.isEmpty else { return nil }
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/details/json")!
        components.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "formatted_address,geometry,types"),
            URLQueryItem(name: "key", value: apiKey),
        ]
        guard let url = components.url else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                #if DEBUG
                print("[Places] Details HTTP:", http.statusCode)
                #endif
                return nil
            }
            let detailsResponse = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
            if detailsResponse.status != "OK" {
                #if DEBUG
                print("[Places] Details status:", detailsResponse.status, detailsResponse.errorMessage ?? "")
                #endif
            }
            guard let result = detailsResponse.result,
                  let lat = result.geometry?.location?.lat,
                  let lng = result.geometry?.location?.lng
            else { return nil }
            return PlaceDetails(
                formattedAddress: result.formattedAddress ?? "",
                lat: lat,
                lng: lng,
                types: result.types ?? []
            )
        } catch {
            print("[Places] Details error:", error)
            return nil
        }
    }
}

// MARK: - Models

struct PlaceSuggestion: Identifiable {
    let id: String
    let mainText: String
    let secondaryText: String
    let placeId: String

    init(prediction: PlacePrediction) {
        id = prediction.placeId
        mainText = prediction.structuredFormatting.mainText
        secondaryText = prediction.structuredFormatting.secondaryText ?? ""
        placeId = prediction.placeId
    }
}

struct PlaceDetails: Sendable {
    let formattedAddress: String
    let lat: Double
    let lng: Double
    let types: [String]

    var buildingType: String {
        if types.contains("street_address"), !types.contains("establishment") {
            return "house"
        }
        if types.contains("office")
            || (types.contains("point_of_interest") && types.contains("establishment")) {
            return "office"
        }
        if types.contains("premise"), types.contains("establishment") {
            return "apartment"
        }
        return "other"
    }
}

// MARK: - API response models

struct PlacesAutocompleteResponse: Decodable {
    let predictions: [PlacePrediction]
    let status: String
    let errorMessage: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = try c.decode(String.self, forKey: .status)
        predictions = try c.decodeIfPresent([PlacePrediction].self, forKey: .predictions) ?? []
        errorMessage = try c.decodeIfPresent(String.self, forKey: .errorMessage)
    }

    enum CodingKeys: String, CodingKey {
        case predictions
        case status
        case errorMessage = "error_message"
    }
}

struct PlacePrediction: Decodable {
    let placeId: String
    let structuredFormatting: StructuredFormatting

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case structuredFormatting = "structured_formatting"
        case description
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        placeId = try c.decode(String.self, forKey: .placeId)
        if let sf = try c.decodeIfPresent(StructuredFormatting.self, forKey: .structuredFormatting) {
            structuredFormatting = sf
        } else if let desc = try c.decodeIfPresent(String.self, forKey: .description) {
            structuredFormatting = StructuredFormatting(mainText: desc, secondaryText: nil)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .structuredFormatting,
                in: c,
                debugDescription: "Missing structured_formatting and description"
            )
        }
    }
}

struct StructuredFormatting: Decodable {
    let mainText: String
    let secondaryText: String?

    enum CodingKeys: String, CodingKey {
        case mainText = "main_text"
        case secondaryText = "secondary_text"
    }
}

struct PlaceDetailsResponse: Decodable {
    let result: PlaceResult?
    let status: String
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case result
        case status
        case errorMessage = "error_message"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        result = try c.decodeIfPresent(PlaceResult.self, forKey: .result)
        status = try c.decode(String.self, forKey: .status)
        errorMessage = try c.decodeIfPresent(String.self, forKey: .errorMessage)
    }
}

struct PlaceResult: Decodable {
    let formattedAddress: String?
    let geometry: PlaceGeometry?
    let types: [String]?

    enum CodingKeys: String, CodingKey {
        case formattedAddress = "formatted_address"
        case geometry
        case types
    }
}

struct PlaceGeometry: Decodable {
    let location: PlaceLocation?
}

struct PlaceLocation: Decodable {
    let lat: Double
    let lng: Double
}
