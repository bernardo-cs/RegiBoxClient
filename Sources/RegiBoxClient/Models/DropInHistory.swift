import Foundation

/// Summary statistics for a user's drop-in history
public struct DropInHistorySummary: Sendable {
    /// Total number of drop-in registrations (Inscrições)
    public let registrations: Int

    /// Total number of confirmed attendances (Presenças)
    public let attendances: Int

    /// Total number of absences (Faltas)
    public let absences: Int

    /// Individual drop-in history entries
    public let entries: [DropInHistoryEntry]

    public init(registrations: Int, attendances: Int, absences: Int, entries: [DropInHistoryEntry]) {
        self.registrations = registrations
        self.attendances = attendances
        self.absences = absences
        self.entries = entries
    }
}

/// A single entry in the drop-in history
public struct DropInHistoryEntry: Sendable {
    /// Date in YYYY-MM-DD format
    public let date: String

    /// Start time (e.g., "18:20")
    public let startTime: String

    /// End time (e.g., "19:20")
    public let endTime: String

    /// Box ID extracted from logo path (e.g., "313")
    public let boxId: String

    /// Box abbreviation (e.g., "U", "C")
    public let boxAbbreviation: String

    /// Class name (e.g., "Wod", "RM/MOB", "CHAMP")
    public let className: String

    /// Whether attendance was confirmed (thumb_up icon present)
    public let isPresent: Bool

    public init(date: String, startTime: String, endTime: String, boxId: String, boxAbbreviation: String, className: String, isPresent: Bool) {
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.boxId = boxId
        self.boxAbbreviation = boxAbbreviation
        self.className = className
        self.isPresent = isPresent
    }
}
