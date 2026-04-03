//
//  FlameoContext.swift
//  Minutes Matter
//

import Foundation

struct FlameoContext: Decodable {
    let role: String?
    let anchors: [FlameoAnchor]?
    let incidentsNearby: [FlameoIncident]?
    let weatherSummary: FlameoWeather?
    let sheltersRanked: [FlameoShelter]?
    let hazardSitesNearby: [FlameoHazard]?
    let flags: FlameoFlags?
    let alertRadiusMiles: Double?
    let status: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case role
        case anchors
        case incidentsNearby = "incidents_nearby"
        case weatherSummary = "weather_summary"
        case sheltersRanked = "shelters_ranked"
        case hazardSitesNearby = "hazard_sites_nearby"
        case flags
        case alertRadiusMiles = "alert_radius_miles"
        case status
        case message
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        role = try c.decodeIfPresent(String.self, forKey: .role)
        anchors = try c.decodeIfPresent([FlameoAnchor].self, forKey: .anchors)
        incidentsNearby = try c.decodeIfPresent([FlameoIncident].self, forKey: .incidentsNearby)
        weatherSummary = try c.decodeIfPresent(FlameoWeather.self, forKey: .weatherSummary)
        sheltersRanked = try c.decodeIfPresent([FlameoShelter].self, forKey: .sheltersRanked)
        hazardSitesNearby = try c.decodeIfPresent([FlameoHazard].self, forKey: .hazardSitesNearby)
        flags = try c.decodeIfPresent(FlameoFlags.self, forKey: .flags)
        alertRadiusMiles = Self.decodeFlexibleDouble(c, key: .alertRadiusMiles)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        message = try c.decodeIfPresent(String.self, forKey: .message)
    }

    private static func decodeFlexibleDouble(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Double? {
        if let d = try? c.decode(Double.self, forKey: key) { return d }
        if let i = try? c.decode(Int.self, forKey: key) { return Double(i) }
        return nil
    }
}

struct FlameoAnchor: Codable {
    let id: String
    let label: String
    let lat: Double
    let lon: Double
}

struct FlameoIncident: Decodable {
    let id: String
    let name: String?
    let distanceMiles: Double
    let lat: Double
    let lon: Double
    let source: String?

    enum CodingKeys: String, CodingKey {
        case id, name, lat, lon, lng, source
        case distanceMiles = "distance_miles"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        lat = try Self.decodeFlexibleDoubleRequired(c, key: .lat)
        if let v = try? Self.decodeFlexibleDoubleRequired(c, key: .lon) {
            lon = v
        } else {
            lon = try Self.decodeFlexibleDoubleRequired(c, key: .lng)
        }
        source = try c.decodeIfPresent(String.self, forKey: .source)
        if let d = try? c.decode(Double.self, forKey: .distanceMiles) {
            distanceMiles = d
        } else if let i = try? c.decode(Int.self, forKey: .distanceMiles) {
            distanceMiles = Double(i)
        } else {
            distanceMiles = 0
        }
    }

    private static func decodeFlexibleDoubleRequired(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Double {
        if let d = try? c.decode(Double.self, forKey: key) { return d }
        if let i = try? c.decode(Int.self, forKey: key) { return Double(i) }
        throw DecodingError.dataCorruptedError(forKey: key, in: c, debugDescription: "Expected number")
    }
}

struct FlameoWeather: Decodable {
    let tempF: Double?
    let windMph: Double?
    let windDir: String?
    let fireRisk: String?

    enum CodingKeys: String, CodingKey {
        case tempF = "temp_f"
        case windMph = "wind_mph"
        case windDir = "wind_dir"
        case fireRisk = "fire_risk"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tempF = Self.decodeFlexibleDouble(c, key: .tempF)
        windMph = Self.decodeFlexibleDouble(c, key: .windMph)
        windDir = try c.decodeIfPresent(String.self, forKey: .windDir)
        fireRisk = try c.decodeIfPresent(String.self, forKey: .fireRisk)
    }

    private static func decodeFlexibleDouble(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Double? {
        if let d = try? c.decode(Double.self, forKey: key) { return d }
        if let i = try? c.decode(Int.self, forKey: key) { return Double(i) }
        return nil
    }
}

struct FlameoShelter: Decodable {
    let name: String
    let lat: Double
    let lon: Double
    let travelMinutes: Double?
    let distanceMiles: Double?
    let routeSummary: String?
    let routeAvoidsFire: Bool?
    let verified: Bool?
    let phone: String?

    enum CodingKeys: String, CodingKey {
        case name, lat, lon, lng, verified, phone
        case travelMinutes = "travel_minutes"
        case distanceMiles = "distance_miles"
        case routeSummary = "route_summary"
        case routeAvoidsFire = "route_avoids_fire"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        lat = try Self.decodeFlexibleDoubleRequired(c, key: .lat)
        if let v = try? Self.decodeFlexibleDoubleRequired(c, key: .lon) {
            lon = v
        } else {
            lon = try Self.decodeFlexibleDoubleRequired(c, key: .lng)
        }
        travelMinutes = Self.decodeFlexibleDouble(c, key: .travelMinutes)
        distanceMiles = Self.decodeFlexibleDouble(c, key: .distanceMiles)
        routeSummary = try c.decodeIfPresent(String.self, forKey: .routeSummary)
        routeAvoidsFire = try c.decodeIfPresent(Bool.self, forKey: .routeAvoidsFire)
        verified = try c.decodeIfPresent(Bool.self, forKey: .verified)
        phone = try c.decodeIfPresent(String.self, forKey: .phone)
    }

    private static func decodeFlexibleDoubleRequired(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Double {
        if let d = try? c.decode(Double.self, forKey: key) { return d }
        if let i = try? c.decode(Int.self, forKey: key) { return Double(i) }
        throw DecodingError.dataCorruptedError(forKey: key, in: c, debugDescription: "Expected number")
    }

    private static func decodeFlexibleDouble(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Double? {
        if let d = try? c.decode(Double.self, forKey: key) { return d }
        if let i = try? c.decode(Int.self, forKey: key) { return Double(i) }
        return nil
    }
}

struct FlameoHazard: Decodable {
    let id: String
    let name: String
    let type: String
    let distanceMiles: Double
    let riskNote: String?

    enum CodingKeys: String, CodingKey {
        case id, name, type
        case distanceMiles = "distance_miles"
        case riskNote = "risk_note"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        type = try c.decode(String.self, forKey: .type)
        if let d = try? c.decode(Double.self, forKey: .distanceMiles) {
            distanceMiles = d
        } else if let i = try? c.decode(Int.self, forKey: .distanceMiles) {
            distanceMiles = Double(i)
        } else {
            distanceMiles = 0
        }
        riskNote = try c.decodeIfPresent(String.self, forKey: .riskNote)
    }
}

struct FlameoFlags: Codable {
    let hasConfirmedThreat: Bool?
    let noData: Bool?
    let feedsUnavailable: Bool?

    enum CodingKeys: String, CodingKey {
        case hasConfirmedThreat = "has_confirmed_threat"
        case noData = "no_data"
        case feedsUnavailable = "feeds_unavailable"
    }
}
