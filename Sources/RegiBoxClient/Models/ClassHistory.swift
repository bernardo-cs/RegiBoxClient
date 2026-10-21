import Foundation

/// Summary statistics for a user's class history
public struct ClassHistorySummary: Sendable {
    /// Total number of registrations (Inscrições)
    public let registrations: Int

    /// Total number of attendances (Presenças)
    public let attendances: Int

    /// Total number of absences (Faltas)
    public let absences: Int

    /// Monthly attendance data from the chart
    public let monthlyData: [MonthlyAttendance]

    public init(registrations: Int, attendances: Int, absences: Int, monthlyData: [MonthlyAttendance]) {
        self.registrations = registrations
        self.attendances = attendances
        self.absences = absences
        self.monthlyData = monthlyData
    }
}

/// A single month's attendance count from the chart
public struct MonthlyAttendance: Sendable {
    /// Month abbreviation (e.g., "Mar", "Abr", "Mai")
    public let month: String

    /// Attendance count for that month
    public let count: Int

    public init(month: String, count: Int) {
        self.month = month
        self.count = count
    }
}

/// Attendance status for a class history entry
public enum AttendanceStatus: String, Sendable {
    case present = "Presente"
    case absent = "Falta"
    case noRecord = "Sem registo"

    /// Initialize from Portuguese status text
    public init(fromText text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch trimmed {
        case "Presente":
            self = .present
        case "Falta":
            self = .absent
        default:
            self = .noRecord
        }
    }
}

/// A single entry in the class history (one class attendance record)
public struct ClassHistoryEntry: Sendable {
    /// Date as displayed (e.g., "17 Fev 2026")
    public let date: String

    /// Class name (e.g., "CROSS TRAINING")
    public let className: String

    /// Attendance status
    public let status: AttendanceStatus

    public init(date: String, className: String, status: AttendanceStatus) {
        self.date = date
        self.className = className
        self.status = status
    }
}
