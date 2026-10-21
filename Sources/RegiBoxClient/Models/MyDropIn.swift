import Foundation

/// Represents a drop-in class the user is registered for
/// Parsed from the "OS MEUS DROP-INS" section on the main page
public struct MyDropIn: Sendable {
    /// Class ID (from id_aula parameter)
    public let classId: String

    /// Box ID where the drop-in class is held (from id_box_dropin parameter)
    public let boxId: String

    /// Name of the box (e.g., "MATCHBOX CROSSFIT")
    public let boxName: String

    /// Date display text (e.g., "16 FEV")
    public let dateText: String

    /// Start time in HH:mm format
    public let startTime: String

    /// End time in HH:mm format
    public let endTime: String

    /// Google Maps directions URL (if available)
    public let mapsURL: String?

    /// Box logo URL
    public let logoURL: String?

    public init(
        classId: String,
        boxId: String,
        boxName: String,
        dateText: String,
        startTime: String,
        endTime: String,
        mapsURL: String? = nil,
        logoURL: String? = nil
    ) {
        self.classId = classId
        self.boxId = boxId
        self.boxName = boxName
        self.dateText = dateText
        self.startTime = startTime
        self.endTime = endTime
        self.mapsURL = mapsURL
        self.logoURL = logoURL
    }

    /// Time range formatted as "HH:mm -> HH:mm"
    public var timeRange: String {
        "\(startTime) -> \(endTime)"
    }
}

extension MyDropIn: Equatable {
    public static func == (lhs: MyDropIn, rhs: MyDropIn) -> Bool {
        lhs.classId == rhs.classId && lhs.boxId == rhs.boxId
    }
}

extension MyDropIn: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(classId)
        hasher.combine(boxId)
    }
}
