//
//  APIService.swift
//  Minutes Matter
//

import Foundation

enum APIServiceError: LocalizedError {
    case invalidURL
    case httpStatus(code: Int, body: String?)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
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

    func fetchFlameoContext(accessToken: String?) async throws -> FlameoContext {
        try await get(path: "/api/flameo/context", accessToken: accessToken)
    }

    private func get<T: Decodable>(path: String, accessToken: String?) async throws -> T {
        let data = try await request(path: path, method: "GET", accessToken: accessToken, body: nil)
        do {
            return try Self.jsonDecoder.decode(T.self, from: data)
        } catch {
            throw APIServiceError.decodingFailed
        }
    }

    func fetchActiveFires() async throws -> [FirePoint] {
        let data = try await request(path: "/api/active-fires", method: "GET", accessToken: nil, body: nil)
        if let list = try? Self.jsonDecoder.decode([FirePoint].self, from: data) {
            return list
        }
        do {
            let wrapped = try Self.jsonDecoder.decode(ActiveFiresEnvelope.self, from: data)
            return wrapped.fires ?? wrapped.data ?? []
        } catch {
            throw APIServiceError.decodingFailed
        }
    }

    func fetchLiveShelters(state: String = "NC") async throws -> [ShelterPoint] {
        let encoded = state.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? state
        let path = "/api/shelters/live?state=\(encoded)"
        let data = try await request(path: path, method: "GET", accessToken: nil, body: nil)
        if let list = try? Self.jsonDecoder.decode([ShelterPoint].self, from: data) {
            return list
        }
        do {
            let envelope = try Self.jsonDecoder.decode(SheltersLiveEnvelope.self, from: data)
            return envelope.shelters
        } catch {
            throw APIServiceError.decodingFailed
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

    func verifyInviteCode(code: String, role: String, token: String?) async throws -> Bool {
        struct Body: Encodable {
            let code: String
            let role: String
        }

        let data = try await request(
            path: "/api/invite/verify",
            method: "POST",
            accessToken: token,
            body: try Self.jsonEncoder.encode(Body(code: code, role: role))
        )
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let valid = json["valid"] as? Bool { return valid }
            if let ok = json["ok"] as? Bool { return ok }
            if let success = json["success"] as? Bool { return success }
        }
        return true
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

        let data = try await request(
            path: "/api/flameo/command-briefing",
            method: "POST",
            accessToken: token,
            body: try Self.jsonEncoder.encode(Body(commandContext: context))
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
            // Fire-and-forget
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
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIServiceError.httpStatus(code: -1, body: nil)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8)
            throw APIServiceError.httpStatus(code: http.statusCode, body: text)
        }
        return data
    }
}

private struct ActiveFiresEnvelope: Decodable {
    let fires: [FirePoint]?
    let data: [FirePoint]?
}

private struct SheltersLiveEnvelope: Decodable {
    let shelters: [ShelterPoint]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        shelters = try c.decodeIfPresent([ShelterPoint].self, forKey: .shelters) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case shelters
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
