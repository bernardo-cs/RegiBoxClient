import Foundation

/// Status of a class
public enum ClassStatus: String, Sendable, CaseIterable {
    case completed = "completed"
    case inProgress = "in_progress"
    case available = "available"

    /// Initialize from Portuguese status text
    public init(fromText text: String) {
        let lowercased = text.lowercased()
        if lowercased.contains("conclu") {
            self = .completed
        } else if lowercased.contains("decorrer") {
            self = .inProgress
        } else {
            self = .available
        }
    }
}

/// Represents a fitness class/session at a box
public struct Class: Identifiable, Sendable {
    /// Unique identifier for the class
    public let id: String

    /// Name of the class (e.g., "CROSS TRAINING", "FIT")
    public let name: String

    /// Location within the box (e.g., "Black Box")
    public let location: String

    /// Start time in HH:mm format
    public let startTime: String

    /// End time in HH:mm format
    public let endTime: String

    /// Number of currently enrolled participants
    public let enrolled: Int

    /// Maximum capacity
    public let capacity: Int

    /// Current status of the class
    public let status: ClassStatus

    /// Date of the class in YYYY-MM-DD format
    public let date: String

    /// Full URL for booking (if registration is available)
    public let bookingURL: String?

    /// Full URL for cancelling (if user is registered)
    public let cancelURL: String?

    /// Current app route for the detailed class view.
    public let detailsURL: String?

    /// Whether the user can book this class (INSCREVER button exists)
    public let canBook: Bool

    /// Whether the user is already registered for this class
    public let isRegistered: Bool

    public init(
        id: String,
        name: String,
        location: String,
        startTime: String,
        endTime: String,
        enrolled: Int,
        capacity: Int,
        status: ClassStatus,
        date: String,
        bookingURL: String? = nil,
        cancelURL: String? = nil,
        detailsURL: String? = nil,
        canBook: Bool = false,
        isRegistered: Bool = false
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.startTime = startTime
        self.endTime = endTime
        self.enrolled = enrolled
        self.capacity = capacity
        self.status = status
        self.date = date
        self.bookingURL = bookingURL
        self.cancelURL = cancelURL
        self.detailsURL = detailsURL
        self.canBook = canBook
        self.isRegistered = isRegistered
    }

    /// Time range formatted as "HH:mm - HH:mm"
    public var timeRange: String {
        "\(startTime) - \(endTime)"
    }

    /// Capacity formatted as "X de Y"
    public var capacityText: String {
        "\(enrolled) de \(capacity)"
    }

    /// Whether there are spots available
    public var hasAvailability: Bool {
        enrolled < capacity && status == .available
    }
}

extension Class: Equatable {
    public static func == (lhs: Class, rhs: Class) -> Bool {
        lhs.id == rhs.id && lhs.date == rhs.date
    }
}

extension Class: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(date)
    }
}
