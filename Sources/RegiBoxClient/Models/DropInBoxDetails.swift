import Foundation

/// Detailed information about a box for drop-in visits
public struct DropInBoxDetails: Sendable {
    /// Basic box information
    public let box: DropInBox

    /// Drop-in rules and policies
    public let rules: DropInRules

    /// Available class types at this box (e.g., "WOD", "OPENBOX", "Pilates")
    public let availableClassTypes: [String]

    /// Weekly schedule
    public let schedule: [DaySchedule]

    /// Social media and website links
    public let socialLinks: SocialLinks?

    public init(
        box: DropInBox,
        rules: DropInRules,
        availableClassTypes: [String],
        schedule: [DaySchedule],
        socialLinks: SocialLinks?
    ) {
        self.box = box
        self.rules = rules
        self.availableClassTypes = availableClassTypes
        self.schedule = schedule
        self.socialLinks = socialLinks
    }
}

/// Rules and policies for drop-in visits at a box
public struct DropInRules: Sendable {
    /// How many days in advance you can register
    public let registrationAdvanceDays: Int

    /// Additional minutes for advance registration
    public let registrationAdvanceMinutes: Int

    /// Latest time to register before class (in minutes)
    public let registrationCutoffMinutes: Int

    /// Latest time to cancel before class (in minutes)
    public let cancellationCutoffMinutes: Int

    /// Maximum number of absences allowed to keep drop-in privileges
    public let maxAllowedAbsences: Int

    /// Price for a drop-in session (e.g., "€12,00")
    public let price: String

    public init(
        registrationAdvanceDays: Int,
        registrationAdvanceMinutes: Int,
        registrationCutoffMinutes: Int,
        cancellationCutoffMinutes: Int,
        maxAllowedAbsences: Int,
        price: String
    ) {
        self.registrationAdvanceDays = registrationAdvanceDays
        self.registrationAdvanceMinutes = registrationAdvanceMinutes
        self.registrationCutoffMinutes = registrationCutoffMinutes
        self.cancellationCutoffMinutes = cancellationCutoffMinutes
        self.maxAllowedAbsences = maxAllowedAbsences
        self.price = price
    }
}

/// Schedule for a day of the week
public struct DaySchedule: Sendable {
    /// Day name in Portuguese (e.g., "Segunda-feira")
    public let dayName: String

    /// Operating hours (e.g., "06:40 - 21:00" or "Encerrado")
    public let hours: String

    /// Whether the box is closed on this day
    public var isClosed: Bool {
        hours.lowercased().contains("encerrado") || hours.lowercased().contains("fechado")
    }

    public init(dayName: String, hours: String) {
        self.dayName = dayName
        self.hours = hours
    }
}

/// Social media and website links for a box
public struct SocialLinks: Sendable {
    /// Box's website URL
    public let website: URL?

    /// Facebook page URL
    public let facebook: URL?

    /// Instagram profile URL
    public let instagram: URL?

    public init(website: URL? = nil, facebook: URL? = nil, instagram: URL? = nil) {
        self.website = website
        self.facebook = facebook
        self.instagram = instagram
    }
}
