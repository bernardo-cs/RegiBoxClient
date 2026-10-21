import Foundation

/// Status of a drop-in class
public enum DropInClassStatus: String, Sendable, CaseIterable {
    case completed = "completed"
    case inProgress = "in_progress"
    case available = "available"
    case registered = "registered"
    case unavailable = "unavailable"

    /// Initialize from Portuguese status text or button presence
    public init(fromText text: String, hasRegisterButton: Bool = false, hasCancelButton: Bool = false) {
        let lowercased = text.lowercased()
        if lowercased.contains("conclu") {
            self = .completed
        } else if lowercased.contains("decorrer") {
            self = .inProgress
        } else if hasCancelButton {
            self = .registered
        } else if hasRegisterButton {
            self = .available
        } else {
            self = .unavailable
        }
    }
}

/// Represents a fitness class available for drop-in registration
public struct DropInClass: Identifiable, Sendable {
    /// Unique identifier for the class
    public let id: String

    /// Name of the class (e.g., "WOD", "OPENBOX", "PILATES")
    public let name: String

    /// Location within the box (e.g., "Aves", "Box 2")
    public let location: String

    /// Coach shown on the current drop-in class card.
    public let instructor: String?

    /// Start time in HH:mm format
    public let startTime: String

    /// End time in HH:mm format
    public let endTime: String

    /// Current status of the class
    public let status: DropInClassStatus

    /// Date of the class in YYYY-MM-DD format
    public let date: String

    /// The box ID where this class is held
    public let boxId: String

    public init(
        id: String,
        name: String,
        location: String,
        instructor: String? = nil,
        startTime: String,
        endTime: String,
        status: DropInClassStatus,
        date: String,
        boxId: String
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.instructor = instructor
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.date = date
        self.boxId = boxId
    }

    /// Time range formatted as "HH:mm -> HH:mm"
    public var timeRange: String {
        "\(startTime) -> \(endTime)"
    }

    /// Whether the user can register for this class
    public var canRegister: Bool {
        status == .available
    }

    /// Whether the user can cancel registration for this class
    public var canCancel: Bool {
        status == .registered
    }
}

extension DropInClass: Equatable {
    public static func == (lhs: DropInClass, rhs: DropInClass) -> Bool {
        lhs.id == rhs.id && lhs.date == rhs.date && lhs.boxId == rhs.boxId
    }
}

extension DropInClass: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(date)
        hasher.combine(boxId)
    }
}
