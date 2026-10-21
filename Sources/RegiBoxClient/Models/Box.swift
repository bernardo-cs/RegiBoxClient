import Foundation

/// Represents a fitness box/gym in the RegiBox platform
public struct Box: Identifiable, Codable, Sendable {
    /// Unique identifier for the box
    public let id: String

    /// Display name of the box
    public let name: String

    /// URL for the box's logo image
    public var logoURL: URL? {
        URL(string: "https://www.regibox.pt/escolas/\(id)/logotipo.jpg")
    }

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

extension Box: Equatable {
    public static func == (lhs: Box, rhs: Box) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

extension Box: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
