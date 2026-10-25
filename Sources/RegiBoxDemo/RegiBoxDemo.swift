import ArgumentParser
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import RegiBoxClient

// MARK: - Exit Codes

enum CLIExitCode: Int32 {
    case success = 0
    case validationError = 1
    case authenticationFailure = 2
    case networkError = 3
}

// MARK: - JSON Output Types

struct JSONResponse<T: Encodable>: Encodable {
    let success: Bool
    let command: String
    let data: T?
    let error: JSONError?

    init(success: Bool, command: String, data: T? = nil, error: JSONError? = nil) {
        self.success = success
        self.command = command
        self.data = data
        self.error = error
    }
}

struct JSONError: Encodable {
    let code: String
    let message: String
    let hint: String?
    let nextCommand: String?

    init(code: String, message: String, hint: String?, nextCommand: String? = nil) {
        self.code = code
        self.message = message
        self.hint = hint
        self.nextCommand = nextCommand
    }
}

struct BoxJSON: Encodable {
    let id: String
    let name: String
}

struct ClassJSON: Encodable {
    let id: String
    let name: String
    let timeRange: String
    let location: String
    let enrolled: Int
    let capacity: Int
    let status: String
    let isRegistered: Bool
    let canBook: Bool
}

struct MyDropInJSON: Encodable {
    let classId: String
    let boxId: String
    let boxName: String
    let dateText: String
    let timeRange: String
    let mapsURL: String?
}

struct ClassesSummary: Encodable {
    let total: Int
    let registered: Int
    let bookable: Int
    let myDropIns: Int
}

struct ClassesData: Encodable {
    let date: String
    let classes: [ClassJSON]
    let myDropIns: [MyDropInJSON]
    let summary: ClassesSummary
}

struct ListBoxesData: Encodable {
    let total: Int
    let showing: Int
    let filter: String?
    let boxes: [BoxJSON]
}

struct LoginData: Encodable {
    let boxId: String
    let authenticated: Bool
    let cookieCount: Int
}

struct RegisterData: Encodable {
    let classId: String
    let className: String
    let timeRange: String
    let date: String
    let registered: Bool
}

struct DropInBoxJSON: Encodable {
    let id: String
    let name: String
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let distanceKm: Double?
    let drivingDurationSeconds: Double?
    let drivingDurationFormatted: String?
}

struct DropInBoxesData: Encodable {
    let total: Int
    let showing: Int
    let searchQuery: String?
    let sortedBy: String
    let userLatitude: Double?
    let userLongitude: Double?
    let boxes: [DropInBoxJSON]
}

struct DropInRulesJSON: Encodable {
    let registrationAdvanceDays: Int
    let registrationAdvanceMinutes: Int
    let registrationCutoffMinutes: Int
    let cancellationCutoffMinutes: Int
    let maxAllowedAbsences: Int
    let price: String
}

struct ScheduleDayJSON: Encodable {
    let dayName: String
    let hours: String
}

struct DropInDetailsData: Encodable {
    let boxId: String
    let boxName: String
    let rules: DropInRulesJSON
    let schedule: [ScheduleDayJSON]
    let classTypes: [String]
    let website: String?
    let facebook: String?
    let instagram: String?
}

struct DropInClassJSON: Encodable {
    let id: String
    let name: String
    let timeRange: String
    let location: String
    let status: String
    let canRegister: Bool
}

struct DropInClassesData: Encodable {
    let boxId: String
    let date: String
    let classes: [DropInClassJSON]
    let summary: DropInClassesSummary
}

struct DropInClassesSummary: Encodable {
    let total: Int
    let available: Int
    let registered: Int
}

struct ClassDetailInstructorJSON: Encodable {
    let name: String
    let photoUrl: String?

    init(name: String, photoURL: URL?) {
        self.name = name
        self.photoUrl = photoURL?.absoluteString
    }
}

struct AdditionalSectionJSON: Encodable {
    let name: String
    let content: String
}

struct ClassDetailWorkoutJSON: Encodable {
    let warmUp: String?
    let skill: String?
    let strength: String?
    let condition: String?
    let additionalSections: [AdditionalSectionJSON]?
    /// Plain text of the workout page when the sections could not be parsed.
    let rawText: String?
}

struct ClassDetailParticipantJSON: Encodable {
    let position: Int
    let name: String
}

struct ClassDetailData: Encodable {
    let classId: String
    let name: String
    let date: String
    let timeRange: String
    let location: String
    let capacity: String
    let instructors: [ClassDetailInstructorJSON]
    let workout: ClassDetailWorkoutJSON?
    let participants: [ClassDetailParticipantJSON]
}

// MARK: - Nearby Drop-In JSON Types

struct NearbyDropInClassJSON: Encodable {
    let classId: String
    let name: String
    let timeRange: String
    let startTime: String
    let location: String
    let status: String
    let canRegister: Bool
    let boxId: String
    let boxName: String
    let distanceKm: Double?
    let drivingDurationSeconds: Double?
    let drivingDurationFormatted: String?
    let date: String
    let instructors: [String]?
    let workout: ClassDetailWorkoutJSON?
}

struct NearbyBoxResultJSON: Encodable {
    let id: String
    let name: String
    let distanceKm: Double?
    let drivingDurationSeconds: Double?
    let drivingDurationFormatted: String?
    let classCount: Int
    let error: String?
}

struct NearbyDropInClassesData: Encodable {
    let date: String
    let sortedBy: String
    let userLatitude: Double
    let userLongitude: Double
    let boxResults: [NearbyBoxResultJSON]
    let classes: [NearbyDropInClassJSON]
    let summary: NearbyDropInSummary
}

struct NearbyDropInSummary: Encodable {
    let totalClasses: Int
    let availableClasses: Int
    let boxesQueried: Int
    let boxesWithClasses: Int
    let boxesWithErrors: Int
}

struct CheckInData: Encodable {
    let code: String
    let imageURL: String
    let imageSavedTo: String?
}

struct ClassHistoryEntryJSON: Encodable {
    let date: String
    let className: String
    let status: String
}

struct MonthlyAttendanceJSON: Encodable {
    let month: String
    let count: Int
    let weeks: Double
    let avgPerWeek: Double
}

struct ClassHistorySummaryJSON: Encodable {
    let registrations: Int
    let attendances: Int
    let absences: Int
    let avgPerWeek: Double
    let avgPerWeekLast6Months: Double
    let avgPerWeekLast3Months: Double
    let monthlyData: [MonthlyAttendanceJSON]
    let includesDropIns: Bool?
    let dropInRegistrations: Int?
}

struct ClassHistoryData: Encodable {
    let startDate: String
    let endDate: String
    let filter: String
    let sortOrder: String
    let totalCount: Int
    let summary: ClassHistorySummaryJSON?
    let entries: [ClassHistoryEntryJSON]?
}

struct DropInHistoryEntryJSON: Encodable {
    let date: String
    let startTime: String
    let endTime: String
    let boxId: String
    let boxAbbreviation: String
    let className: String
    let isPresent: Bool
}

struct DropInHistorySummaryJSON: Encodable {
    let registrations: Int
    let attendances: Int
    let absences: Int
    let entries: [DropInHistoryEntryJSON]
}

struct DropInHistoryData: Encodable {
    let summary: DropInHistorySummaryJSON
}

// MARK: - JSON Output Helper

func outputJSON<T: Encodable>(_ response: JSONResponse<T>) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(response),
       let string = String(data: data, encoding: .utf8) {
        print(string)
    }
}

func formatDuration(_ seconds: Double) -> String {
    let totalMinutes = Int(seconds / 60)
    if totalMinutes < 60 {
        return "\(totalMinutes) min"
    }
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
}

func exitWithError(command: String, code: String, message: String, hint: String? = nil, nextCommand: String? = nil, json: Bool) -> Never {
    if json {
        let response = JSONResponse<String>(
            success: false,
            command: command,
            data: nil,
            error: JSONError(code: code, message: message, hint: hint, nextCommand: nextCommand)
        )
        outputJSON(response)
    } else {
        fputs("Error: \(message)\n", stderr)
        if let hint = hint {
            fputs("Hint: \(hint)\n", stderr)
        }
    }
    Foundation.exit(CLIExitCode.validationError.rawValue)
}

// MARK: - Main Command

@main
struct RegiBoxDemo: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "regybox",
        abstract: "RegiBox CLI - Manage fitness class bookings at RegiBox gyms",
        discussion: """
        AUTHENTICATION:
          Set environment variables for convenience:
            export REGIBOX_EMAIL="your@email.com"
            export REGIBOX_PASSWORD="yourpassword"
            export REGIBOX_BOX_ID="299"  # Your gym's ID

          Use environment variables for credentials so passwords do not appear
          in shell history or process arguments.

        QUICK START:
          1. Find your gym:     regybox list-boxes --filter "YourGym"
          2. List classes:      regybox classes --date 2026-02-04
          3. Book a class:      regybox register --class-id 86271 --date 2026-02-04
          4. View details:      regybox class-detail 86271 --date 2026-02-04
          5. Find nearby gyms:  regybox dropin-boxes --latitude 38.72 --longitude=-9.14 --limit 10

        FOR BOTS/AUTOMATION:
          Add --json flag for machine-readable output
          Run 'regybox skill' for a complete agent instruction prompt
          Run 'regybox doctor' to diagnose issues

        EXIT CODES:
          0 - Success
          1 - Invalid input/validation error
          2 - Authentication failure
          3 - Network or API error
        """,
        version: "0.1.1",
        subcommands: [
            ListBoxes.self,
            Login.self,
            Classes.self,
            ClassDetail.self,
            Register.self,
            Unregister.self,
            DropInBoxes.self,
            DropInDetails.self,
            DropInClasses.self,
            DropInRegister.self,
            DropInUnregister.self,
            DropInNearbyClasses.self,
            CheckIn.self,
            ClassHistory.self,
            DropInHistory.self,
            Skill.self,
            Doctor.self,
            Workflows.self,
            Demo.self
        ],
        defaultSubcommand: Demo.self
    )
}

// MARK: - List Boxes Command

struct ListBoxes: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-boxes",
        abstract: "List all available boxes/gyms",
        discussion: """
        Lists all RegiBox gyms. No authentication required.

        EXAMPLES:
          regybox list-boxes
          regybox list-boxes --filter "CrossFit"
          regybox list-boxes --limit 50 --json

        OUTPUT COLUMNS:
          ID   - Box ID (use with --box-id in other commands)
          Name - Gym name

        WORKFLOW:
          Use this to find your gym's ID, then set REGIBOX_BOX_ID env var
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(name: .shortAndLong, help: "Filter boxes by name (case-insensitive)")
    var filter: String?

    @Option(name: .shortAndLong, help: "Maximum number of boxes to display")
    var limit: Int = 100

    func run() async throws {
        let client = RegiBoxClient()

        if !json { print("Fetching boxes...") }

        let boxes: [Box]
        do {
            boxes = try await client.listBoxes()
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "list-boxes",
                    error: JSONError(code: "NETWORK_ERROR", message: error.localizedDescription, hint: "Check your internet connection", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Error: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.networkError.rawValue)
        }

        var filtered = boxes
        if let filter = filter {
            filtered = boxes.filter { $0.name.localizedCaseInsensitiveContains(filter) }
        }

        let displayBoxes = Array(filtered.prefix(limit))

        if json {
            let data = ListBoxesData(
                total: boxes.count,
                showing: displayBoxes.count,
                filter: filter,
                boxes: displayBoxes.map { BoxJSON(id: $0.id, name: $0.name) }
            )
            let response = JSONResponse<ListBoxesData>(success: true, command: "list-boxes", data: data)
            outputJSON(response)
        } else {
            print("\nFound \(boxes.count) total boxes")
            if filter != nil {
                print("Showing \(displayBoxes.count) boxes matching '\(filter!)':\n")
            } else {
                print("Showing first \(displayBoxes.count) boxes:\n")
            }

            print(String(repeating: "-", count: 60))
            print("ID".padding(toLength: 8, withPad: " ", startingAt: 0) + " | Name")
            print(String(repeating: "-", count: 60))

            for box in displayBoxes {
                let paddedId = box.id.padding(toLength: 8, withPad: " ", startingAt: 0)
                print("\(paddedId) | \(box.name)")
            }

            print(String(repeating: "-", count: 60))
        }
    }
}

// MARK: - Login Command

struct Login: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "login",
        abstract: "Login to a specific box",
        discussion: """
        Tests authentication with a RegiBox gym.

        EXAMPLES:
          regybox login --box-id 299
          regybox login --box-id 299

        NOTE:
          Most commands auto-login using environment variables.
          This command is mainly for testing credentials.

        COMMON ERRORS:
          - "Login failed" - Wrong email/password or invalid box ID
          - "Network error" - Check internet connection
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(name: .shortAndLong, help: "Box ID to login to")
    var boxId: String

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]

        guard let email = resolvedEmail else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "login",
                    error: JSONError(code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Email required. Use --email or set REGIBOX_EMAIL env var")
        }
        guard let password = resolvedPassword else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "login",
                    error: JSONError(code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Password required. Use --password or set REGIBOX_PASSWORD env var")
        }

        let client = RegiBoxClient()

        if !json {
            print("Logging in to box \(boxId)...")
            print("Email: \(email)")
        }

        do {
            let session = try await client.login(boxId: boxId, email: email, password: password)

            if json {
                let data = LoginData(boxId: session.boxId, authenticated: client.isAuthenticated, cookieCount: session.cookies.count)
                let response = JSONResponse<LoginData>(success: true, command: "login", data: data)
                outputJSON(response)
            } else {
                print("\n\u{2705} Login successful!")
                print("\nSession Info:")
                print("  Box ID: \(session.boxId)")
                print("  Cookies: \(session.cookies.count) cookies stored")
                print("\nAuthenticated: \(client.isAuthenticated)")
            }
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "login",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check email, password, and box ID", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Error: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }
    }
}

// MARK: - Classes Command

struct Classes: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "classes",
        abstract: "List classes for a specific date",
        discussion: """
        Lists all fitness classes at your gym for a given date.
        Also shows any drop-in classes you're registered for at other boxes.

        EXAMPLES:
          regybox classes --date 2026-02-04
          regybox classes                      # uses today's date
          regybox classes --json               # machine-readable output

        OUTPUT COLUMNS:
          ID       - Class ID (use with register/class-detail commands)
          Time     - Start and end time (HH:MM - HH:MM)
          Name     - Class name (e.g., WOD, OPEN BOX)
          Location - Room/area
          Spots    - "X de Y" (enrolled/capacity)
          Status   - Completed, In Progress, Available, or Full
          Action   - REGISTERED, Can Book, or -

        MY DROP-INS:
          If you have registered for drop-in classes at other boxes,
          they appear in a separate section with date, time, box name,
          and a Google Maps link for directions.

        WORKFLOW:
          1. Run 'classes --date DATE' to see available classes
          2. Note the ID of the class you want
          3. Run 'register --class-id ID --date DATE' to book
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(name: .shortAndLong, help: "Box ID to login to (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    @Option(name: .shortAndLong, help: "Date in YYYY-MM-DD format (defaults to today)")
    var date: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "classes",
                    error: JSONError(code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Email required. Use --email or set REGIBOX_EMAIL env var")
        }
        guard let password = resolvedPassword else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "classes",
                    error: JSONError(code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Password required. Use --password or set REGIBOX_PASSWORD env var")
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "classes",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        // Parse date or use today
        let targetDate: Date
        if let dateString = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let parsed = formatter.date(from: dateString) else {
                if json {
                    let response = JSONResponse<String>(
                        success: false,
                        command: "classes",
                        error: JSONError(code: "INVALID_DATE", message: "Invalid date format", hint: "Use YYYY-MM-DD format (e.g., 2026-02-04)")
                    )
                    outputJSON(response)
                    throw ExitCode(CLIExitCode.validationError.rawValue)
                }
                throw ValidationError("Invalid date format. Use YYYY-MM-DD")
            }
            targetDate = parsed
        } else {
            targetDate = Date()
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: targetDate)

        if !json { print("Fetching classes for \(dateString)...\n") }

        let classes: [Class]
        do {
            classes = try await client.getClasses(for: targetDate)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "classes",
                    error: JSONError(code: "FETCH_FAILED", message: error.localizedDescription, hint: nil, nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Error fetching classes: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.networkError.rawValue)
        }

        // Fetch drop-in registrations from the main page
        let myDropIns: [MyDropIn]
        do {
            myDropIns = try await client.getMyDropIns()
        } catch {
            // Non-fatal: just show classes without drop-ins
            myDropIns = []
            if !json {
                fputs("Note: Could not fetch drop-in registrations\n", stderr)
            }
        }

        let registeredCount = classes.filter { $0.isRegistered }.count
        let bookableCount = classes.filter { $0.canBook }.count

        if json {
            let classesJSON = classes.map { classItem -> ClassJSON in
                let status: String
                switch classItem.status {
                case .completed: status = "completed"
                case .inProgress: status = "in_progress"
                case .available: status = classItem.hasAvailability ? "available" : "full"
                }
                return ClassJSON(
                    id: classItem.id,
                    name: classItem.name,
                    timeRange: classItem.timeRange,
                    location: classItem.location,
                    enrolled: classItem.enrolled,
                    capacity: classItem.capacity,
                    status: status,
                    isRegistered: classItem.isRegistered,
                    canBook: classItem.canBook
                )
            }
            let dropInsJSON = myDropIns.map { dropIn -> MyDropInJSON in
                MyDropInJSON(
                    classId: dropIn.classId,
                    boxId: dropIn.boxId,
                    boxName: dropIn.boxName,
                    dateText: dropIn.dateText,
                    timeRange: dropIn.timeRange,
                    mapsURL: dropIn.mapsURL
                )
            }
            let data = ClassesData(
                date: dateString,
                classes: classesJSON,
                myDropIns: dropInsJSON,
                summary: ClassesSummary(total: classes.count, registered: registeredCount, bookable: bookableCount, myDropIns: myDropIns.count)
            )
            let response = JSONResponse<ClassesData>(success: true, command: "classes", data: data)
            outputJSON(response)
            return
        }

        if classes.isEmpty && myDropIns.isEmpty {
            print("No classes found for \(dateString)")
            return
        }

        if !classes.isEmpty {
            print(String(repeating: "-", count: 100))
            print("ID".padding(toLength: 8, withPad: " ", startingAt: 0) +
                  "Time".padding(toLength: 14, withPad: " ", startingAt: 0) +
                  "Name".padding(toLength: 20, withPad: " ", startingAt: 0) +
                  "Location".padding(toLength: 15, withPad: " ", startingAt: 0) +
                  "Spots".padding(toLength: 10, withPad: " ", startingAt: 0) +
                  "Status".padding(toLength: 12, withPad: " ", startingAt: 0) +
                  "Action")
            print(String(repeating: "-", count: 100))

            for classItem in classes {
                let id = classItem.id.padding(toLength: 8, withPad: " ", startingAt: 0)
                let time = classItem.timeRange.padding(toLength: 14, withPad: " ", startingAt: 0)
                let name = String(classItem.name.prefix(18)).padding(toLength: 20, withPad: " ", startingAt: 0)
                let location = String(classItem.location.prefix(13)).padding(toLength: 15, withPad: " ", startingAt: 0)
                let spots = classItem.capacityText.padding(toLength: 10, withPad: " ", startingAt: 0)
                let status: String
                switch classItem.status {
                case .completed:
                    status = "Completed"
                case .inProgress:
                    status = "In Progress"
                case .available:
                    status = classItem.hasAvailability ? "Available" : "Full"
                }
                let statusPadded = status.padding(toLength: 12, withPad: " ", startingAt: 0)
                let action: String
                if classItem.isRegistered {
                    action = "REGISTERED"
                } else if classItem.canBook {
                    action = "Can Book"
                } else {
                    action = "-"
                }
                print("\(id)\(time)\(name)\(location)\(spots)\(statusPadded)\(action)")
            }

            print(String(repeating: "-", count: 100))
        }

        // Display drop-in registrations
        if !myDropIns.isEmpty {
            print("\nMY DROP-INS")
            print(String(repeating: "-", count: 70))
            print("Date".padding(toLength: 10, withPad: " ", startingAt: 0) +
                  "Time".padding(toLength: 16, withPad: " ", startingAt: 0) +
                  "Box")
            print(String(repeating: "-", count: 70))

            for dropIn in myDropIns {
                let dateCol = dropIn.dateText.padding(toLength: 10, withPad: " ", startingAt: 0)
                let timeCol = dropIn.timeRange.padding(toLength: 16, withPad: " ", startingAt: 0)
                print("\(dateCol)\(timeCol)\(dropIn.boxName)")
                if let mapsURL = dropIn.mapsURL {
                    print("          Maps: \(mapsURL)")
                }
            }

            print(String(repeating: "-", count: 70))
        }

        print("\nTotal: \(classes.count) classes")

        if registeredCount > 0 {
            print("Registered: \(registeredCount)")
        }
        if bookableCount > 0 {
            print("Available for booking: \(bookableCount)")
        }
        if !myDropIns.isEmpty {
            print("Drop-in registrations: \(myDropIns.count)")
        }

        print("\nTip: Use 'register --class-id <ID> --date \(dateString)' to book a class")
        print("     Use 'unregister --class-id <ID> --date \(dateString)' to cancel")
        print("     Use 'class-detail <CLASS_ID> --date \(dateString)' to see details")
    }
}

// MARK: - Register Command (Own Gym)

struct Register: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "register",
        abstract: "Register for a class at your own gym",
        discussion: """
        Registers you for a class at your home gym.

        PREREQUISITES:
          - Valid credentials (env vars or --email/--password)
          - Class must have status "Available" and "Can Book"

        EXAMPLES:
          regybox register --class-id 86271 --date 2026-02-04
          regybox register --class-id 86271 --date 2026-02-04 --json

        HOW TO GET CLASS ID:
          Run 'regybox classes --date DATE' and look at the ID column

        COMMON ERRORS:
          - "already registered" - You're already booked for this class
          - "cannot register" - Class is full, completed, or registration not open
          - "not found" - Wrong class ID or date
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(name: .long, help: "The class ID to register for")
    var classId: String

    @Option(name: .shortAndLong, help: "Date in YYYY-MM-DD format (required)")
    var date: String

    @Option(name: .shortAndLong, help: "Box ID to login to (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "register",
                    error: JSONError(code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Email required. Use --email or set REGIBOX_EMAIL env var")
        }
        guard let password = resolvedPassword else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "register",
                    error: JSONError(code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Password required. Use --password or set REGIBOX_PASSWORD env var")
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "register",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        // Parse date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let targetDate = formatter.date(from: date) else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "register",
                    error: JSONError(code: "INVALID_DATE", message: "Invalid date format", hint: "Use YYYY-MM-DD format (e.g., 2026-02-04)")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Invalid date format. Use YYYY-MM-DD")
        }

        if !json { print("Fetching classes for \(date)...") }
        let classes = try await client.getClasses(for: targetDate)

        guard let classItem = classes.first(where: { $0.id == classId }) else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "register",
                    error: JSONError(code: "CLASS_NOT_FOUND", message: "Class with ID \(classId) not found on \(date)", hint: "Run 'classes --date \(date)' to see available classes", nextCommand: "regybox classes --date \(date) --json")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Class with ID \(classId) not found on \(date)")
        }

        if classItem.isRegistered {
            if json {
                let data = RegisterData(classId: classId, className: classItem.name, timeRange: classItem.timeRange, date: date, registered: true)
                let response = JSONResponse<RegisterData>(success: true, command: "register", data: data, error: JSONError(code: "ALREADY_REGISTERED", message: "Already registered for this class", hint: nil))
                outputJSON(response)
            } else {
                print("\n\u{26A0}\u{FE0F}  You are already registered for \(classItem.name) at \(classItem.timeRange)")
            }
            return
        }

        guard classItem.canBook else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "register",
                    error: JSONError(code: "CANNOT_REGISTER", message: "Cannot register for \(classItem.name) at \(classItem.timeRange)", hint: "Class may be full, completed, or registration not yet open", nextCommand: "regybox classes --date \(date) --json")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            print("\n\u{274C} Cannot register for \(classItem.name) at \(classItem.timeRange)")
            print("   Class may be full, completed, or registration not yet open.")
            return
        }

        if !json { print("Registering for \(classItem.name) at \(classItem.timeRange)...") }
        let success = try await client.registerForClass(classItem)

        if json {
            let data = RegisterData(classId: classId, className: classItem.name, timeRange: classItem.timeRange, date: date, registered: success)
            if success {
                let response = JSONResponse<RegisterData>(success: true, command: "register", data: data)
                outputJSON(response)
            } else {
                let response = JSONResponse<RegisterData>(success: false, command: "register", data: data, error: JSONError(code: "REGISTRATION_FAILED", message: "Failed to register for class", hint: nil, nextCommand: "regybox classes --date \(date) --json"))
                outputJSON(response)
            }
        } else {
            if success {
                print("\n\u{2705} Successfully registered for \(classItem.name) at \(classItem.timeRange)!")
            } else {
                print("\n\u{274C} Failed to register for class \(classId)")
            }
        }
    }
}

// MARK: - Unregister Command (Own Gym)

struct Unregister: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "unregister",
        abstract: "Unregister from a class at your own gym",
        discussion: """
        Cancels your registration for a class at your home gym.

        PREREQUISITES:
          - You must be registered for the class

        EXAMPLES:
          regybox unregister --class-id 86271 --date 2026-02-04
          regybox unregister --class-id 86271 --date 2026-02-04 --json

        HOW TO CHECK REGISTRATION:
          Run 'regybox classes --date DATE'
          Classes you're registered for show "REGISTERED" in Action column

        COMMON ERRORS:
          - "not registered" - You're not booked for this class
          - "not found" - Wrong class ID or date
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(name: .long, help: "The class ID to unregister from")
    var classId: String

    @Option(name: .shortAndLong, help: "Date in YYYY-MM-DD format (required)")
    var date: String

    @Option(name: .shortAndLong, help: "Box ID to login to (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "unregister",
                    error: JSONError(code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Email required. Use --email or set REGIBOX_EMAIL env var")
        }
        guard let password = resolvedPassword else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "unregister",
                    error: JSONError(code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Password required. Use --password or set REGIBOX_PASSWORD env var")
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "unregister",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        // Parse date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let targetDate = formatter.date(from: date) else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "unregister",
                    error: JSONError(code: "INVALID_DATE", message: "Invalid date format", hint: "Use YYYY-MM-DD format (e.g., 2026-02-04)")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Invalid date format. Use YYYY-MM-DD")
        }

        if !json { print("Fetching classes for \(date)...") }
        let classes = try await client.getClasses(for: targetDate)

        guard let classItem = classes.first(where: { $0.id == classId }) else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "unregister",
                    error: JSONError(code: "CLASS_NOT_FOUND", message: "Class with ID \(classId) not found on \(date)", hint: "Run 'classes --date \(date)' to see available classes", nextCommand: "regybox classes --date \(date) --json")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Class with ID \(classId) not found on \(date)")
        }

        guard classItem.isRegistered else {
            if json {
                let data = RegisterData(classId: classId, className: classItem.name, timeRange: classItem.timeRange, date: date, registered: false)
                let response = JSONResponse<RegisterData>(success: true, command: "unregister", data: data, error: JSONError(code: "NOT_REGISTERED", message: "Not registered for this class", hint: nil))
                outputJSON(response)
            } else {
                print("\n\u{26A0}\u{FE0F}  You are not registered for \(classItem.name) at \(classItem.timeRange)")
            }
            return
        }

        if !json { print("Unregistering from \(classItem.name) at \(classItem.timeRange)...") }
        let success = try await client.unregisterFromClass(classItem)

        if json {
            let data = RegisterData(classId: classId, className: classItem.name, timeRange: classItem.timeRange, date: date, registered: !success)
            if success {
                let response = JSONResponse<RegisterData>(success: true, command: "unregister", data: data)
                outputJSON(response)
            } else {
                let response = JSONResponse<RegisterData>(success: false, command: "unregister", data: data, error: JSONError(code: "UNREGISTER_FAILED", message: "Failed to unregister from class", hint: nil, nextCommand: "regybox classes --date \(date) --json"))
                outputJSON(response)
            }
        } else {
            if success {
                print("\n\u{2705} Successfully unregistered from \(classItem.name) at \(classItem.timeRange)!")
            } else {
                print("\n\u{274C} Failed to unregister from class \(classId)")
            }
        }
    }
}

// MARK: - Class Detail Command

struct ClassDetail: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "class-detail",
        abstract: "Show detailed information about a class",
        discussion: """
        Shows full details for a class including instructors, workout, and participants.

        EXAMPLES:
          regybox class-detail 86271 --date 2026-02-04
          regybox class-detail 86271 --date 2026-02-04 --json

        OUTPUT INCLUDES:
          - Class info (name, time, location, capacity)
          - Instructors/coaches
          - Workout details (Warm-Up, Strength, Conditioning, etc.)
          - List of enrolled participants

        HOW TO GET CLASS ID:
          Run 'regybox classes --date DATE' and look at the ID column
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Argument(help: "The class ID")
    var classId: String

    @Option(name: .shortAndLong, help: "Date in YYYY-MM-DD format (required)")
    var date: String

    @Option(name: .shortAndLong, help: "Box ID to login to (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "class-detail",
                    error: JSONError(code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Email required. Use --email or set REGIBOX_EMAIL env var")
        }
        guard let password = resolvedPassword else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "class-detail",
                    error: JSONError(code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Password required. Use --password or set REGIBOX_PASSWORD env var")
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "class-detail",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        // First, get the classes for the day to find the full class info
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let targetDate = formatter.date(from: date) else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "class-detail",
                    error: JSONError(code: "INVALID_DATE", message: "Invalid date format", hint: "Use YYYY-MM-DD format (e.g., 2026-02-04)")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Invalid date format. Use YYYY-MM-DD")
        }

        if !json { print("Fetching classes for \(date)...") }
        let classes = try await client.getClasses(for: targetDate)

        guard let classItem = classes.first(where: { $0.id == classId }) else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "class-detail",
                    error: JSONError(code: "CLASS_NOT_FOUND", message: "Class with ID \(classId) not found on \(date)", hint: "Run 'classes --date \(date)' to see available classes", nextCommand: "regybox classes --date \(date) --json")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Class with ID \(classId) not found on \(date)")
        }

        if !json { print("Fetching details for class \(classItem.name)...\n") }
        let details = try await client.getClassDetails(classItem)

        if json {
            let instructorsJSON = details.instructors.map { ClassDetailInstructorJSON(name: $0.name, photoURL: $0.photoURL) }
            let workoutJSON: ClassDetailWorkoutJSON?
            if let workout = details.workout {
                let additional = workout.additionalSections.isEmpty ? nil : workout.additionalSections.map {
                    AdditionalSectionJSON(name: $0.name, content: $0.content)
                }
                workoutJSON = ClassDetailWorkoutJSON(
                    warmUp: workout.warmUp,
                    skill: workout.skill,
                    strength: workout.strength,
                    condition: workout.condition,
                    additionalSections: additional,
                    rawText: workout.rawText
                )
            } else {
                workoutJSON = nil
            }
            let participantsJSON = details.participants.map { ClassDetailParticipantJSON(position: $0.position, name: $0.name) }

            let data = ClassDetailData(
                classId: classId,
                name: details.classInfo.name,
                date: details.classInfo.date,
                timeRange: details.classInfo.timeRange,
                location: details.classInfo.location,
                capacity: details.classInfo.capacityText,
                instructors: instructorsJSON,
                workout: workoutJSON,
                participants: participantsJSON
            )
            let response = JSONResponse<ClassDetailData>(success: true, command: "class-detail", data: data)
            outputJSON(response)
            return
        }

        // Display details
        print(String(repeating: "=", count: 60))
        print(" \(details.classInfo.name)")
        print(String(repeating: "=", count: 60))
        print("\nDate:     \(details.classInfo.date)")
        print("Time:     \(details.classInfo.timeRange)")
        print("Location: \(details.classInfo.location)")
        print("Capacity: \(details.classInfo.capacityText)")

        // Instructors
        if !details.instructors.isEmpty {
            print("\n--- INSTRUCTORS ---")
            for instructor in details.instructors {
                print("  \(instructor.name)")
            }
        }

        // Workout
        if let workout = details.workout, !workout.isEmpty {
            print("\n--- WORKOUT ---")
            print(workout.formattedDescription)
        }

        // Participants
        if !details.participants.isEmpty {
            print("\n--- PARTICIPANTS (\(details.participants.count)) ---")
            for participant in details.participants {
                print("  \(participant.position). \(participant.name)")
            }
        }

        print("")
    }
}

// MARK: - Drop-In Boxes Command

struct DropInBoxes: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dropin-boxes",
        abstract: "List all boxes available for drop-in visits with GPS coordinates",
        discussion: """
        Lists gyms where you can do drop-in visits (visit another gym as a guest).

        EXAMPLES:
          regybox dropin-boxes
          regybox dropin-boxes --search "Porto"
          regybox dropin-boxes --limit 100 --json
          regybox dropin-boxes --latitude 38.7223 --longitude=-9.1393 --limit 10
          regybox dropin-boxes --latitude 38.7223 --longitude=-9.1393 --no-driving --limit 10
          regybox dropin-boxes --latitude 38.7223 --longitude=-9.1393 --search "Lisboa"

        NOTES:
          Use = (no space) for negative coordinates: --longitude=-9.1393
          A space before a negative number is interpreted as a flag by the parser.
          Driving durations are fetched by default via the free OSRM routing service.
          Use --no-driving to skip OSRM and sort by straight-line distance.

        OUTPUT COLUMNS:
          ID        - Box ID (use with --target-box-id in dropin commands)
          Name      - Gym name
          Distance  - Driving time (default) or straight-line distance (with --no-driving)
          Address   - Physical address

        WORKFLOW:
          1. Run 'dropin-boxes' to find a gym near your destination
          2. Run 'dropin-details --target-box-id ID' to see rules and pricing
          3. Run 'dropin-classes --target-box-id ID --date DATE' to see classes
          4. Run 'dropin-register --target-box-id ID --class-id CLASS' to book
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(name: .shortAndLong, help: "Box ID to login to (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    @Option(name: .shortAndLong, help: "Search query to filter boxes")
    var search: String?

    @Option(name: .shortAndLong, help: "Maximum number of boxes to display")
    var limit: Int = 50

    @Option(help: "Your current latitude (use with --longitude for distance sorting, use = for negative: --latitude=-12.3)")
    var latitude: Double?

    @Option(help: "Your current longitude (use with --latitude for distance sorting, use = for negative: --longitude=-9.2)")
    var longitude: Double?

    @Flag(name: .long, help: "Skip OSRM driving durations and sort by straight-line distance only")
    var noDriving = false

    func run() async throws {
        if (latitude != nil) != (longitude != nil) {
            throw ValidationError("Both --latitude and --longitude must be provided together")
        }

        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-boxes",
                    error: JSONError(code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Email required. Use --email or set REGIBOX_EMAIL env var")
        }
        guard let password = resolvedPassword else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-boxes",
                    error: JSONError(code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Password required. Use --password or set REGIBOX_PASSWORD env var")
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-boxes",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        if !json { print("Fetching drop-in boxes...") }
        let allBoxes = try await client.listDropInBoxes()

        // Calculate distances if user coordinates provided
        let hasCoords = latitude != nil && longitude != nil
        var distances: [String: Double] = [:]
        if let userLat = latitude, let userLng = longitude {
            for box in allBoxes {
                if let d = box.distanceTo(latitude: userLat, longitude: userLng) {
                    distances[box.id] = d
                }
            }
        }

        // Fetch driving durations (default when coordinates provided, skip with --no-driving)
        var drivingDurations: [String: Double] = [:]
        let useDriving: Bool
        if !noDriving, let userLat = latitude, let userLng = longitude {
            // Pre-filter by Haversine to avoid querying all 313 boxes
            let candidates = allBoxes.sorted { a, b in
                let da = distances[a.id] ?? Double.greatestFiniteMagnitude
                let db = distances[b.id] ?? Double.greatestFiniteMagnitude
                return da < db
            }
            let preFiltered = Array(candidates.prefix(limit * 3))

            if !json { print("Fetching driving durations for \(preFiltered.count) candidates...") }
            drivingDurations = await OSRMClient.getDrivingDurations(
                from: userLat, longitude: userLng, to: preFiltered
            )
            useDriving = !drivingDurations.isEmpty
            if !useDriving && !json {
                fputs("Warning: OSRM routing failed, falling back to straight-line distance\n", stderr)
            }
        } else {
            useDriving = false
        }

        let sortedBy = useDriving ? "driving" : (hasCoords ? "haversine" : "none")

        // Sort by driving duration or distance when coordinates provided
        var sorted = allBoxes
        if useDriving {
            sorted.sort { a, b in
                let da = drivingDurations[a.id] ?? Double.greatestFiniteMagnitude
                let db = drivingDurations[b.id] ?? Double.greatestFiniteMagnitude
                return da < db
            }
        } else if hasCoords {
            sorted.sort { a, b in
                let da = distances[a.id] ?? Double.greatestFiniteMagnitude
                let db = distances[b.id] ?? Double.greatestFiniteMagnitude
                return da < db
            }
        }

        var filtered = sorted
        if let search = search {
            filtered = sorted.filter {
                $0.name.localizedCaseInsensitiveContains(search) ||
                ($0.address?.localizedCaseInsensitiveContains(search) ?? false)
            }
        }

        let displayBoxes = Array(filtered.prefix(limit))

        if json {
            let boxesJSON = displayBoxes.map { box in
                let dur = drivingDurations[box.id]
                return DropInBoxJSON(
                    id: box.id, name: box.name, address: box.address,
                    latitude: box.latitude, longitude: box.longitude,
                    distanceKm: distances[box.id],
                    drivingDurationSeconds: dur,
                    drivingDurationFormatted: dur.map { formatDuration($0) }
                )
            }
            let data = DropInBoxesData(
                total: allBoxes.count, showing: displayBoxes.count, searchQuery: search,
                sortedBy: sortedBy,
                userLatitude: latitude, userLongitude: longitude, boxes: boxesJSON
            )
            let response = JSONResponse<DropInBoxesData>(success: true, command: "dropin-boxes", data: data)
            outputJSON(response)
            return
        }

        print("\nFound \(allBoxes.count) total drop-in boxes")
        if let search = search {
            print("Showing \(displayBoxes.count) matching '\(search)':\n")
        } else {
            print("Showing first \(displayBoxes.count) boxes:\n")
        }

        if hasCoords {
            let distHeader = useDriving ? "Drive" : "Distance"
            print(String(repeating: "-", count: 85))
            print("ID".padding(toLength: 6, withPad: " ", startingAt: 0) +
                  "Name".padding(toLength: 30, withPad: " ", startingAt: 0) +
                  distHeader.padding(toLength: 12, withPad: " ", startingAt: 0) +
                  "Address")
            print(String(repeating: "-", count: 85))

            for box in displayBoxes {
                let id = box.id.padding(toLength: 6, withPad: " ", startingAt: 0)
                let name = String(box.name.prefix(28)).padding(toLength: 30, withPad: " ", startingAt: 0)
                let dist: String
                if useDriving {
                    dist = drivingDurations[box.id].map { formatDuration($0) } ?? "N/A"
                } else {
                    dist = distances[box.id].map { String(format: "%.1f km", $0) } ?? "N/A"
                }
                let distCol = dist.padding(toLength: 12, withPad: " ", startingAt: 0)
                let address = box.address ?? "N/A"
                print("\(id)\(name)\(distCol)\(address)")
            }

            print(String(repeating: "-", count: 85))
        } else {
            print(String(repeating: "-", count: 100))
            print("ID".padding(toLength: 6, withPad: " ", startingAt: 0) +
                  "Name".padding(toLength: 30, withPad: " ", startingAt: 0) +
                  "Latitude".padding(toLength: 15, withPad: " ", startingAt: 0) +
                  "Longitude".padding(toLength: 15, withPad: " ", startingAt: 0) +
                  "Address")
            print(String(repeating: "-", count: 100))

            for box in displayBoxes {
                let id = box.id.padding(toLength: 6, withPad: " ", startingAt: 0)
                let name = String(box.name.prefix(28)).padding(toLength: 30, withPad: " ", startingAt: 0)
                let lat = (box.latitude.map { String(format: "%.6f", $0) } ?? "N/A").padding(toLength: 15, withPad: " ", startingAt: 0)
                let lng = (box.longitude.map { String(format: "%.6f", $0) } ?? "N/A").padding(toLength: 15, withPad: " ", startingAt: 0)
                let address = box.address ?? "N/A"
                print("\(id)\(name)\(lat)\(lng)\(address)")
            }

            print(String(repeating: "-", count: 100))
        }

        print("\nTip: Use 'dropin-details --target-box-id <ID>' to see box rules and schedule")
    }
}

// MARK: - Drop-In Details Command

struct DropInDetails: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dropin-details",
        abstract: "Show detailed information about a box for drop-in (rules, schedule, pricing)",
        discussion: """
        Shows rules, schedule, and pricing for a drop-in gym before you visit.

        EXAMPLES:
          regybox dropin-details --target-box-id 1
          regybox dropin-details --target-box-id 1 --json

        OUTPUT INCLUDES:
          - Registration rules (advance booking, cutoffs)
          - Drop-in pricing
          - Weekly schedule
          - Available class types
          - Social media links

        WORKFLOW:
          Check rules and pricing before booking a drop-in class
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(name: .long, help: "The drop-in box ID to get details for")
    var targetBoxId: String

    @Option(name: .shortAndLong, help: "Your home box ID to login (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-details",
                    error: JSONError(code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Email required. Use --email or set REGIBOX_EMAIL env var")
        }
        guard let password = resolvedPassword else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-details",
                    error: JSONError(code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Password required. Use --password or set REGIBOX_PASSWORD env var")
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-details",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        if !json { print("Fetching drop-in details for box \(targetBoxId)...") }
        let details = try await client.getDropInBoxDetails(boxId: targetBoxId)

        if json {
            let rulesJSON = DropInRulesJSON(
                registrationAdvanceDays: details.rules.registrationAdvanceDays,
                registrationAdvanceMinutes: details.rules.registrationAdvanceMinutes,
                registrationCutoffMinutes: details.rules.registrationCutoffMinutes,
                cancellationCutoffMinutes: details.rules.cancellationCutoffMinutes,
                maxAllowedAbsences: details.rules.maxAllowedAbsences,
                price: details.rules.price
            )
            let scheduleJSON = details.schedule.map { ScheduleDayJSON(dayName: $0.dayName, hours: $0.hours) }
            let data = DropInDetailsData(
                boxId: targetBoxId,
                boxName: details.box.name,
                rules: rulesJSON,
                schedule: scheduleJSON,
                classTypes: details.availableClassTypes,
                website: details.socialLinks?.website?.absoluteString,
                facebook: details.socialLinks?.facebook?.absoluteString,
                instagram: details.socialLinks?.instagram?.absoluteString
            )
            let response = JSONResponse<DropInDetailsData>(success: true, command: "dropin-details", data: data)
            outputJSON(response)
            return
        }

        print("\n" + String(repeating: "=", count: 60))
        print(" \(details.box.name)")
        print(String(repeating: "=", count: 60))

        // Rules
        print("\n--- RULES ---")
        print("  Registration advance: \(details.rules.registrationAdvanceDays) days, \(details.rules.registrationAdvanceMinutes) minutes")
        print("  Registration cutoff:  \(details.rules.registrationCutoffMinutes) minutes before class")
        print("  Cancellation cutoff:  \(details.rules.cancellationCutoffMinutes) minutes before class")
        print("  Max absences allowed: \(details.rules.maxAllowedAbsences)")
        if !details.rules.price.isEmpty {
            print("  Price:                \(details.rules.price)")
        }

        // Schedule
        if !details.schedule.isEmpty {
            print("\n--- SCHEDULE ---")
            for day in details.schedule {
                let dayName = day.dayName.padding(toLength: 15, withPad: " ", startingAt: 0)
                print("  \(dayName) \(day.hours)")
            }
        }

        // Class types
        if !details.availableClassTypes.isEmpty {
            print("\n--- AVAILABLE CLASS TYPES ---")
            print("  \(details.availableClassTypes.joined(separator: ", "))")
        }

        // Social links
        if let social = details.socialLinks {
            print("\n--- SOCIAL LINKS ---")
            if let website = social.website {
                print("  Website:   \(website)")
            }
            if let facebook = social.facebook {
                print("  Facebook:  \(facebook)")
            }
            if let instagram = social.instagram {
                print("  Instagram: \(instagram)")
            }
        }

        print("\n\nTip: Use 'dropin-classes --target-box-id \(targetBoxId)' to see available classes")
    }
}

// MARK: - Drop-In Classes Command

struct DropInClasses: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dropin-classes",
        abstract: "List drop-in classes for a specific box and date",
        discussion: """
        Lists classes available for drop-in at another gym.

        EXAMPLES:
          regybox dropin-classes --target-box-id 1 --date 2026-02-04
          regybox dropin-classes --target-box-id 1 --json

        OUTPUT COLUMNS:
          ID       - Class ID (use with dropin-register)
          Time     - Start and end time
          Name     - Class name
          Location - Room/area
          Status   - Available, Registered, Completed, or Unavailable

        WORKFLOW:
          1. Find the class you want from the output
          2. Run 'dropin-register --target-box-id ID --class-id CLASS' to book
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(name: .long, help: "The drop-in box ID to get classes for")
    var targetBoxId: String

    @Option(name: .shortAndLong, help: "Your home box ID to login (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    @Option(name: .shortAndLong, help: "Date in YYYY-MM-DD format (defaults to today)")
    var date: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-classes",
                    error: JSONError(code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Email required. Use --email or set REGIBOX_EMAIL env var")
        }
        guard let password = resolvedPassword else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-classes",
                    error: JSONError(code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Password required. Use --password or set REGIBOX_PASSWORD env var")
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-classes",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        // Parse date or use today
        let targetDate: Date
        if let dateString = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let parsed = formatter.date(from: dateString) else {
                if json {
                    let response = JSONResponse<String>(
                        success: false,
                        command: "dropin-classes",
                        error: JSONError(code: "INVALID_DATE", message: "Invalid date format", hint: "Use YYYY-MM-DD format (e.g., 2026-02-04)")
                    )
                    outputJSON(response)
                    throw ExitCode(CLIExitCode.validationError.rawValue)
                }
                throw ValidationError("Invalid date format. Use YYYY-MM-DD")
            }
            targetDate = parsed
        } else {
            targetDate = Date()
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: targetDate)

        if !json { print("Fetching drop-in classes at box \(targetBoxId) for \(dateString)...\n") }

        let classes = try await client.getDropInClasses(boxId: targetBoxId, for: targetDate)

        let availableCount = classes.filter { $0.canRegister }.count
        let registeredCount = classes.filter { $0.status == .registered }.count

        if json {
            let classesJSON = classes.map { classItem -> DropInClassJSON in
                let status: String
                switch classItem.status {
                case .completed: status = "completed"
                case .inProgress: status = "in_progress"
                case .available: status = "available"
                case .registered: status = "registered"
                case .unavailable: status = "unavailable"
                }
                return DropInClassJSON(
                    id: classItem.id,
                    name: classItem.name,
                    timeRange: classItem.timeRange,
                    location: classItem.location,
                    status: status,
                    canRegister: classItem.canRegister
                )
            }
            let data = DropInClassesData(
                boxId: targetBoxId,
                date: dateString,
                classes: classesJSON,
                summary: DropInClassesSummary(total: classes.count, available: availableCount, registered: registeredCount)
            )
            let response = JSONResponse<DropInClassesData>(success: true, command: "dropin-classes", data: data)
            outputJSON(response)
            return
        }

        if classes.isEmpty {
            print("No drop-in classes found for \(dateString)")
            return
        }

        print(String(repeating: "-", count: 90))
        print("ID".padding(toLength: 8, withPad: " ", startingAt: 0) +
              "Time".padding(toLength: 14, withPad: " ", startingAt: 0) +
              "Name".padding(toLength: 20, withPad: " ", startingAt: 0) +
              "Location".padding(toLength: 15, withPad: " ", startingAt: 0) +
              "Status")
        print(String(repeating: "-", count: 90))

        for classItem in classes {
            let id = classItem.id.padding(toLength: 8, withPad: " ", startingAt: 0)
            let time = classItem.timeRange.padding(toLength: 14, withPad: " ", startingAt: 0)
            let name = String(classItem.name.prefix(18)).padding(toLength: 20, withPad: " ", startingAt: 0)
            let location = String(classItem.location.prefix(13)).padding(toLength: 15, withPad: " ", startingAt: 0)
            let status: String
            switch classItem.status {
            case .completed:
                status = "Completed"
            case .inProgress:
                status = "In Progress"
            case .available:
                status = "Available"
            case .registered:
                status = "Registered"
            case .unavailable:
                status = "Unavailable"
            }
            print("\(id)\(time)\(name)\(location)\(status)")
        }

        print(String(repeating: "-", count: 90))
        print("\nTotal: \(classes.count) classes")

        if availableCount > 0 {
            print("Available for registration: \(availableCount)")
        }
        if registeredCount > 0 {
            print("Already registered: \(registeredCount)")
        }

        print("\nTip: Use 'dropin-register --target-box-id \(targetBoxId) --class-id <ID>' to register")
    }
}

// MARK: - Drop-In Register Command

struct DropInRegisterData: Encodable {
    let targetBoxId: String
    let classId: String
    let registered: Bool
}

struct DropInRegister: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dropin-register",
        abstract: "Register for a drop-in class",
        discussion: """
        Registers you for a class at another gym as a drop-in visitor.

        PREREQUISITES:
          - Check the gym's rules first: 'dropin-details --target-box-id ID'
          - Class must show "Available" status

        EXAMPLES:
          regybox dropin-register --target-box-id 1 --class-id 57105
          regybox dropin-register --target-box-id 1 --class-id 57105 --json

        HOW TO GET CLASS ID:
          Run 'dropin-classes --target-box-id ID --date DATE'
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(name: .long, help: "The drop-in box ID")
    var targetBoxId: String

    @Option(name: .long, help: "The class ID to register for")
    var classId: String

    @Option(name: .shortAndLong, help: "Your home box ID to login (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-register",
                    error: JSONError(code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Email required. Use --email or set REGIBOX_EMAIL env var")
        }
        guard let password = resolvedPassword else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-register",
                    error: JSONError(code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Password required. Use --password or set REGIBOX_PASSWORD env var")
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-register",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        if !json { print("Registering for class \(classId) at box \(targetBoxId)...") }
        let success = try await client.registerForDropInClass(classId: classId, boxId: targetBoxId)

        if json {
            let data = DropInRegisterData(targetBoxId: targetBoxId, classId: classId, registered: success)
            if success {
                let response = JSONResponse<DropInRegisterData>(success: true, command: "dropin-register", data: data)
                outputJSON(response)
            } else {
                let response = JSONResponse<DropInRegisterData>(success: false, command: "dropin-register", data: data, error: JSONError(code: "REGISTRATION_FAILED", message: "Failed to register for drop-in class", hint: nil, nextCommand: "regybox dropin-classes --target-box-id \(targetBoxId) --json"))
                outputJSON(response)
            }
        } else {
            if success {
                print("\n\u{2705} Successfully registered for class \(classId)!")
            } else {
                print("\n\u{274C} Failed to register for class \(classId)")
            }
        }
    }
}

// MARK: - Drop-In Unregister Command

struct DropInUnregister: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dropin-unregister",
        abstract: "Unregister from a drop-in class",
        discussion: """
        Cancels your registration for a drop-in class at another gym.

        EXAMPLES:
          regybox dropin-unregister --target-box-id 1 --class-id 57105
          regybox dropin-unregister --target-box-id 1 --class-id 57105 --json

        NOTE:
          Check the gym's cancellation policy first:
          'dropin-details --target-box-id ID'
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(name: .long, help: "The drop-in box ID")
    var targetBoxId: String

    @Option(name: .long, help: "The class ID to unregister from")
    var classId: String

    @Option(name: .shortAndLong, help: "Your home box ID to login (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-unregister",
                    error: JSONError(code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Email required. Use --email or set REGIBOX_EMAIL env var")
        }
        guard let password = resolvedPassword else {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-unregister",
                    error: JSONError(code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var")
                )
                outputJSON(response)
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
            throw ValidationError("Password required. Use --password or set REGIBOX_PASSWORD env var")
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-unregister",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        if !json { print("Unregistering from class \(classId) at box \(targetBoxId)...") }
        let success = try await client.unregisterFromDropInClass(classId: classId, boxId: targetBoxId)

        if json {
            let data = DropInRegisterData(targetBoxId: targetBoxId, classId: classId, registered: !success)
            if success {
                let response = JSONResponse<DropInRegisterData>(success: true, command: "dropin-unregister", data: data)
                outputJSON(response)
            } else {
                let response = JSONResponse<DropInRegisterData>(success: false, command: "dropin-unregister", data: data, error: JSONError(code: "UNREGISTER_FAILED", message: "Failed to unregister from drop-in class", hint: nil, nextCommand: "regybox dropin-classes --target-box-id \(targetBoxId) --json"))
                outputJSON(response)
            }
        } else {
            if success {
                print("\n\u{2705} Successfully unregistered from class \(classId)!")
            } else {
                print("\n\u{274C} Failed to unregister from class \(classId)")
            }
        }
    }
}

// MARK: - Drop-In Nearby Classes Command

struct DropInNearbyClasses: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dropin-nearby-classes",
        abstract: "Find drop-in classes across multiple nearby boxes",
        discussion: """
        Fetches classes from the closest drop-in boxes and displays them sorted by time.
        Requires GPS coordinates to calculate distances.

        EXAMPLES:
          regybox dropin-nearby-classes --latitude 38.7223 --longitude=-9.1393
          regybox dropin-nearby-classes --latitude 38.7223 --longitude=-9.1393 --no-driving
          regybox dropin-nearby-classes --latitude 38.7223 --longitude=-9.1393 --date 2026-02-20
          regybox dropin-nearby-classes --latitude 38.7223 --longitude=-9.1393 --limit 3 --details
          regybox dropin-nearby-classes --latitude 38.7223 --longitude=-9.1393 --filter-name "WOD"
          regybox dropin-nearby-classes --latitude 38.7223 --longitude=-9.1393 --group-by-box
          regybox dropin-nearby-classes --latitude 38.7223 --longitude=-9.1393 --json

        NOTES:
          Use = (no space) for negative coordinates: --longitude=-9.1393
          The --details flag makes extra API calls and is slower.
          Driving durations are fetched by default via the free OSRM routing service.
          Use --no-driving to skip OSRM and sort by straight-line distance.

        WORKFLOW:
          1. Find classes nearby with this command
          2. Run 'dropin-register --target-box-id <ID> --class-id <ID>' to book
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(help: "Your current latitude (required, use = for negative: --latitude=-12.3)")
    var latitude: Double

    @Option(help: "Your current longitude (required, use = for negative: --longitude=-9.2)")
    var longitude: Double

    @Option(name: .shortAndLong, help: "Date in YYYY-MM-DD format (defaults to today)")
    var date: String?

    @Option(name: .shortAndLong, help: "Number of closest boxes to query (default: 5)")
    var limit: Int = 5

    @Option(name: .long, help: "Filter classes by name (case-insensitive, e.g. \"WOD\")")
    var filterName: String?

    @Flag(name: .long, help: "Group output by box instead of sorting by time")
    var groupByBox = false

    @Flag(name: .long, help: "Include workout/instructor details (slower, extra API calls)")
    var details = false

    @Flag(name: .long, help: "Skip OSRM driving durations and sort by straight-line distance only")
    var noDriving = false

    @Option(name: .shortAndLong, help: "Your home box ID to login (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            exitWithError(command: "dropin-nearby-classes", code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var", json: json)
        }
        guard let password = resolvedPassword else {
            exitWithError(command: "dropin-nearby-classes", code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var", json: json)
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-nearby-classes",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        // Parse date or use today
        let targetDate: Date
        if let dateString = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let parsed = formatter.date(from: dateString) else {
                exitWithError(command: "dropin-nearby-classes", code: "INVALID_DATE", message: "Invalid date format", hint: "Use YYYY-MM-DD format (e.g., 2026-02-04)", json: json)
            }
            targetDate = parsed
        } else {
            targetDate = Date()
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: targetDate)

        // Fetch all drop-in boxes
        if !json { print("Fetching drop-in boxes...") }
        let allBoxes: [DropInBox]
        do {
            allBoxes = try await client.listDropInBoxes()
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-nearby-classes",
                    error: JSONError(code: "FETCH_FAILED", message: error.localizedDescription, hint: nil, nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Error fetching drop-in boxes: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.networkError.rawValue)
        }

        // Calculate distances and sort by proximity
        var distances: [String: Double] = [:]
        for box in allBoxes {
            if let d = box.distanceTo(latitude: latitude, longitude: longitude) {
                distances[box.id] = d
            }
        }

        // Pre-sort by Haversine to pick candidates
        let haversineSorted = allBoxes.sorted { a, b in
            let da = distances[a.id] ?? Double.greatestFiniteMagnitude
            let db = distances[b.id] ?? Double.greatestFiniteMagnitude
            return da < db
        }

        // Fetch driving durations (default unless --no-driving)
        var drivingDurations: [String: Double] = [:]
        let useDriving: Bool
        if !noDriving {
            let candidates = Array(haversineSorted.prefix(limit * 3))
            if !json { print("Fetching driving durations for \(candidates.count) candidates...") }
            drivingDurations = await OSRMClient.getDrivingDurations(
                from: latitude, longitude: longitude, to: candidates
            )
            useDriving = !drivingDurations.isEmpty
            if !useDriving && !json {
                fputs("Warning: OSRM routing failed, falling back to straight-line distance\n", stderr)
            }
        } else {
            useDriving = false
        }

        let sortedBy = useDriving ? "driving" : "haversine"

        // Sort by driving duration or Haversine distance
        let sorted: [DropInBox]
        if useDriving {
            sorted = allBoxes.sorted { a, b in
                let da = drivingDurations[a.id] ?? Double.greatestFiniteMagnitude
                let db = drivingDurations[b.id] ?? Double.greatestFiniteMagnitude
                return da < db
            }
        } else {
            sorted = haversineSorted
        }

        let nearbyBoxes = Array(sorted.prefix(limit))

        if !json {
            print("Fetching classes from \(nearbyBoxes.count) nearby boxes for \(dateString)...")
        }

        // Fetch classes from all nearby boxes in parallel
        let results: [RegiBoxClient.NearbyDropInResult]
        do {
            results = try await client.getDropInClassesForMultipleBoxes(
                boxes: nearbyBoxes,
                distances: distances,
                drivingDurations: useDriving ? drivingDurations : nil,
                for: targetDate
            )
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-nearby-classes",
                    error: JSONError(code: "FETCH_FAILED", message: error.localizedDescription, hint: nil, nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Error fetching classes: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.networkError.rawValue)
        }

        // Flatten all classes with box context
        struct ClassWithContext {
            let dropInClass: DropInClass
            let box: DropInBox
            let distanceKm: Double?
            let drivingDurationSeconds: Double?
            var instructors: [String]?
            var workout: Workout?
        }

        var allClasses: [ClassWithContext] = []
        for result in results {
            for cls in result.classes {
                allClasses.append(ClassWithContext(
                    dropInClass: cls,
                    box: result.box,
                    distanceKm: result.distanceKm,
                    drivingDurationSeconds: result.drivingDurationSeconds
                ))
            }
        }

        // Apply name filter
        if let filterName = filterName {
            allClasses = allClasses.filter {
                $0.dropInClass.name.localizedCaseInsensitiveContains(filterName)
            }
        }

        // Fetch details if requested
        if details && !allClasses.isEmpty {
            let nonCompletedIndices = allClasses.indices.filter {
                allClasses[$0].dropInClass.status != .completed
            }

            if !json && !nonCompletedIndices.isEmpty {
                print("Fetching details for \(nonCompletedIndices.count) classes...")
            }

            // Fetch details in parallel using TaskGroup
            let detailResults = await withTaskGroup(
                of: (Int, ClassDetails?).self,
                returning: [(Int, ClassDetails?)].self
            ) { group in
                for idx in nonCompletedIndices {
                    let cls = allClasses[idx].dropInClass
                    group.addTask {
                        let detail = try? await client.getDropInClassDetails(
                            classId: cls.id,
                            date: cls.date,
                            boxId: cls.boxId
                        )
                        return (idx, detail)
                    }
                }

                var collected: [(Int, ClassDetails?)] = []
                for await result in group {
                    collected.append(result)
                }
                return collected
            }

            for (idx, detail) in detailResults {
                if let detail = detail {
                    allClasses[idx].instructors = detail.instructors.map { $0.name }
                    allClasses[idx].workout = detail.workout
                }
            }
        }

        // Sort by start time (default) unless grouping by box
        if !groupByBox {
            allClasses.sort { a, b in
                if a.dropInClass.startTime == b.dropInClass.startTime {
                    if useDriving {
                        let da = a.drivingDurationSeconds ?? Double.greatestFiniteMagnitude
                        let db = b.drivingDurationSeconds ?? Double.greatestFiniteMagnitude
                        return da < db
                    }
                    let da = a.distanceKm ?? Double.greatestFiniteMagnitude
                    let db = b.distanceKm ?? Double.greatestFiniteMagnitude
                    return da < db
                }
                return a.dropInClass.startTime < b.dropInClass.startTime
            }
        } else {
            allClasses.sort { a, b in
                if useDriving {
                    let da = a.drivingDurationSeconds ?? Double.greatestFiniteMagnitude
                    let db = b.drivingDurationSeconds ?? Double.greatestFiniteMagnitude
                    if da != db { return da < db }
                } else {
                    let da = a.distanceKm ?? Double.greatestFiniteMagnitude
                    let db = b.distanceKm ?? Double.greatestFiniteMagnitude
                    if da != db { return da < db }
                }
                return a.dropInClass.startTime < b.dropInClass.startTime
            }
        }

        // Count stats
        let boxesWithClasses = results.filter { !$0.classes.isEmpty }.count
        let boxesWithErrors = results.filter { $0.error != nil }.count
        let availableCount = allClasses.filter { $0.dropInClass.canRegister }.count

        // JSON output
        if json {
            let boxResults = results.sorted(by: {
                if useDriving {
                    return ($0.drivingDurationSeconds ?? .greatestFiniteMagnitude) < ($1.drivingDurationSeconds ?? .greatestFiniteMagnitude)
                }
                return ($0.distanceKm ?? .greatestFiniteMagnitude) < ($1.distanceKm ?? .greatestFiniteMagnitude)
            }).map { result in
                NearbyBoxResultJSON(
                    id: result.box.id,
                    name: result.box.name,
                    distanceKm: result.distanceKm,
                    drivingDurationSeconds: result.drivingDurationSeconds,
                    drivingDurationFormatted: result.drivingDurationSeconds.map { formatDuration($0) },
                    classCount: result.classes.count,
                    error: result.error
                )
            }

            let classesJSON = allClasses.map { ctx -> NearbyDropInClassJSON in
                let status: String
                switch ctx.dropInClass.status {
                case .completed: status = "completed"
                case .inProgress: status = "in_progress"
                case .available: status = "available"
                case .registered: status = "registered"
                case .unavailable: status = "unavailable"
                }

                var workoutJSON: ClassDetailWorkoutJSON? = nil
                if let workout = ctx.workout, !workout.isEmpty {
                    let additional = workout.additionalSections.isEmpty ? nil : workout.additionalSections.map {
                        AdditionalSectionJSON(name: $0.name, content: $0.content)
                    }
                    workoutJSON = ClassDetailWorkoutJSON(
                        warmUp: workout.warmUp,
                        skill: workout.skill,
                        strength: workout.strength,
                        condition: workout.condition,
                        additionalSections: additional,
                        rawText: workout.rawText
                    )
                }

                return NearbyDropInClassJSON(
                    classId: ctx.dropInClass.id,
                    name: ctx.dropInClass.name,
                    timeRange: ctx.dropInClass.timeRange,
                    startTime: ctx.dropInClass.startTime,
                    location: ctx.dropInClass.location,
                    status: status,
                    canRegister: ctx.dropInClass.canRegister,
                    boxId: ctx.box.id,
                    boxName: ctx.box.name,
                    distanceKm: ctx.distanceKm,
                    drivingDurationSeconds: ctx.drivingDurationSeconds,
                    drivingDurationFormatted: ctx.drivingDurationSeconds.map { formatDuration($0) },
                    date: ctx.dropInClass.date,
                    instructors: ctx.instructors,
                    workout: workoutJSON
                )
            }

            let data = NearbyDropInClassesData(
                date: dateString,
                sortedBy: sortedBy,
                userLatitude: latitude,
                userLongitude: longitude,
                boxResults: boxResults,
                classes: classesJSON,
                summary: NearbyDropInSummary(
                    totalClasses: allClasses.count,
                    availableClasses: availableCount,
                    boxesQueried: nearbyBoxes.count,
                    boxesWithClasses: boxesWithClasses,
                    boxesWithErrors: boxesWithErrors
                )
            )
            let response = JSONResponse<NearbyDropInClassesData>(success: true, command: "dropin-nearby-classes", data: data)
            outputJSON(response)
            return
        }

        // Human-readable output
        print("")

        // Always show which boxes were queried
        let sortedResults = results.sorted {
            if useDriving {
                return ($0.drivingDurationSeconds ?? .greatestFiniteMagnitude) < ($1.drivingDurationSeconds ?? .greatestFiniteMagnitude)
            }
            return ($0.distanceKm ?? .greatestFiniteMagnitude) < ($1.distanceKm ?? .greatestFiniteMagnitude)
        }
        print("Queried boxes:")
        for result in sortedResults {
            let dist: String
            if useDriving {
                dist = result.drivingDurationSeconds.map { formatDuration($0).padding(toLength: 7, withPad: " ", startingAt: 0) } ?? "  N/A  "
            } else {
                dist = result.distanceKm.map { String(format: "%5.1f km", $0) } ?? "  N/A  "
            }
            let boxLabel = "\(result.box.name) (\(result.box.id))"
            let paddedBox = String(boxLabel.prefix(35)).padding(toLength: 37, withPad: " ", startingAt: 0)
            let status: String
            if let error = result.error {
                status = "ERROR: \(error)"
            } else {
                let count = result.classes.count
                status = count == 1 ? "1 class" : "\(count) classes"
            }
            print("  \(dist)  \(paddedBox) - \(status)")
        }

        if boxesWithErrors > 0 {
            print("")
            let errorBoxes = results.filter { $0.error != nil }
            for eb in errorBoxes {
                fputs("Warning: \(eb.box.name) (\(eb.box.id)): \(eb.error!)\n", stderr)
            }
        }

        if allClasses.isEmpty {
            print("\nNo classes found across \(nearbyBoxes.count) nearby boxes for \(dateString)")
            if let filterName = filterName {
                print("(filtered by name: \"\(filterName)\")")
            }
            if let firstBox = sortedResults.first {
                print("Tip: Verify with 'regybox dropin-classes --target-box-id \(firstBox.box.id) --date \(dateString)'")
            }
            return
        }

        print("\nFound \(allClasses.count) classes across \(boxesWithClasses) boxes\n")

        if groupByBox {
            // Group by box output
            var currentBoxId = ""
            for ctx in allClasses {
                if ctx.box.id != currentBoxId {
                    currentBoxId = ctx.box.id
                    let dist: String
                    if useDriving {
                        dist = ctx.drivingDurationSeconds.map { formatDuration($0) } ?? "N/A"
                    } else {
                        dist = ctx.distanceKm.map { String(format: "%.1f km", $0) } ?? "N/A"
                    }
                    print("=== \(ctx.box.name) (\(ctx.box.id)) - \(dist) ===")
                    print("ID".padding(toLength: 8, withPad: " ", startingAt: 0) +
                          "Time".padding(toLength: 16, withPad: " ", startingAt: 0) +
                          "Class".padding(toLength: 18, withPad: " ", startingAt: 0) +
                          "Status")
                }

                let id = ctx.dropInClass.id.padding(toLength: 8, withPad: " ", startingAt: 0)
                let time = ctx.dropInClass.timeRange.padding(toLength: 16, withPad: " ", startingAt: 0)
                let name = String(ctx.dropInClass.name.prefix(16)).padding(toLength: 18, withPad: " ", startingAt: 0)
                let status = dropInStatusText(ctx.dropInClass.status)
                print("\(id)\(time)\(name)\(status)")

                if details {
                    printClassDetails(ctx.instructors, ctx.workout)
                }
            }
        } else {
            // Time-sorted output (default)
            let distHeader = useDriving ? "Drive" : "Dist"
            let lineWidth = 105
            print(String(repeating: "-", count: lineWidth))
            print("Time".padding(toLength: 14, withPad: " ", startingAt: 0) +
                  "Class".padding(toLength: 16, withPad: " ", startingAt: 0) +
                  "Box".padding(toLength: 30, withPad: " ", startingAt: 0) +
                  distHeader.padding(toLength: 10, withPad: " ", startingAt: 0) +
                  "ID".padding(toLength: 8, withPad: " ", startingAt: 0) +
                  "Status")
            print(String(repeating: "-", count: lineWidth))

            for ctx in allClasses {
                let time = ctx.dropInClass.timeRange.padding(toLength: 14, withPad: " ", startingAt: 0)
                let name = String(ctx.dropInClass.name.prefix(14)).padding(toLength: 16, withPad: " ", startingAt: 0)
                let boxLabel = "\(ctx.box.name) (\(ctx.box.id))"
                let boxCol = String(boxLabel.prefix(28)).padding(toLength: 30, withPad: " ", startingAt: 0)
                let dist: String
                if useDriving {
                    dist = (ctx.drivingDurationSeconds.map { formatDuration($0) } ?? "N/A").padding(toLength: 10, withPad: " ", startingAt: 0)
                } else {
                    dist = (ctx.distanceKm.map { String(format: "%.1f km", $0) } ?? "N/A").padding(toLength: 10, withPad: " ", startingAt: 0)
                }
                let classId = ctx.dropInClass.id.padding(toLength: 8, withPad: " ", startingAt: 0)
                let status = dropInStatusText(ctx.dropInClass.status)
                print("\(time)\(name)\(boxCol)\(dist)\(classId)\(status)")

                if details {
                    printClassDetails(ctx.instructors, ctx.workout)
                }
            }

            print(String(repeating: "-", count: lineWidth))
        }

        print("\nTotal: \(allClasses.count) classes | Available: \(availableCount) | Boxes: \(boxesWithClasses)")
        print("\nBook with: regybox dropin-register --target-box-id <ID> --class-id <ID>")
    }

    private func dropInStatusText(_ status: DropInClassStatus) -> String {
        switch status {
        case .completed: return "Completed"
        case .inProgress: return "In Progress"
        case .available: return "Available"
        case .registered: return "Registered"
        case .unavailable: return "Unavailable"
        }
    }

    private func printClassDetails(_ instructors: [String]?, _ workout: Workout?) {
        if let instructors = instructors, !instructors.isEmpty {
            print("              Coach: \(instructors.joined(separator: ", "))")
        }
        if let workout = workout, !workout.isEmpty {
            if let s = workout.strength, !s.isEmpty {
                let oneLine = s.replacingOccurrences(of: "\n", with: " | ")
                print("              Strength: \(String(oneLine.prefix(70)))")
            }
            if let c = workout.condition, !c.isEmpty {
                let oneLine = c.replacingOccurrences(of: "\n", with: " | ")
                print("              Conditioning: \(String(oneLine.prefix(70)))")
            }
            if let w = workout.warmUp, !w.isEmpty {
                let oneLine = w.replacingOccurrences(of: "\n", with: " | ")
                print("              Warm-Up: \(String(oneLine.prefix(70)))")
            }
            if let s = workout.skill, !s.isEmpty {
                let oneLine = s.replacingOccurrences(of: "\n", with: " | ")
                print("              Skill: \(String(oneLine.prefix(70)))")
            }
            for section in workout.additionalSections {
                let oneLine = section.content.replacingOccurrences(of: "\n", with: " | ")
                print("              \(section.name): \(String(oneLine.prefix(70)))")
            }
        }
    }
}

// MARK: - Check-In Command

struct CheckIn: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check-in",
        abstract: "Get the check-in QR code for gym entry",
        discussion: """
        Retrieves the QR code used for gym check-in at the entrance reader.

        EXAMPLES:
          regybox check-in
          regybox check-in --output qr.png
          regybox check-in --json

        OUTPUT:
          By default prints the QR code URL and code string.
          With --output, saves the QR code PNG image to the specified path.
          With --json, outputs structured JSON with code and image URL.

        WORKFLOW:
          1. Run 'check-in --output qr.png' to save the QR code image
          2. Present the image at the gym's QR code reader for entry
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(name: .shortAndLong, help: "Save QR code PNG image to this file path")
    var output: String?

    @Option(name: .shortAndLong, help: "Box ID to login to (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            exitWithError(command: "check-in", code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var", json: json)
        }
        guard let password = resolvedPassword else {
            exitWithError(command: "check-in", code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var", json: json)
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "check-in",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        if !json { print("Fetching check-in QR code...") }

        let qrCode: CheckInQRCode
        do {
            qrCode = try await client.getCheckInQRCode()
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "check-in",
                    error: JSONError(code: "FETCH_FAILED", message: error.localizedDescription, hint: nil, nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Error fetching QR code: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.networkError.rawValue)
        }

        // Save image if --output specified
        var savedPath: String?
        if let outputPath = output {
            do {
                let url = URL(fileURLWithPath: outputPath)
                try qrCode.imageData.write(to: url)
                savedPath = outputPath
            } catch {
                if json {
                    let response = JSONResponse<String>(
                        success: false,
                        command: "check-in",
                        error: JSONError(code: "WRITE_FAILED", message: "Failed to save image: \(error.localizedDescription)", hint: "Check the output path is writable", nextCommand: "regybox check-in --json")
                    )
                    outputJSON(response)
                } else {
                    fputs("Error saving QR code image: \(error.localizedDescription)\n", stderr)
                }
                throw ExitCode(CLIExitCode.validationError.rawValue)
            }
        }

        if json {
            let data = CheckInData(
                code: qrCode.code,
                imageURL: qrCode.imageURL,
                imageSavedTo: savedPath
            )
            let response = JSONResponse<CheckInData>(success: true, command: "check-in", data: data)
            outputJSON(response)
        } else {
            print("\nCheck-In QR Code")
            print(String(repeating: "-", count: 60))
            print("Code:      \(qrCode.code)")
            print("Image URL: \(qrCode.imageURL)")
            print("Image size: \(qrCode.imageData.count) bytes")
            if let path = savedPath {
                print("Saved to:  \(path)")
            }
            print(String(repeating: "-", count: 60))
        }
    }
}

// MARK: - Class History Command

struct ClassHistory: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "class-history",
        abstract: "View your training attendance history",
        discussion: """
        Shows your class attendance history - which classes you attended,
        missed, or are registered for. Fetches data from the RegiBox
        "HISTÓRICO DE AULAS" feature.

        EXAMPLES:
          regybox class-history                                    # current month
          regybox class-history --month 2026-01                    # specific month
          regybox class-history --from 2026-01-01 --to 2026-02-28 # date range
          regybox class-history --type present                     # only attended
          regybox class-history --summary                          # stats + chart only
          regybox class-history --json                             # machine-readable

        FILTERS:
          --type all       - All entries (default)
          --type present   - Only classes you attended
          --type absent    - Only classes you missed
          --type no-record - Registered but no attendance record

        SORT OPTIONS:
          --sort recent     - Most recent first (default)
          --sort oldest     - Oldest first
          --sort class-type - Group by class name

        WORKFLOW:
          Use --summary to see weekly averages (overall, 6-month, 3-month)
          and a monthly breakdown with avg sessions/week per month.
          Use --type absent to identify missed classes.
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Flag(name: .long, help: "Show only summary stats and monthly breakdown (skip detailed list)")
    var summary = false

    @Flag(name: .long, help: "Include drop-in sessions in weekly averages")
    var includeDropins = false

    @Option(name: .long, help: "Start date in YYYY-MM-DD format (defaults to 1st of current month)")
    var from: String?

    @Option(name: .long, help: "End date in YYYY-MM-DD format (defaults to last day of current month)")
    var to: String?

    @Option(name: .long, help: "Month in YYYY-MM format (shorthand for --from/--to)")
    var month: String?

    @Option(name: .long, help: "Filter: all, present, absent, no-record (default: all)")
    var type: String = "all"

    @Option(name: .long, help: "Sort: recent, oldest, class-type (default: recent)")
    var sort: String = "recent"

    @Option(name: .shortAndLong, help: "Box ID to login to (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            exitWithError(command: "class-history", code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var", json: json)
        }
        guard let password = resolvedPassword else {
            exitWithError(command: "class-history", code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var", json: json)
        }

        // Validate type
        let apiType: String
        switch type.lowercased() {
        case "all": apiType = "all"
        case "present": apiType = "pres"
        case "absent": apiType = "falt"
        case "no-record": apiType = "insc"
        default:
            exitWithError(command: "class-history", code: "INVALID_TYPE", message: "Invalid type '\(type)'", hint: "Use: all, present, absent, or no-record", json: json)
        }

        // Validate sort
        let apiOrder: String
        switch sort.lowercased() {
        case "recent": apiOrder = "data_ini DESC"
        case "oldest": apiOrder = "data_ini ASC"
        case "class-type": apiOrder = "aula ASC, data_ini DESC"
        default:
            exitWithError(command: "class-history", code: "INVALID_SORT", message: "Invalid sort '\(sort)'", hint: "Use: recent, oldest, or class-type", json: json)
        }

        // Resolve date range
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startDate: String
        let endDate: String

        if let monthStr = month {
            // Parse YYYY-MM and compute first/last day
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "yyyy-MM"
            guard let monthDate = monthFormatter.date(from: monthStr) else {
                exitWithError(command: "class-history", code: "INVALID_MONTH", message: "Invalid month format '\(monthStr)'", hint: "Use YYYY-MM format (e.g., 2026-01)", json: json)
            }
            let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay)!
            startDate = dateFormatter.string(from: firstDay)
            endDate = dateFormatter.string(from: lastDay)
        } else if let fromStr = from, let toStr = to {
            // Validate dates
            guard dateFormatter.date(from: fromStr) != nil else {
                exitWithError(command: "class-history", code: "INVALID_DATE", message: "Invalid start date '\(fromStr)'", hint: "Use YYYY-MM-DD format", json: json)
            }
            guard dateFormatter.date(from: toStr) != nil else {
                exitWithError(command: "class-history", code: "INVALID_DATE", message: "Invalid end date '\(toStr)'", hint: "Use YYYY-MM-DD format", json: json)
            }
            startDate = fromStr
            endDate = toStr
        } else {
            // Default to current month
            let now = Date()
            let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay)!
            startDate = dateFormatter.string(from: firstDay)
            endDate = dateFormatter.string(from: lastDay)
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "class-history",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        // Fetch summary
        var summaryData: ClassHistorySummaryJSON?
        if !json { print("Fetching class history summary...") }

        do {
            let historySummary = try await client.getClassHistorySummary()
            // Map Portuguese month abbreviations to month numbers
            let ptMonthMap: [String: Int] = [
                "Jan": 1, "Fev": 2, "Mar": 3, "Abr": 4, "Mai": 5, "Jun": 6,
                "Jul": 7, "Ago": 8, "Set": 9, "Out": 10, "Nov": 11, "Dez": 12
            ]

            let calendar = Calendar.current
            let now = Date()
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)
            let currentDay = calendar.component(.day, from: now)

            // Assign year to each month by walking backwards from current month
            // The chart shows up to 12 months ending with the current month
            let monthlyWithWeeks: [MonthlyAttendanceJSON] = historySummary.monthlyData.enumerated().map { (index, m) in
                let monthNum = ptMonthMap[m.month] ?? 1
                let isLastEntry = index == historySummary.monthlyData.count - 1

                // Determine year: if month > current month, it's from previous year
                // For the last entry (current month), always use current year
                let year: Int
                if isLastEntry {
                    year = currentYear
                } else if monthNum > currentMonth {
                    year = currentYear - 1
                } else {
                    year = currentYear
                }

                var weeks: Double
                if isLastEntry && monthNum == currentMonth {
                    // Current month: use elapsed days
                    weeks = Double(currentDay) / 7.0
                } else {
                    // Full month: use total days in month
                    var components = DateComponents()
                    components.year = year
                    components.month = monthNum
                    components.day = 1
                    if let date = calendar.date(from: components),
                       let range = calendar.range(of: .day, in: .month, for: date) {
                        weeks = Double(range.count) / 7.0
                    } else {
                        weeks = 4.3
                    }
                }

                let avg = weeks > 0 ? Double(m.count) / weeks : 0
                return MonthlyAttendanceJSON(
                    month: m.month,
                    count: m.count,
                    weeks: (weeks * 10).rounded() / 10,
                    avgPerWeek: (avg * 10).rounded() / 10
                )
            }

            // Compute rolling averages: total, last 6 months, last 3 months
            func avgForSlice(_ data: [MonthlyAttendanceJSON]) -> Double {
                guard !data.isEmpty else { return 0 }
                let totalCount = data.reduce(0) { $0 + $1.count }
                let totalWeeks = data.reduce(0.0) { $0 + $1.weeks }
                return totalWeeks > 0 ? (Double(totalCount) / totalWeeks * 10).rounded() / 10 : 0
            }

            // Build year mapping for each chart month (needed for drop-in merge)
            let monthYears: [String] = historySummary.monthlyData.enumerated().map { (index, m) in
                let monthNum = ptMonthMap[m.month] ?? 1
                let isLastEntry = index == historySummary.monthlyData.count - 1
                let year: Int
                if isLastEntry {
                    year = currentYear
                } else if monthNum > currentMonth {
                    year = currentYear - 1
                } else {
                    year = currentYear
                }
                // Key: "YYYY-MM" e.g. "2026-02"
                return String(format: "%04d-%02d", year, monthNum)
            }

            // If --include-dropins, fetch drop-in history and merge into monthly counts
            var dropInRegs: Int? = nil
            var mergedMonthly = monthlyWithWeeks
            if includeDropins {
                if !json { print("Fetching drop-in history...") }
                do {
                    let dropInHistory = try await client.getDropInHistory()
                    dropInRegs = dropInHistory.registrations

                    // Group drop-in entries by YYYY-MM (not just month abbreviation!)
                    var dropInByYearMonth: [String: Int] = [:]
                    for entry in dropInHistory.entries {
                        // entry.date is "YYYY-MM-DD", extract "YYYY-MM"
                        let yearMonth = String(entry.date.prefix(7))
                        dropInByYearMonth[yearMonth, default: 0] += 1
                    }

                    // Add drop-in counts only to the matching year-month bar
                    mergedMonthly = monthlyWithWeeks.enumerated().map { (index, m) in
                        let key = monthYears[index]
                        let extra = dropInByYearMonth[key] ?? 0
                        let newCount = m.count + extra
                        let newAvg = m.weeks > 0 ? (Double(newCount) / m.weeks * 10).rounded() / 10 : 0
                        return MonthlyAttendanceJSON(
                            month: m.month,
                            count: newCount,
                            weeks: m.weeks,
                            avgPerWeek: newAvg
                        )
                    }
                } catch {
                    if !json {
                        fputs("Warning: Could not fetch drop-in history: \(error.localizedDescription)\n", stderr)
                    }
                }
            }

            let finalMonthly = includeDropins ? mergedMonthly : monthlyWithWeeks
            let finalAllAvg = avgForSlice(finalMonthly)
            let finalLast6 = Array(finalMonthly.suffix(6))
            let finalLast3 = Array(finalMonthly.suffix(3))

            summaryData = ClassHistorySummaryJSON(
                registrations: historySummary.registrations,
                attendances: historySummary.attendances,
                absences: historySummary.absences,
                avgPerWeek: finalAllAvg,
                avgPerWeekLast6Months: avgForSlice(finalLast6),
                avgPerWeekLast3Months: avgForSlice(finalLast3),
                monthlyData: finalMonthly,
                includesDropIns: includeDropins ? true : nil,
                dropInRegistrations: dropInRegs
            )
        } catch {
            if !json {
                fputs("Warning: Could not fetch summary stats: \(error.localizedDescription)\n", stderr)
            }
        }

        // Fetch detailed entries (unless --summary only)
        var entries: [ClassHistoryEntry] = []
        if !summary {
            if !json { print("Fetching class history for \(startDate) to \(endDate)...") }

            do {
                entries = try await client.getClassHistory(
                    startDate: startDate,
                    endDate: endDate,
                    type: apiType,
                    order: apiOrder
                )
            } catch {
                if json {
                    let response = JSONResponse<String>(
                        success: false,
                        command: "class-history",
                        error: JSONError(code: "FETCH_FAILED", message: error.localizedDescription, hint: nil, nextCommand: "regybox doctor --json")
                    )
                    outputJSON(response)
                } else {
                    fputs("Error fetching class history: \(error.localizedDescription)\n", stderr)
                }
                throw ExitCode(CLIExitCode.networkError.rawValue)
            }
        }

        if json {
            let data = ClassHistoryData(
                startDate: startDate,
                endDate: endDate,
                filter: type,
                sortOrder: sort,
                totalCount: entries.count,
                summary: summaryData,
                entries: summary ? nil : entries.map {
                    ClassHistoryEntryJSON(date: $0.date, className: $0.className, status: $0.status.rawValue)
                }
            )
            let response = JSONResponse<ClassHistoryData>(success: true, command: "class-history", data: data)
            outputJSON(response)
        } else {
            // Display summary
            if let s = summaryData {
                let title = includeDropins ? "Training Summary (incl. drop-ins)" : "Training Summary"
                print("\n\(title)")
                print(String(repeating: "-", count: 60))
                print("  Registrations: \(s.registrations)")
                print("  Attendances:   \(s.attendances)")
                print("  Absences:      \(s.absences)")
                if let dropInRegs = s.dropInRegistrations {
                    print("  Drop-in regs:  \(dropInRegs)")
                }
                print("")
                print("  Avg/week (all):      \(String(format: "%.1f", s.avgPerWeek))")
                print("  Avg/week (6 months): \(String(format: "%.1f", s.avgPerWeekLast6Months))")
                print("  Avg/week (3 months): \(String(format: "%.1f", s.avgPerWeekLast3Months))")

                if !s.monthlyData.isEmpty {
                    print("\nMonthly Breakdown:")
                    for m in s.monthlyData {
                        let bar = String(repeating: "\u{2588}", count: m.count)
                        let countStr = String(m.count).padding(toLength: 4, withPad: " ", startingAt: 0)
                        print("  \(m.month.padding(toLength: 4, withPad: " ", startingAt: 0)) \(bar) \(countStr)(\(String(format: "%.1f", m.avgPerWeek))/wk)")
                    }
                }
                print(String(repeating: "-", count: 60))
            }

            // Display entries
            if !summary {
                print("\nClass History (\(startDate) to \(endDate))")
                if type != "all" { print("Filter: \(type)") }
                print(String(repeating: "-", count: 70))
                print("Date".padding(toLength: 16, withPad: " ", startingAt: 0)
                    + "Class".padding(toLength: 30, withPad: " ", startingAt: 0)
                    + "Status")
                print(String(repeating: "-", count: 70))

                if entries.isEmpty {
                    print("  No entries found for this period.")
                } else {
                    for entry in entries {
                        let statusIcon: String
                        switch entry.status {
                        case .present: statusIcon = "\u{2705} Presente"
                        case .absent: statusIcon = "\u{274C} Falta"
                        case .noRecord: statusIcon = "\u{2B1C} Sem registo"
                        }
                        print(entry.date.padding(toLength: 16, withPad: " ", startingAt: 0)
                            + entry.className.padding(toLength: 30, withPad: " ", startingAt: 0)
                            + statusIcon)
                    }
                }

                print(String(repeating: "-", count: 70))
                print("Total: \(entries.count) entries")
            }
        }
    }
}

// MARK: - Drop-In History Command

struct DropInHistory: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dropin-history",
        abstract: "View your drop-in attendance history",
        discussion: """
        Shows your drop-in class history - visits to other boxes,
        with attendance confirmation status.

        EXAMPLES:
          regybox dropin-history           # view all drop-in history
          regybox dropin-history --json    # machine-readable output
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    @Option(name: .shortAndLong, help: "Box ID to login to (or set REGIBOX_BOX_ID env var)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        guard let email = resolvedEmail else {
            exitWithError(command: "dropin-history", code: "MISSING_EMAIL", message: "Email required", hint: "Use --email or set REGIBOX_EMAIL env var", json: json)
        }
        guard let password = resolvedPassword else {
            exitWithError(command: "dropin-history", code: "MISSING_PASSWORD", message: "Password required", hint: "Use --password or set REGIBOX_PASSWORD env var", json: json)
        }

        let client = RegiBoxClient()

        if !json { print("Logging in to box \(resolvedBoxId)...") }

        do {
            _ = try await client.login(boxId: resolvedBoxId, email: email, password: password)
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-history",
                    error: JSONError(code: "AUTH_FAILED", message: error.localizedDescription, hint: "Check credentials", nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Login failed: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.authenticationFailure.rawValue)
        }

        if !json { print("Fetching drop-in history...") }

        do {
            let history = try await client.getDropInHistory()

            if json {
                let data = DropInHistoryData(
                    summary: DropInHistorySummaryJSON(
                        registrations: history.registrations,
                        attendances: history.attendances,
                        absences: history.absences,
                        entries: history.entries.map {
                            DropInHistoryEntryJSON(
                                date: $0.date,
                                startTime: $0.startTime,
                                endTime: $0.endTime,
                                boxId: $0.boxId,
                                boxAbbreviation: $0.boxAbbreviation,
                                className: $0.className,
                                isPresent: $0.isPresent
                            )
                        }
                    )
                )
                let response = JSONResponse<DropInHistoryData>(success: true, command: "dropin-history", data: data)
                outputJSON(response)
            } else {
                print("\nDrop-in History")
                print(String(repeating: "-", count: 60))
                print("  Registrations: \(history.registrations)")
                print("  Attendances:   \(history.attendances)")
                print("  Absences:      \(history.absences)")
                print(String(repeating: "-", count: 60))

                if history.entries.isEmpty {
                    print("  No drop-in entries found.")
                } else {
                    print("Date".padding(toLength: 13, withPad: " ", startingAt: 0)
                        + "Time".padding(toLength: 16, withPad: " ", startingAt: 0)
                        + "Box".padding(toLength: 5, withPad: " ", startingAt: 0)
                        + "Class".padding(toLength: 16, withPad: " ", startingAt: 0)
                        + "Status")
                    print(String(repeating: "-", count: 60))

                    for entry in history.entries {
                        let timeRange = "\(entry.startTime) -> \(entry.endTime)"
                        // Most boxes don't track drop-in attendance — no status means assumed present
                        let status = "\u{2705} Present"
                        print(entry.date.padding(toLength: 13, withPad: " ", startingAt: 0)
                            + timeRange.padding(toLength: 16, withPad: " ", startingAt: 0)
                            + entry.boxAbbreviation.padding(toLength: 5, withPad: " ", startingAt: 0)
                            + entry.className.padding(toLength: 16, withPad: " ", startingAt: 0)
                            + status)
                    }
                }

                print(String(repeating: "-", count: 60))
                print("Total: \(history.entries.count) entries")
            }
        } catch {
            if json {
                let response = JSONResponse<String>(
                    success: false,
                    command: "dropin-history",
                    error: JSONError(code: "FETCH_FAILED", message: error.localizedDescription, hint: nil, nextCommand: "regybox doctor --json")
                )
                outputJSON(response)
            } else {
                fputs("Error fetching drop-in history: \(error.localizedDescription)\n", stderr)
            }
            throw ExitCode(CLIExitCode.networkError.rawValue)
        }
    }
}

// MARK: - Skill Command

struct Skill: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "skill",
        abstract: "Output a complete agent instruction prompt for this CLI",
        discussion: """
        Prints a ready-to-use markdown prompt that teaches an AI agent
        how to use every command, including workflows and error handling.

        EXAMPLES:
          regybox skill             # full output with workflows
          regybox skill --compact   # commands only, no workflows
        """
    )

    @Flag(name: .long, help: "Shorter output: commands only, no workflows")
    var compact = false

    func run() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let tomorrowStr = dateFormatter.string(from: tomorrow)

        var output = """
        # Regybox CLI — Agent Instructions

        You have access to the `regybox` CLI for managing CrossFit gym bookings via RegiBox (www.regibox.pt).

        ## Authentication

        Set these environment variables before running commands:
        - `REGIBOX_EMAIL` (required) — Login email for RegiBox account
        - `REGIBOX_PASSWORD` (required) — Login password
        - `REGIBOX_BOX_ID` (optional, default: 299) — Your home gym's box ID

        ## Commands

        ### Diagnostics

        #### Health check (no auth required for partial checks)
        ```
        regybox doctor [--json]
        ```
        Verifies env vars, network, login credentials, and OSRM routing. Run this first to diagnose issues.

        ### Gym Discovery (no auth required)

        #### List all gyms
        ```
        regybox list-boxes [--filter TEXT] [--limit N] [--json]
        ```
        Returns all RegiBox gyms. Use `--filter` for case-insensitive name search.

        ### Classes at Your Gym (auth required)

        #### List classes for a date
        ```
        regybox classes [--date YYYY-MM-DD] [--json]
        ```
        Defaults to today if `--date` omitted. Shows class ID, time, name, capacity, status, and registration state.

        #### View class details (instructor, workout, participants)
        ```
        regybox class-detail CLASS_ID --date YYYY-MM-DD [--json]
        ```

        #### Book a class
        ```
        regybox register --class-id ID --date YYYY-MM-DD [--json]
        ```

        #### Cancel a booking
        ```
        regybox unregister --class-id ID --date YYYY-MM-DD [--json]
        ```

        ### Drop-In at Other Gyms (auth required)

        #### List drop-in boxes
        ```
        regybox dropin-boxes [--search TEXT] [--latitude LAT --longitude=LNG] [--limit N] [--no-driving] [--json]
        ```
        Use `--latitude`/`--longitude` for distance sorting (driving time by default). Use `=` for negative values: `--longitude=-9.14`.

        #### View drop-in gym rules and schedule
        ```
        regybox dropin-details --target-box-id ID [--json]
        ```

        #### List drop-in classes
        ```
        regybox dropin-classes --target-box-id ID [--date YYYY-MM-DD] [--json]
        ```

        #### Book a drop-in class
        ```
        regybox dropin-register --target-box-id ID --class-id ID [--json]
        ```

        #### Cancel a drop-in booking
        ```
        regybox dropin-unregister --target-box-id ID --class-id ID [--json]
        ```

        #### Find classes across multiple nearby gyms
        ```
        regybox dropin-nearby-classes --latitude LAT --longitude=LNG [--date YYYY-MM-DD] [--limit N] [--filter-name TEXT] [--details] [--group-by-box] [--no-driving] [--json]
        ```
        Searches the closest N boxes and returns all classes sorted by time.

        ### Check-In

        #### Get gym entry QR code
        ```
        regybox check-in [--output FILE.png] [--json]
        ```
        Retrieves the QR code for gym entry. Use `--output` to save as PNG image.

        ### Training History (auth required)

        #### View attendance history
        ```
        regybox class-history [--month YYYY-MM] [--from YYYY-MM-DD --to YYYY-MM-DD] [--type TYPE] [--sort ORDER] [--summary] [--include-dropins] [--json]
        ```
        Shows class attendance history with filters. Types: `all` (default), `present`, `absent`, `no-record`. Sort: `recent` (default), `oldest`, `class-type`.

        Use `--summary` for stats only: registrations, attendances, absences, weekly averages (overall, last 6 months, last 3 months), and a monthly breakdown chart with avg sessions/week per month.

        Use `--include-dropins` to merge drop-in sessions into the monthly counts and weekly averages. Drop-in registrations are matched by exact year-month.

        #### View drop-in history
        ```
        regybox dropin-history [--json]
        ```
        Shows all drop-in visits to other gyms with date, time, box, class name, and attendance status. Most boxes don't track drop-in attendance, so entries default to "Present".
        """

        if !compact {
            output += """


            ## Workflows

            ### Book a class at your gym
            1. `regybox classes --date \(today) --json`
            2. Pick a class where `status` is `"available"` and `canBook` is `true`
            3. `regybox register --class-id <ID> --date \(today) --json`
            4. Verify: `regybox classes --date \(today) --json` → confirm `isRegistered` is `true`

            ### Cancel a class at your gym
            1. `regybox classes --date \(today) --json`
            2. Find the class where `isRegistered` is `true`
            3. `regybox unregister --class-id <ID> --date \(today) --json`
            4. Verify: `regybox classes --date \(today) --json` → confirm `isRegistered` is `false`

            ### Book a drop-in at another gym
            1. `regybox dropin-boxes --latitude <LAT> --longitude=<LNG> --limit 10 --json`
            2. Pick a box, note its `id`
            3. `regybox dropin-details --target-box-id <ID> --json` — check rules and pricing
            4. `regybox dropin-classes --target-box-id <ID> --date \(tomorrowStr) --json`
            5. `regybox dropin-register --target-box-id <ID> --class-id <CLASS_ID> --json`
            6. Verify: `regybox dropin-classes --target-box-id <ID> --date \(tomorrowStr) --json`

            ### Find the nearest available class
            1. `regybox dropin-nearby-classes --latitude <LAT> --longitude=<LNG> --limit 5 --json`
            2. Pick a class from the results (already sorted by proximity)
            3. `regybox dropin-register --target-box-id <BOX_ID> --class-id <CLASS_ID> --json`

            ### View weekly schedule
            ```bash
            for date in \(today) \(tomorrowStr) ...; do
              regybox classes --date "$date" --json
            done
            ```
            Filter JSON by `isRegistered: true` to see only your bookings.

            ### Get gym entry QR code
            1. `regybox check-in --json`
            2. Use the `imageURL` to display the QR code, or
            3. `regybox check-in --output qr.png` to save the image

            ### Check training consistency
            1. `regybox class-history --summary --json` — overall stats + weekly averages
            2. Compare `avgPerWeek`, `avgPerWeekLast6Months`, `avgPerWeekLast3Months` to spot trends
            3. `regybox class-history --type absent --json` — identify missed classes
            4. `regybox class-history --summary --include-dropins --json` — include drop-in sessions in averages

            ### View drop-in history
            1. `regybox dropin-history --json` — all drop-in visits with attendance status
            """
        }

        output += """


        ## Rules for Agents
        - Always use `--json` flag when parsing output programmatically
        - Always confirm with the user before booking or cancelling
        - Use `regybox doctor --json` to diagnose auth or network issues
        - Exit codes: 0 = success, 1 = validation error, 2 = auth failure, 3 = network error
        - On error, check the `nextCommand` field in the JSON response for a recovery command
        - Use `=` (no space) for negative longitude values: `--longitude=-9.14`
        - Dates use YYYY-MM-DD format; omitting `--date` defaults to today (\(today))
        """

        print(output)
    }
}

// MARK: - Doctor Command

struct DoctorCheckJSON: Encodable {
    let name: String
    let status: String
    let value: String?
    let latencyMs: Int?

    init(name: String, status: String, value: String? = nil, latencyMs: Int? = nil) {
        self.name = name
        self.status = status
        self.value = value
        self.latencyMs = latencyMs
    }
}

struct DoctorData: Encodable {
    let checks: [DoctorCheckJSON]
    let allGood: Bool
}

struct Doctor: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Check environment, credentials, and connectivity",
        discussion: """
        Runs health checks to verify everything is configured correctly.
        Useful for diagnosing authentication or network issues.

        CHECKS:
          1. REGIBOX_EMAIL env var
          2. REGIBOX_PASSWORD env var
          3. REGIBOX_BOX_ID env var (warning if missing)
          4. Network: can reach www.regibox.pt
          5. Login: credentials are valid
          6. OSRM: routing service reachable (optional)

        EXAMPLES:
          regybox doctor
          regybox doctor --json
        """
    )

    @Flag(name: .long, help: "Output as JSON for automation")
    var json = false

    func run() async throws {
        var checks: [DoctorCheckJSON] = []
        var hasFailure = false

        // Check 1: REGIBOX_EMAIL
        let emailValue = ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        if let email = emailValue, !email.isEmpty {
            let masked = String(email.prefix(2)) + "***@" + (email.split(separator: "@").last.map(String.init) ?? "***")
            checks.append(DoctorCheckJSON(name: "env_email", status: "ok", value: masked))
            if !json { print("  [ok] REGIBOX_EMAIL = \(masked)") }
        } else {
            checks.append(DoctorCheckJSON(name: "env_email", status: "fail"))
            hasFailure = true
            if !json { print("  [FAIL] REGIBOX_EMAIL not set") }
        }

        // Check 2: REGIBOX_PASSWORD
        let passwordValue = ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        if let pw = passwordValue, !pw.isEmpty {
            checks.append(DoctorCheckJSON(name: "env_password", status: "ok"))
            if !json { print("  [ok] REGIBOX_PASSWORD is set") }
        } else {
            checks.append(DoctorCheckJSON(name: "env_password", status: "fail"))
            hasFailure = true
            if !json { print("  [FAIL] REGIBOX_PASSWORD not set") }
        }

        // Check 3: REGIBOX_BOX_ID
        let boxIdValue = ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"]
        if let boxId = boxIdValue, !boxId.isEmpty {
            checks.append(DoctorCheckJSON(name: "env_box_id", status: "ok", value: boxId))
            if !json { print("  [ok] REGIBOX_BOX_ID = \(boxId)") }
        } else {
            checks.append(DoctorCheckJSON(name: "env_box_id", status: "warn", value: "defaults to 299"))
            if !json { print("  [warn] REGIBOX_BOX_ID not set (defaults to 299)") }
        }

        // Check 4: Network connectivity
        do {
            let start = Date()
            let url = URL(string: "https://www.regibox.pt")!
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 10
            let (_, response) = try await URLSession.shared.asyncData(for: request)
            let latencyMs = Int(Date().timeIntervalSince(start) * 1000)
            if let http = response as? HTTPURLResponse, (200...399).contains(http.statusCode) {
                checks.append(DoctorCheckJSON(name: "network", status: "ok", latencyMs: latencyMs))
                if !json { print("  [ok] Network: regibox.pt reachable (\(latencyMs)ms)") }
            } else {
                checks.append(DoctorCheckJSON(name: "network", status: "fail", latencyMs: latencyMs))
                hasFailure = true
                if !json { print("  [FAIL] Network: unexpected response from regibox.pt") }
            }
        } catch {
            checks.append(DoctorCheckJSON(name: "network", status: "fail"))
            hasFailure = true
            if !json { print("  [FAIL] Network: \(error.localizedDescription)") }
        }

        // Check 5: Login
        if let email = emailValue, !email.isEmpty,
           let password = passwordValue, !password.isEmpty {
            let boxId = boxIdValue ?? "299"
            let client = RegiBoxClient()
            do {
                let start = Date()
                _ = try await client.login(boxId: boxId, email: email, password: password)
                let latencyMs = Int(Date().timeIntervalSince(start) * 1000)
                checks.append(DoctorCheckJSON(name: "login", status: "ok", latencyMs: latencyMs))
                if !json { print("  [ok] Login: authenticated successfully (\(latencyMs)ms)") }
            } catch {
                checks.append(DoctorCheckJSON(name: "login", status: "fail"))
                hasFailure = true
                if !json { print("  [FAIL] Login: \(error.localizedDescription)") }
            }
        } else {
            checks.append(DoctorCheckJSON(name: "login", status: "skip", value: "missing credentials"))
            if !json { print("  [skip] Login: missing email or password") }
        }

        // Check 6: OSRM routing service
        do {
            let start = Date()
            let url = URL(string: "https://router.project-osrm.org/table/v1/driving/-9.1393,38.7223;-9.1393,38.7223?sources=0")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            let (data, _) = try await URLSession.shared.asyncData(for: request)
            let latencyMs = Int(Date().timeIntervalSince(start) * 1000)
            if let body = String(data: data, encoding: .utf8), body.contains("\"Ok\"") {
                checks.append(DoctorCheckJSON(name: "osrm", status: "ok", latencyMs: latencyMs))
                if !json { print("  [ok] OSRM: routing service reachable (\(latencyMs)ms)") }
            } else {
                checks.append(DoctorCheckJSON(name: "osrm", status: "warn"))
                if !json { print("  [warn] OSRM: unexpected response (driving durations may not work)") }
            }
        } catch {
            checks.append(DoctorCheckJSON(name: "osrm", status: "warn"))
            if !json { print("  [warn] OSRM: \(error.localizedDescription) (driving durations may not work)") }
        }

        let allGood = !hasFailure

        if json {
            let doctorData = DoctorData(checks: checks, allGood: allGood)
            let response = JSONResponse<DoctorData>(success: allGood, command: "doctor", data: doctorData)
            outputJSON(response)
        } else {
            print("")
            if allGood {
                print("All checks passed!")
            } else {
                print("Some checks failed. Fix the issues above and re-run.")
            }
        }

        if !allGood {
            throw ExitCode(CLIExitCode.validationError.rawValue)
        }
    }
}

// MARK: - Workflows Command

struct Workflows: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "workflows",
        abstract: "Show step-by-step guides for common tasks",
        discussion: """
        Displays detailed workflow guides for AI agents and automation.

        AVAILABLE WORKFLOWS:
          list-boxes            - Find your gym's box ID
          book-class            - Book a class at your gym
          cancel-class          - Cancel a class booking
          dropin-visit          - Book a drop-in at another gym
          find-nearby-dropin    - Find & book drop-in classes near you
          view-schedule         - View weekly schedule
          training-history      - View training stats and drop-in history

        EXAMPLES:
          regybox workflows              # list all workflows
          regybox workflows book-class   # show specific workflow
        """
    )

    @Argument(help: "Workflow name (optional)")
    var workflow: String?

    func run() throws {
        if let workflow = workflow {
            showWorkflow(workflow)
        } else {
            listWorkflows()
        }
    }

    func listWorkflows() {
        print("""
        AVAILABLE WORKFLOWS
        ===================

        list-boxes           Find your gym's box ID for authentication
        book-class           Book a class at your home gym
        cancel-class         Cancel a class booking
        dropin-visit         Book a drop-in class at another gym
        find-nearby-dropin   Find & book drop-in classes near your location
        view-schedule        View your weekly class schedule
        training-history     View training stats, weekly averages, and drop-in history

        Run 'regybox workflows <name>' for step-by-step guide.
        """)
    }

    func showWorkflow(_ name: String) {
        switch name.lowercased() {
        case "list-boxes":
            print("""
            WORKFLOW: Find Your Gym's Box ID
            =================================

            STEP 1: List all gyms
              $ regybox list-boxes

            STEP 2: Filter by name (optional)
              $ regybox list-boxes --filter "YourGymName"

            STEP 3: Note the ID from the output
              Look for the ID column (e.g., "299")

            STEP 4: Set as environment variable
              $ export REGIBOX_BOX_ID="299"

            This ID is used for all authenticated commands.
            """)

        case "book-class":
            print("""
            WORKFLOW: Book a Class at Your Gym
            ===================================

            STEP 1: List available classes
              $ regybox classes --date 2026-02-04

            STEP 2: Find the class ID from the output
              Look for the ID column (e.g., "86271")
              Check that Status is "Available" and Action is "Can Book"

            STEP 3: Register for the class
              $ regybox register --class-id 86271 --date 2026-02-04

            STEP 4: Verify registration
              $ regybox classes --date 2026-02-04
              The class should now show "REGISTERED" in the Action column

            FOR AUTOMATION (JSON output):
              $ regybox classes --date 2026-02-04 --json
              $ regybox register --class-id 86271 --date 2026-02-04 --json

            TO CANCEL:
              $ regybox unregister --class-id 86271 --date 2026-02-04
            """)

        case "cancel-class":
            print("""
            WORKFLOW: Cancel a Class Booking
            =================================

            STEP 1: List your classes to find the registration
              $ regybox classes --date 2026-02-04
              Look for classes showing "REGISTERED" in Action column

            STEP 2: Unregister from the class
              $ regybox unregister --class-id 86271 --date 2026-02-04

            STEP 3: Verify cancellation
              $ regybox classes --date 2026-02-04
              The class should no longer show "REGISTERED"

            FOR AUTOMATION (JSON output):
              $ regybox unregister --class-id 86271 --date 2026-02-04 --json
            """)

        case "dropin-visit", "dropin":
            print("""
            WORKFLOW: Book a Drop-In Class at Another Gym
            ==============================================

            STEP 1: Search for gyms near your destination
              $ regybox dropin-boxes --search "Porto"

              ALTERNATIVE — Sort by driving distance from your location:
              $ regybox dropin-boxes --latitude 41.1579 --longitude=-8.6291 --limit 10
              (Uses OSRM driving durations by default. Add --no-driving for straight-line distance.)

            STEP 2: Note the target box ID
              Look for the ID column (e.g., "1")

            STEP 3: Check the gym's rules and pricing
              $ regybox dropin-details --target-box-id 1

            STEP 4: List available classes
              $ regybox dropin-classes --target-box-id 1 --date 2026-02-04

            STEP 5: Register for a class
              $ regybox dropin-register --target-box-id 1 --class-id 57105

            STEP 6: Verify registration
              $ regybox dropin-classes --target-box-id 1 --date 2026-02-04
              The class should show "Registered" status

            TO CANCEL:
              $ regybox dropin-unregister --target-box-id 1 --class-id 57105
            """)

        case "find-nearby-dropin", "nearby-dropin", "nearby":
            print("""
            WORKFLOW: Find & Book a Drop-In Class Near You
            ===============================================

            Best when you're travelling and want the closest class available.

            STEP 1: Find nearby classes across multiple gyms
              $ regybox dropin-nearby-classes --latitude 38.7223 --longitude=-9.1393 --limit 5
              This searches all nearby boxes and returns available classes
              sorted by driving time (OSRM). Add --no-driving for straight-line distance.

            STEP 2 (optional): Check the gym's rules and pricing
              $ regybox dropin-details --target-box-id <BOX_ID>

            STEP 3: Register for a class
              $ regybox dropin-register --target-box-id <BOX_ID> --class-id <CLASS_ID>

            STEP 4: Verify registration
              $ regybox dropin-classes --target-box-id <BOX_ID> --date <DATE>
              The class should show "Registered" status

            FOR AUTOMATION (JSON output):
              $ regybox dropin-nearby-classes --latitude 38.7223 --longitude=-9.1393 --limit 5 --json
              $ regybox dropin-register --target-box-id <BOX_ID> --class-id <CLASS_ID> --json

            TO CANCEL:
              $ regybox dropin-unregister --target-box-id <BOX_ID> --class-id <CLASS_ID>
            """)

        case "view-schedule", "schedule":
            print("""
            WORKFLOW: View Weekly Class Schedule
            =====================================

            STEP 1: List classes for each day of the week
              $ regybox classes --date 2026-02-03  # Monday
              $ regybox classes --date 2026-02-04  # Tuesday
              $ regybox classes --date 2026-02-05  # Wednesday
              # ... and so on

            FOR AUTOMATION (get multiple days):
              $ for d in 03 04 05 06 07; do
                  regybox classes --date 2026-02-$d --json
                done

            TO SEE YOUR REGISTRATIONS:
              Look for classes with "REGISTERED" in Action column
              Or filter JSON output by "isRegistered": true
            """)

        case "training-history", "history":
            print("""
            WORKFLOW: View Training Stats & Drop-In History
            ================================================

            STEP 1: View your home gym training summary
              $ regybox class-history --summary

            STEP 2: Include drop-in sessions in your averages
              $ regybox class-history --summary --include-dropins

            STEP 3: View your drop-in history
              $ regybox dropin-history

            STEP 4: View detailed attendance for a specific month
              $ regybox class-history --month 2026-01

            STEP 5: Filter by attendance type
              $ regybox class-history --type absent     # missed classes
              $ regybox class-history --type present    # attended classes

            FOR AUTOMATION (JSON output):
              $ regybox class-history --summary --include-dropins --json
              $ regybox dropin-history --json
            """)

        default:
            print("Unknown workflow: \(name)")
            print("\nAvailable workflows:")
            print("  list-boxes, book-class, cancel-class, dropin-visit, find-nearby-dropin, view-schedule, training-history")
            print("\nRun 'regybox workflows' to see all options.")
        }
    }
}

// MARK: - Demo Command (default)

struct Demo: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "demo",
        abstract: "Run full demo showcasing all client features",
        discussion: """
        Runs an interactive demo that exercises all API features.

        This is useful for:
          - Testing your credentials work correctly
          - Seeing what data is available
          - Learning how the CLI works

        EXAMPLES:
          regybox demo
          regybox demo --limit 10
          regybox demo --drop-in-box-id 5
        """
    )

    @Option(name: .shortAndLong, help: "Box ID to login to (default: 299)")
    var boxId: String?

    @Option(name: .shortAndLong, help: "Email address (or set REGIBOX_EMAIL env var)")
    var email: String?

    @Option(name: .shortAndLong, help: "Password (or set REGIBOX_PASSWORD env var)")
    var password: String?

    @Option(name: .shortAndLong, help: "Number of items to show in lists")
    var limit: Int = 5

    @Option(name: .long, help: "Drop-in box ID to demo (default: 1)")
    var dropInBoxId: String = "1"

    func run() async throws {
        let resolvedEmail = email ?? ProcessInfo.processInfo.environment["REGIBOX_EMAIL"]
        let resolvedPassword = password ?? ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"]
        let resolvedBoxId = boxId ?? ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] ?? "299"

        print("""
        ╔══════════════════════════════════════════════════════════╗
        ║              RegiBox Client Demo                         ║
        ╚══════════════════════════════════════════════════════════╝
        """)

        let client = RegiBoxClient()

        // Demo 1: List Boxes (no auth required)
        print("\n\u{1F4E6} DEMO 1: Listing available boxes...")
        print(String(repeating: "─", count: 50))

        let boxes = try await client.listBoxes()
        print("Found \(boxes.count) boxes!\n")

        print("First \(limit) boxes:")
        for box in boxes.prefix(limit) {
            print("  [\(box.id)] \(box.name)")
        }

        // Demo 2: Login (if credentials provided)
        guard let email = resolvedEmail, let password = resolvedPassword else {
            print("\n\u{26A0}\u{FE0F}  Skipping authenticated demos - no credentials provided")
            print("   Set REGIBOX_EMAIL and REGIBOX_PASSWORD env vars")
            print("   Set REGIBOX_BOX_ID to your gym's ID as well")
            print("\n\u{2705} Demo complete! (unauthenticated)")
            return
        }

        print("\n\u{1F511} DEMO 2: Logging in...")
        print(String(repeating: "─", count: 50))
        print("Box ID: \(resolvedBoxId)")
        print("Email:  \(email)")

        _ = try await client.login(
            boxId: resolvedBoxId,
            email: email,
            password: password
        )

        print("\n\u{2705} Login successful!")
        print("  Authenticated: \(client.isAuthenticated)")

        // Find the box name
        let homeBoxName = boxes.first(where: { $0.id == resolvedBoxId })?.name ?? "Unknown"
        print("  Box Name: \(homeBoxName)")

        // Demo 3: Today's Classes
        print("\n\u{1F4C5} DEMO 3: Today's classes at \(homeBoxName)...")
        print(String(repeating: "─", count: 50))

        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: today)
        print("Date: \(dateString)\n")

        let classes = try await client.getClasses(for: today)

        if classes.isEmpty {
            print("No classes found for today.")
        } else {
            print("Found \(classes.count) classes:")
            for classItem in classes.prefix(limit) {
                let time = classItem.timeRange.padding(toLength: 13, withPad: " ", startingAt: 0)
                let name = String(classItem.name.prefix(16)).padding(toLength: 18, withPad: " ", startingAt: 0)
                let location = String(classItem.location.prefix(10)).padding(toLength: 12, withPad: " ", startingAt: 0)
                let capacity = classItem.capacityText.padding(toLength: 8, withPad: " ", startingAt: 0)
                let status: String
                switch classItem.status {
                case .completed: status = "Completed"
                case .inProgress: status = "In Progress"
                case .available: status = classItem.hasAvailability ? "Available" : "Full"
                }
                print("  \(time) \(name) \(location) \(capacity) \(status)")
            }
            if classes.count > limit {
                print("  ... and \(classes.count - limit) more")
            }
        }

        // Demo 4: Class Details
        if let firstClass = classes.first {
            print("\n\u{1F4CB} DEMO 4: Class details for \(firstClass.name)...")
            print(String(repeating: "─", count: 50))
            print("Class ID: \(firstClass.id)")

            let details = try await client.getClassDetails(firstClass)

            if !details.instructors.isEmpty {
                print("Instructors: \(details.instructors.map { $0.name }.joined(separator: ", "))")
            }

            if let workout = details.workout, !workout.isEmpty {
                print("\nWorkout:")
                if let warmUp = workout.warmUp {
                    print("  Warm-Up: \(warmUp.prefix(60))...")
                }
                if let strength = workout.strength {
                    print("  Strength: \(strength.prefix(60))...")
                }
                if let condition = workout.condition {
                    print("  Conditioning: \(condition.prefix(60))...")
                }
            }

            print("Participants: \(details.participants.count) enrolled")
        } else {
            print("\n\u{1F4CB} DEMO 4: Skipping class details (no classes today)")
        }

        // Demo 5: Drop-In Boxes
        print("\n\u{1F30D} DEMO 5: Drop-in boxes with GPS...")
        print(String(repeating: "─", count: 50))

        let dropInBoxes = try await client.listDropInBoxes()
        print("Found \(dropInBoxes.count) boxes available for drop-in!\n")

        print("First \(limit) boxes:")
        for box in dropInBoxes.prefix(limit) {
            let coords: String
            if let lat = box.latitude, let lng = box.longitude {
                coords = String(format: "(%.4f, %.4f)", lat, lng)
            } else {
                coords = "(no GPS)"
            }
            print("  [\(box.id)] \(box.name) \(coords)")
        }

        // Demo 6: Drop-In Box Details
        print("\n\u{1F4CD} DEMO 6: Drop-in box details (box ID: \(dropInBoxId))...")
        print(String(repeating: "─", count: 50))

        do {
            let boxDetails = try await client.getDropInBoxDetails(boxId: dropInBoxId)
            print("Box: \(boxDetails.box.name)")
            print("\nRules:")
            print("  Registration advance: \(boxDetails.rules.registrationAdvanceDays) days, \(boxDetails.rules.registrationAdvanceMinutes) min")
            print("  Registration cutoff:  \(boxDetails.rules.registrationCutoffMinutes) min before class")
            print("  Cancellation cutoff:  \(boxDetails.rules.cancellationCutoffMinutes) min before class")
            print("  Max absences:         \(boxDetails.rules.maxAllowedAbsences)")
            if !boxDetails.rules.price.isEmpty {
                print("  Price:                \(boxDetails.rules.price)")
            }

            if !boxDetails.schedule.isEmpty {
                print("\nSchedule:")
                for day in boxDetails.schedule.prefix(3) {
                    let dayName = day.dayName.padding(toLength: 15, withPad: " ", startingAt: 0)
                    print("  \(dayName) \(day.hours)")
                }
                if boxDetails.schedule.count > 3 {
                    print("  ... and \(boxDetails.schedule.count - 3) more days")
                }
            }

            if !boxDetails.availableClassTypes.isEmpty {
                print("\nClass types: \(boxDetails.availableClassTypes.joined(separator: ", "))")
            }
        } catch {
            print("Could not fetch box details: \(error.localizedDescription)")
        }

        // Demo 7: Drop-In Classes
        print("\n\u{1F3CB} DEMO 7: Drop-in classes at box \(dropInBoxId)...")
        print(String(repeating: "─", count: 50))
        print("Date: \(dateString)\n")

        do {
            let dropInClasses = try await client.getDropInClasses(boxId: dropInBoxId, for: today)

            if dropInClasses.isEmpty {
                print("No drop-in classes found for today.")
            } else {
                print("Found \(dropInClasses.count) classes:")
                for classItem in dropInClasses.prefix(limit) {
                    let time = classItem.timeRange.padding(toLength: 15, withPad: " ", startingAt: 0)
                    let name = String(classItem.name.prefix(12)).padding(toLength: 14, withPad: " ", startingAt: 0)
                    let location = String(classItem.location.prefix(8)).padding(toLength: 10, withPad: " ", startingAt: 0)
                    let status: String
                    switch classItem.status {
                    case .completed: status = "Completed"
                    case .inProgress: status = "In Progress"
                    case .available: status = "Available"
                    case .registered: status = "Registered"
                    case .unavailable: status = "Unavailable"
                    }
                    print("  \(time) \(name) \(location) \(status)")
                }
                if dropInClasses.count > limit {
                    print("  ... and \(dropInClasses.count - limit) more")
                }
            }
        } catch {
            print("Could not fetch drop-in classes: \(error.localizedDescription)")
        }

        // Demo 8: Logout
        print("\n\u{1F6AA} DEMO 8: Logging out...")
        print(String(repeating: "─", count: 50))
        client.logout()
        print("Authenticated after logout: \(client.isAuthenticated)")

        print("\n\u{2705} Demo complete!")
    }
}
