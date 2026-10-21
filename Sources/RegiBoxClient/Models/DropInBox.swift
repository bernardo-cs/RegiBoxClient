import Foundation

/// Represents a fitness box/gym available for drop-in visits
public struct DropInBox: Identifiable, Codable, Sendable {
    /// Unique identifier for the box
    public let id: String

    /// Display name of the box
    public let name: String

    /// Street address of the box
    public let address: String?

    /// GPS latitude coordinate
    public let latitude: Double?

    /// GPS longitude coordinate
    public let longitude: Double?

    /// ACS token for drop-in API calls (per-box, extracted from dropin_find_box.php)
    public let acsToken: String?

    /// Parent box code used by the current drop-in routes (sub-box IDs can be negative).
    public let code: String
    public let subBox: Int

    /// URL for the box's logo image
    public var logoURL: URL? {
        let suffix = subBox > 0 ? "\(subBox)" : ""
        return URL(string: "https://www.regibox.pt/escolas/\(code)/logotipo\(suffix).jpg")
    }

    public init(
        id: String,
        name: String,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        acsToken: String? = nil,
        code: String? = nil,
        subBox: Int = 0
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.acsToken = acsToken
        self.code = code ?? id
        self.subBox = subBox
    }
}

extension DropInBox {
    /// Calculate distance in km from this box to the given coordinates using the Haversine formula.
    /// Returns `nil` if the box has no GPS coordinates.
    public func distanceTo(latitude: Double, longitude: Double) -> Double? {
        guard let boxLat = self.latitude, let boxLng = self.longitude else { return nil }

        let earthRadiusKm = 6371.0
        let dLat = (boxLat - latitude) * .pi / 180.0
        let dLng = (boxLng - longitude) * .pi / 180.0
        let lat1 = latitude * .pi / 180.0
        let lat2 = boxLat * .pi / 180.0

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusKm * c
    }
}

extension DropInBox: Equatable {
    public static func == (lhs: DropInBox, rhs: DropInBox) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

extension DropInBox: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
