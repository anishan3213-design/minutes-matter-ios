//
//  APIService.swift
//  Minutes Matter
//

import Foundation

enum APIServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case httpStatus(code: Int, body: String?)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid server response."
        case .unauthorized:
            return "Session expired. Sign in again."
        case let .httpStatus(code, body):
            return "Request failed (\(code)): \(body ?? "")"
        case .decodingFailed:
            return "Could not decode the response."
        }
    }
}

/// Calls the Minutes Matter web API on Vercel. Pass the Supabase access token for routes that require auth.
final class APIService {
    static let shared = APIService()

    private let baseURL: URL
    private let urlSession: URLSession

    private static let jsonDecoder = JSONDecoder()
    private static let jsonEncoder = JSONEncoder()

    init(baseURL: URL = AppConfig.apiBaseURL, urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    private func debugLog(_ label: String, data: Data) {
        #if DEBUG
        let preview = String(data: data, encoding: .utf8).map { String($0.prefix(300)) } ?? "binary"
        print("[API] \(label):", preview)
        #endif
    }

    /// Builds a request; adds `Authorization` only when `token` is non-empty after trimming.
    private func makeRequest(url: URL, method: String, token: String?, body: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let t = token?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
            request.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    func fetchFlameoContext(accessToken: String?) async throws -> FlameoContext {
        guard let url = URL(string: "/api/flameo/context", relativeTo: baseURL) else {
            throw APIServiceError.invalidURL
        }
        #if DEBUG
        let hasToken = accessToken?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        print("[API] GET /api/flameo/context token:", hasToken ? "present" : "nil")
        #endif
        let request = makeRequest(url: url, method: "GET", token: accessToken, body: nil)
        let (data, response) = try await urlSession.data(for: request)
        debugLog("flameo/context", data: data)
        guard let http = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        if http.statusCode == 401 {
            throw APIServiceError.unauthorized
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8)
            throw APIServiceError.httpStatus(code: http.statusCode, body: text)
        }
        do {
            return try Self.jsonDecoder.decode(FlameoContext.self, from: data)
        } catch {
            #if DEBUG
            print("[API] flameo/context decode error:", error)
            #endif
            throw APIServiceError.decodingFailed
        }
    }

    private func get<T: Decodable>(path: String, accessToken: String?) async throws -> T {
        let data = try await request(path: path, method: "GET", accessToken: accessToken, body: nil)
        do {
            return try Self.jsonDecoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[API] GET decode failed", path, error)
            debugLog("decode_error", data: data)
            #endif
            throw APIServiceError.decodingFailed
        }
    }

    /// Returns fires or empty array on HTTP/decode failure (never throws).
    func fetchActiveFires(accessToken: String? = nil) async -> [FirePoint] {
        guard let url = URL(string: "/api/active-fires", relativeTo: baseURL) else {
            #if DEBUG
            print("[fires] invalid base URL")
            #endif
            return []
        }
        let req = makeRequest(url: url, method: "GET", token: accessToken, body: nil)
        do {
            let (data, response) = try await urlSession.data(for: req)
            #if DEBUG
            if let str = String(data: data, encoding: .utf8) {
                print("[fires] raw:", String(str.prefix(400)))
            }
            let sc = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("[API] GET /api/active-fires HTTP:", sc)
            #endif
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                #if DEBUG
                print("[fires] non-2xx or invalid response")
                #endif
                return []
            }
            if let fires = try? Self.jsonDecoder.decode([FirePoint].self, from: data), !fires.isEmpty {
                #if DEBUG
                print("[fires] decoded \(fires.count) direct")
                #endif
                return fires
            }
            struct ActiveFiresEnvelope: Decodable {
                let fires: [FirePoint]?
                let data: [FirePoint]?
                let features: [GeoJSONFireFeature]?
            }
            struct GeoJSONFireFeature: Decodable {
                let properties: FireGeoProperties?
                let geometry: FireGeoGeometry?
            }
            struct FireGeoProperties: Decodable {
                let id: String?
                let name: String?
                let source: String?
                let containmentPct: Double?
                let acresBurned: Double?

                enum CodingKeys: String, CodingKey {
                    case id, name, source
                    case containmentPct = "containment_pct"
                    case acresBurned = "acres_burned"
                }

                init(from decoder: Decoder) throws {
                    let c = try decoder.container(keyedBy: CodingKeys.self)
                    id = try c.decodeIfPresent(String.self, forKey: .id)
                    name = try c.decodeIfPresent(String.self, forKey: .name)
                    source = try c.decodeIfPresent(String.self, forKey: .source)
                    containmentPct = Self.flexDouble(c, .containmentPct)
                    acresBurned = Self.flexDouble(c, .acresBurned)
                }

                private static func flexDouble(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Double? {
                    if let d = try? c.decode(Double.self, forKey: key) { return d }
                    if let i = try? c.decode(Int.self, forKey: key) { return Double(i) }
                    return nil
                }
            }
            struct FireGeoGeometry: Decodable {
                let type: String?
                let coordinates: [Double]?

                enum CodingKeys: String, CodingKey {
                    case type, coordinates
                }

                init(from decoder: Decoder) throws {
                    let c = try decoder.container(keyedBy: CodingKeys.self)
                    type = try c.decodeIfPresent(String.self, forKey: .type)
                    coordinates = try? c.decode([Double].self, forKey: .coordinates)
                }
            }

            if let env = try? Self.jsonDecoder.decode(ActiveFiresEnvelope.self, from: data) {
                if let fires = env.fires ?? env.data, !fires.isEmpty {
                    #if DEBUG
                    print("[fires] decoded \(fires.count) envelope")
                    #endif
                    return fires
                }
                if let feats = env.features, !feats.isEmpty {
                    let mapped: [FirePoint] = feats.compactMap { f in
                        guard let coords = f.geometry?.coordinates, coords.count >= 2 else { return nil }
                        let lon = coords[0]
                        let lat = coords[1]
                        let p = f.properties
                        let id = p?.id ?? String(format: "%.5f,%.5f", lat, lon)
                        return FirePoint(
                            id: id,
                            name: p?.name,
                            lat: lat,
                            lon: lon,
                            containmentPct: p?.containmentPct,
                            acresBurned: p?.acresBurned,
                            source: p?.source
                        )
                    }
                    if !mapped.isEmpty {
                        #if DEBUG
                        print("[fires] decoded \(mapped.count) from GeoJSON features")
                        #endif
                        return mapped
                    }
                }
            }
            #if DEBUG
            print("[fires] no fires decoded from response")
            #endif
            return []
        } catch {
            #if DEBUG
            print("[fires] request error:", error)
            #endif
            return []
        }
    }

    /// Best-effort: returns `[]` on HTTP/decode failures (logged in DEBUG) so the map still loads fires.
    func fetchLiveShelters(state: String = "NC", accessToken: String? = nil) async throws -> [ShelterPoint] {
        let encoded = state.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? state
        let path = "/api/shelters/live?state=\(encoded)"
        do {
            let data = try await request(path: path, method: "GET", accessToken: accessToken, body: nil)
            debugLog("shelters/live", data: data)
            if let list = try? Self.jsonDecoder.decode([ShelterPoint].self, from: data) {
                return list
            }
            struct SheltersEnvelope: Decodable {
                let shelters: [ShelterPoint]?
            }
            if let envelope = try? Self.jsonDecoder.decode(SheltersEnvelope.self, from: data) {
                return envelope.shelters ?? []
            }
            #if DEBUG
            print("[API] shelters/live: decode failed")
            #endif
            return []
        } catch {
            #if DEBUG
            print("[API] shelters/live error:", error)
            #endif
            return []
        }
    }

    func flameoContext(accessToken: String?) async throws -> Data {
        try await request(path: "/api/flameo/context", method: "GET", accessToken: accessToken, body: nil)
    }

    func activeFires(accessToken: String?) async throws -> Data {
        try await request(path: "/api/active-fires", method: "GET", accessToken: accessToken, body: nil)
    }

    func sheltersLive(accessToken: String?) async throws -> Data {
        try await request(path: "/api/shelters/live", method: "GET", accessToken: accessToken, body: nil)
    }

    func weather(accessToken: String?) async throws -> Data {
        try await request(path: "/api/weather", method: "GET", accessToken: accessToken, body: nil)
    }

    func patchProfile(accessToken: String?, body: Data) async throws -> Data {
        try await request(path: "/api/profile", method: "PATCH", accessToken: accessToken, body: body)
    }

    func sendFamilyInvite(email: String, token: String?) async throws {
        struct Body: Encodable {
            let email: String
        }

        try await post(path: "/api/family/send-invite", body: Body(email: email), accessToken: token)
    }

    // MARK: - Emergency responder / station

    func verifyInviteCode(code: String, role: String, token: String?) async -> Bool {
        struct VerifyBody: Encodable {
            let code: String
            let role: String
        }

        struct VerifyResponse: Decodable {
            let valid: Bool?
            let ok: Bool?
            let success: Bool?
            let verified: Bool?
        }

        guard let url = URL(string: "/api/invite/verify", relativeTo: baseURL) else {
            #if DEBUG
            print("[API] verifyInviteCode: invalid URL")
            #endif
            return false
        }
        do {
            let body = try Self.jsonEncoder.encode(VerifyBody(code: code, role: role))
            let req = makeRequest(url: url, method: "POST", token: token, body: body)
            let (data, response) = try await urlSession.data(for: req)
            guard let http = response as? HTTPURLResponse else { return false }
            #if DEBUG
            print("[API] POST /api/invite/verify HTTP:", http.statusCode)
            if let s = String(data: data, encoding: .utf8) {
                print("[API] verifyInviteCode body:", String(s.prefix(400)))
            }
            #endif
            if http.statusCode == 400 || http.statusCode == 404 || http.statusCode == 401 {
                return false
            }
            guard (200 ... 299).contains(http.statusCode) else {
                return false
            }
            if let decoded = try? Self.jsonDecoder.decode(VerifyResponse.self, from: data) {
                return decoded.valid == true
                    || decoded.ok == true
                    || decoded.success == true
                    || decoded.verified == true
            }
            return http.statusCode == 200
        } catch {
            #if DEBUG
            print("[API] verifyInviteCode error:", error)
            #endif
            return false
        }
    }

    func validateStationInvite(code: String, token: String?) async throws -> StationInviteValidation {
        struct Body: Encodable {
            let code: String
        }

        let data = try await request(
            path: "/api/station/invite/validate",
            method: "POST",
            accessToken: token,
            body: try Self.jsonEncoder.encode(Body(code: code))
        )
        return try Self.jsonDecoder.decode(StationInviteValidation.self, from: data)
    }

    func acceptStationInvite(code: String, token: String?) async throws -> String {
        struct Body: Encodable {
            let code: String
        }

        let data = try await request(
            path: "/api/station/invite/accept",
            method: "POST",
            accessToken: token,
            body: try Self.jsonEncoder.encode(Body(code: code))
        )
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let name = json["station_name"] as? String { return name }
            if let name = json["stationName"] as? String { return name }
            if let name = json["name"] as? String { return name }
        }
        return "station"
    }

    func fetchHouseholds(token: String?) async throws -> [HouseholdPin] {
        let data = try await request(path: "/api/responder/evacuees", method: "GET", accessToken: token, body: nil)
        if let list = try? Self.jsonDecoder.decode([HouseholdPin].self, from: data) {
            return list
        }
        struct Envelope: Decodable {
            let households: [HouseholdPin]?
            let data: [HouseholdPin]?
            let evacuees: [HouseholdPin]?
        }
        let env = try Self.jsonDecoder.decode(Envelope.self, from: data)
        return env.households ?? env.data ?? env.evacuees ?? []
    }

    func fetchCommandContext(token: String?) async throws -> FlameoCommandContext {
        try await get(path: "/api/flameo/command-context", accessToken: token)
    }

    func fetchCommandBriefing(context: FlameoCommandContext, token: String?) async throws -> String {
        struct Body: Encodable {
            let commandContext: FlameoCommandContext
        }

        let briefingEncoder = JSONEncoder()
        briefingEncoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try await request(
            path: "/api/flameo/command-briefing",
            method: "POST",
            accessToken: token,
            body: try briefingEncoder.encode(Body(commandContext: context))
        )
        struct BriefingEnvelope: Decodable {
            let briefing: String?
        }
        if let env = try? Self.jsonDecoder.decode(BriefingEnvelope.self, from: data),
           let b = env.briefing, !b.isEmpty {
            return b
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let b = json["briefing"] as? String {
            return b
        }
        throw APIServiceError.decodingFailed
    }

    func updateFirefighterLocation(lat: Double, lng: Double, token: String?) async {
        struct Body: Encodable {
            let lat: Double
            let lng: Double
        }

        do {
            let data = try Self.jsonEncoder.encode(Body(lat: lat, lng: lng))
            _ = try await request(
                path: "/api/station/firefighter/location",
                method: "PATCH",
                accessToken: token,
                body: data
            )
        } catch {
            #if DEBUG
            print("[API] PATCH /api/station/firefighter/location error:", error)
            #endif
        }
    }

    func clearHouse(userId: String?, address: String, clearedStatus: String, token: String?) async throws {
        struct Body: Encodable {
            let target_user_id: String?
            let target_address: String
            let cleared_status: String
        }

        let data = try Self.jsonEncoder.encode(
            Body(target_user_id: userId, target_address: address, cleared_status: clearedStatus)
        )
        _ = try await request(
            path: "/api/station/firefighter/clear-house",
            method: "POST",
            accessToken: token,
            body: data
        )
    }

    func updateResponderFieldStatus(_ status: String, token: String?) async throws {
        struct Body: Encodable {
            let field_status: String
        }

        let data = try Self.jsonEncoder.encode(Body(field_status: status))
        _ = try await request(
            path: "/api/responder/update-status",
            method: "PATCH",
            accessToken: token,
            body: data
        )
    }

    private func post<B: Encodable>(path: String, body: B, accessToken: String?) async throws {
        let data = try Self.jsonEncoder.encode(body)
        _ = try await request(path: path, method: "POST", accessToken: accessToken, body: data)
    }

    private func request(
        path: String,
        method: String,
        accessToken: String?,
        body: Data?
    ) async throws -> Data {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIServiceError.invalidURL
        }
        let request = makeRequest(url: url, method: method, token: accessToken, body: body)
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIServiceError.httpStatus(code: -1, body: nil)
        }
        #if DEBUG
        print("[API]", method, path, "HTTP:", http.statusCode)
        #endif
        guard (200 ... 299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8)
            #if DEBUG
            print("[API] error body:", text?.prefix(400) ?? "")
            #endif
            throw APIServiceError.httpStatus(code: http.statusCode, body: text)
        }
        return data
    }
}

/// Response from `POST /api/station/invite/validate`.
struct StationInviteValidation: Decodable {
    let valid: Bool?
    let ok: Bool?
    let success: Bool?
    let stationName: String?
    let station_name: String?
    let incidentName: String?
    let incident_name: String?

    var isValid: Bool {
        valid == true || ok == true || success == true
    }

    var resolvedStationName: String? {
        stationName ?? station_name
    }

    var resolvedIncidentName: String? {
        incidentName ?? incident_name
    }
}
