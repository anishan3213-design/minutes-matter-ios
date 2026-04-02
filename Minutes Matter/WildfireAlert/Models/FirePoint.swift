//
//  FirePoint.swift
//  Minutes Matter
//

import CoreLocation
import SwiftUI

struct FirePoint: Codable, Identifiable {
    let id: String
    let name: String?
    let lat: Double
    let lon: Double
    let containmentPct: Double?
    let acresBurned: Double?
    let source: String?

    enum CodingKeys: String, CodingKey {
        case id, name, lat, lon, source
        case containmentPct = "containment_pct"
        case acresBurned = "acres_burned"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        lat = try Self.decodeDouble(c, key: .lat)
        lon = try Self.decodeDouble(c, key: .lon)
        containmentPct = Self.decodeOptionalDouble(c, key: .containmentPct)
        acresBurned = Self.decodeOptionalDouble(c, key: .acresBurned)
        source = try c.decodeIfPresent(String.self, forKey: .source)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var containmentColor: Color {
        guard let pct = containmentPct else {
            return Color(hex: "#dc2626")
        }
        switch pct {
        case 75...:
            return Color(hex: "#22c55e")
        case 50 ..< 75:
            return Color(hex: "#eab308")
        case 25 ..< 50:
            return Color(hex: "#f97316")
        default:
            return Color(hex: "#dc2626")
        }
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
}
