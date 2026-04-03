//
//  ShelterPoint.swift
//  Minutes Matter
//

import CoreLocation
import Foundation

/// Live shelter from `/api/shelters/live` — coordinates use **`lng`** (not `lon`).
struct ShelterPoint: Codable, Identifiable {
    let id: String
    let name: String
    let lat: Double
    let lng: Double
    let verified: Bool?
    let capacity: Int?
    let currentOccupancy: Int?
    let distanceMiles: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, lat, lng, lon, verified, capacity
        case currentOccupancy = "current_occupancy"
        case distanceMiles = "distance_miles"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        lat = try Self.decodeDouble(c, key: .lat)
        if let v = Self.decodeOptionalDouble(c, key: .lng) {
            lng = v
        } else if let v = Self.decodeOptionalDouble(c, key: .lon) {
            lng = v
        } else {
            throw DecodingError.dataCorruptedError(forKey: .lng, in: c, debugDescription: "Missing lng/lon")
        }
        verified = try c.decodeIfPresent(Bool.self, forKey: .verified)
        capacity = try Self.decodeOptionalInt(c, key: .capacity)
        currentOccupancy = try Self.decodeOptionalInt(c, key: .currentOccupancy)
        distanceMiles = Self.decodeOptionalDouble(c, key: .distanceMiles)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(lat, forKey: .lat)
        try c.encode(lng, forKey: .lng)
        try c.encodeIfPresent(verified, forKey: .verified)
        try c.encodeIfPresent(capacity, forKey: .capacity)
        try c.encodeIfPresent(currentOccupancy, forKey: .currentOccupancy)
        try c.encodeIfPresent(distanceMiles, forKey: .distanceMiles)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    private static func decodeDouble(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Double {
        if let d = try? c.decode(Double.self, forKey: key) { return d }
        if let i = try? c.decode(Int.self, forKey: key) { return Double(i) }
        throw DecodingError.dataCorruptedError(forKey: key, in: c, debugDescription: "Expected number")
    }

    private static func decodeOptionalDouble(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Double? {
        if let d = try? c.decode(Double.self, forKey: key) { return d }
        if let i = try? c.decode(Int.self, forKey: key) { return Double(i) }
        return nil
    }

    private static func decodeOptionalInt(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Int? {
        if let i = try? c.decode(Int.self, forKey: key) { return i }
        if let d = try? c.decode(Double.self, forKey: key) { return Int(d) }
        return nil
    }
}
