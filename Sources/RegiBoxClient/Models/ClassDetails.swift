import Foundation

/// An instructor/coach for a class
public struct Instructor: Sendable {
    /// Instructor's name
    public let name: String

    /// URL to instructor's photo
    public let photoURL: URL?

    public init(name: String, photoURL: URL? = nil) {
        self.name = name
        self.photoURL = photoURL
    }
}

extension Instructor: Equatable {}
extension Instructor: Hashable {}

/// A named workout section (for non-standard section names like "Hybrid Day", "Team WOD", etc.)
public struct WorkoutSection: Sendable, Equatable, Hashable {
    /// Section name (e.g., "Hybrid Day", "EMOM", "Team WOD")
    public let name: String

    /// Section content
    public let content: String

    public init(name: String, content: String) {
        self.name = name
        self.content = content
    }
}

/// Workout description with different sections
public struct Workout: Sendable {
    /// Warm-up exercises
    public let warmUp: String?

    /// Skill work
    public let skill: String?

    /// Strength exercises
    public let strength: String?

    /// Conditioning/metcon
    public let condition: String?

    /// Non-standard workout sections not covered by the 4 known fields
    public let additionalSections: [WorkoutSection]

    public init(
        warmUp: String? = nil,
        skill: String? = nil,
        strength: String? = nil,
        condition: String? = nil,
        additionalSections: [WorkoutSection] = []
    ) {
        self.warmUp = warmUp
        self.skill = skill
        self.strength = strength
        self.condition = condition
        self.additionalSections = additionalSections
    }

    /// Whether the workout has any content
    public var isEmpty: Bool {
        warmUp == nil && skill == nil && strength == nil && condition == nil && additionalSections.isEmpty
    }

    /// All non-empty sections as a formatted string
    public var formattedDescription: String {
        var parts: [String] = []

        if let warmUp = warmUp, !warmUp.isEmpty {
            parts.append("WARM-UP:\n\(warmUp)")
        }
        if let skill = skill, !skill.isEmpty {
            parts.append("SKILL:\n\(skill)")
        }
        if let strength = strength, !strength.isEmpty {
            parts.append("STRENGTH:\n\(strength)")
        }
        if let condition = condition, !condition.isEmpty {
            parts.append("CONDITIONING:\n\(condition)")
        }
        for section in additionalSections {
            parts.append("\(section.name.uppercased()):\n\(section.content)")
        }

        return parts.joined(separator: "\n\n")
    }
}

extension Workout: Equatable {
    public static func == (lhs: Workout, rhs: Workout) -> Bool {
        lhs.warmUp == rhs.warmUp
            && lhs.skill == rhs.skill
            && lhs.strength == rhs.strength
            && lhs.condition == rhs.condition
            && lhs.additionalSections == rhs.additionalSections
    }
}

/// A participant enrolled in a class
public struct Participant: Sendable {
    /// Participant's name
    public let name: String

    /// Position in the enrollment list (1-based)
    public let position: Int

    /// URL to participant's photo
    public let photoURL: URL?

    public init(name: String, position: Int, photoURL: URL? = nil) {
        self.name = name
        self.position = position
        self.photoURL = photoURL
    }
}

extension Participant: Equatable {}
extension Participant: Hashable {}

/// Detailed information about a class including instructors, workout, and participants
public struct ClassDetails: Sendable {
    /// Basic class information
    public let classInfo: Class

    /// Instructors/coaches for the class
    public let instructors: [Instructor]

    /// Workout description (may be nil if not published)
    public let workout: Workout?

    /// List of enrolled participants
    public let participants: [Participant]

    public init(
        classInfo: Class,
        instructors: [Instructor],
        workout: Workout?,
        participants: [Participant]
    ) {
        self.classInfo = classInfo
        self.instructors = instructors
        self.workout = workout
        self.participants = participants
    }

    /// Instructor names joined with commas
    public var instructorNames: String {
        instructors.map(\.name).joined(separator: ", ")
    }
}

extension ClassDetails: Equatable {
    public static func == (lhs: ClassDetails, rhs: ClassDetails) -> Bool {
        lhs.classInfo == rhs.classInfo
    }
}
