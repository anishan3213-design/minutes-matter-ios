//
//  ShelterPoint.swift
//  Minutes Matter
//

import CoreLocation
import Foundation

struct ShelterPoint: Codable, Identifiable {
    let id: String
    let name: String
    let lat: Double
    let lon: Double
    let verified: Bool?
    let capacity: Int?
    let currentOccupancy: Int?
    let distanceMiles: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, lat, lon, verified, capacity
        case currentOccupancy = "current_occupancy"
        case distanceMiles = "distance_miles"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        lat = try Self.decodeDouble(c, key: .lat)
        lon = try Self.decodeDouble(c, key: .lon)
        verified = try c.decodeIfPresent(Bool.self, forKey: .verified)
        capacity = try Self.decodeOptionalInt(c, key: .capacity)
        currentOccupancy = try Self.decodeOptionalInt(c, key: .currentOccupancy)
        distanceMiles = Self.decodeOptionalDouble(c, key: .distanceMiles)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
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
