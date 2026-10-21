# RegiBoxClient

A Swift client library for the [RegiBox](https://www.regibox.pt) fitness platform, enabling iOS/macOS apps to interact with gym scheduling systems. This is an independent, unofficial project and is not affiliated with or endorsed by RegiBox.

## Current RegiBox app

The client uses RegiBox's current browser app at `https://www.regibox.pt/php8/app3`.
Login first opens the PWA root to initialize the PHP session and CSRF token, then submits
the login form. Class lists, history, drop-in gyms and classes, and check-in all use
the current app's page and script routes. The retired `/app/app_nova` routes are no
longer used by the client.

The booking and cancellation routes have been updated from the current app's
buttons. These calls change real registrations; use them only when you intend to
book or cancel a place.

## Features

- List all available boxes/gyms
- Authenticate with email/password
- Fetch classes for any date
- Get class details including workout description and instructors
- **Drop-In Support:**
  - Browse boxes with GPS coordinates for nearby discovery
  - View box rules, schedules, and pricing
  - List available drop-in classes at any box
  - Register/unregister for drop-in classes
- Register/unregister for classes at your own gym
- View class and drop-in history, and retrieve a check-in QR code

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+

## Installation

### CLI (Homebrew)

Install the `regybox` command-line tool on macOS with Homebrew:

```bash
brew install bernardo-cs/tap/regybox
```

To build the latest unreleased code from the `main` branch instead:

```bash
brew install --HEAD bernardo-cs/tap/regybox
```

Check the installation:

```bash
regybox --version
regybox --help
```

### CLI (from source)

```bash
git clone https://github.com/bernardo-cs/RegiBoxClient.git
cd RegiBoxClient
swift build -c release
cp .build/release/regybox /usr/local/bin/
```

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bernardo-cs/RegiBoxClient.git", branch: "main")
]
```

Or in Xcode: File > Add Package Dependencies > enter the repository URL. Use a
version requirement after a release is tagged.

## Usage

### List Available Boxes

```swift
import RegiBoxClient

let client = RegiBoxClient()
let boxes = try await client.listBoxes()

for box in boxes {
    print("\(box.id): \(box.name)")
}
```

### Login

```swift
let session = try await client.login(
    boxId: "299",
    email: "user@example.com",
    password: "password"
)

print("Logged in to box \(session.boxId)")
```

### Get Classes for a Date

```swift
// Get today's classes
let classes = try await client.getClasses()

// Get classes for a specific date
let date = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 15))!
let classes = try await client.getClasses(for: date)

for classItem in classes {
    print("\(classItem.timeRange) - \(classItem.name)")
    print("  Location: \(classItem.location)")
    print("  Capacity: \(classItem.capacityText)")
    print("  Status: \(classItem.status)")
}
```

### Get Class Details

```swift
let classes = try await client.getClasses()

if let firstClass = classes.first {
    let details = try await client.getClassDetails(firstClass)

    // Instructors
    for instructor in details.instructors {
        print("Coach: \(instructor.name)")
    }

    // Workout
    if let workout = details.workout {
        print(workout.formattedDescription)
    }

    // Participants
    for participant in details.participants {
        print("\(participant.position). \(participant.name)")
    }
}
```

### Logout

```swift
client.logout()
```

## Drop-In Usage

### List Drop-In Boxes with GPS

```swift
// Get all boxes available for drop-in visits
let boxes = try await client.listDropInBoxes()

for box in boxes {
    print("\(box.name)")
    if let lat = box.latitude, let lng = box.longitude {
        print("  Location: \(lat), \(lng)")
    }
    if let address = box.address {
        print("  Address: \(address)")
    }
}

// Search for boxes by name or location
let nearbyBoxes = try await client.searchDropInBoxes(query: "Porto")
```

### Get Box Details (Rules, Schedule, Pricing)

```swift
let details = try await client.getDropInBoxDetails(boxId: "1")

print("Box: \(details.box.name)")
print("Price: \(details.rules.price)")
print("Registration advance: \(details.rules.registrationAdvanceDays) days")
print("Cancellation cutoff: \(details.rules.cancellationCutoffMinutes) minutes")

// Show schedule
for day in details.schedule {
    print("\(day.dayName): \(day.hours)")
}
```

### Get Drop-In Classes

```swift
// Get classes for a specific box and date
let classes = try await client.getDropInClasses(boxId: "1", for: Date())

for classItem in classes {
    print("\(classItem.timeRange) - \(classItem.name)")
    print("  Status: \(classItem.status)")
    print("  Can register: \(classItem.canRegister)")
}
```

### Register/Unregister for Drop-In Class

```swift
// Register for a class
let registered = try await client.registerForDropInClass(
    classId: "57105",
    boxId: "1"
)

if registered {
    print("Successfully registered!")
}

// Unregister from a class
let unregistered = try await client.unregisterFromDropInClass(
    classId: "57105",
    boxId: "1"
)
```

## iOS App Integration

The library uses Swift concurrency and depends on SwiftSoup for HTML parsing.

### Step 1: Add Package to Xcode

1. Open your iOS project in Xcode
2. File > Add Package Dependencies
3. Enter the repository URL
4. Select "Up to Next Major Version"

### Step 2: Create a Session Manager

```swift
import SwiftUI
import RegiBoxClient

@MainActor
class RegiBoxManager: ObservableObject {
    static let shared = RegiBoxManager()

    private let client = RegiBoxClient()

    @Published var isAuthenticated = false
    @Published var currentBoxId: String?
    @Published var classes: [Class] = []
    @Published var isLoading = false
    @Published var error: String?

    func login(boxId: String, email: String, password: String) async {
        isLoading = true
        error = nil

        do {
            _ = try await client.login(boxId: boxId, email: email, password: password)
            isAuthenticated = true
            currentBoxId = boxId
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadClasses(for date: Date = Date()) async {
        isLoading = true

        do {
            classes = try await client.getClasses(for: date)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func getClassDetails(_ classItem: Class) async -> ClassDetails? {
        do {
            return try await client.getClassDetails(classItem)
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func logout() {
        client.logout()
        isAuthenticated = false
        currentBoxId = nil
        classes = []
    }
}
```

### Step 3: SwiftUI Views

**Login View:**
```swift
struct LoginView: View {
    @StateObject private var manager = RegiBoxManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var boxId = "299"

    var body: some View {
        Form {
            TextField("Box ID", text: $boxId)
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            SecureField("Password", text: $password)

            if let error = manager.error {
                Text(error).foregroundColor(.red)
            }

            Button("Login") {
                Task {
                    await manager.login(boxId: boxId, email: email, password: password)
                }
            }
            .disabled(manager.isLoading)
        }
    }
}
```

**Classes List View:**
```swift
struct ClassesListView: View {
    @StateObject private var manager = RegiBoxManager.shared
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            List(manager.classes) { classItem in
                NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                    ClassRow(classItem: classItem)
                }
            }
            .navigationTitle("Classes")
            .toolbar {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .onChange(of: selectedDate) { newDate in
                        Task { await manager.loadClasses(for: newDate) }
                    }
            }
            .task {
                await manager.loadClasses(for: selectedDate)
            }
            .refreshable {
                await manager.loadClasses(for: selectedDate)
            }
        }
    }
}

struct ClassRow: View {
    let classItem: Class

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(classItem.name).font(.headline)
                Spacer()
                Text(classItem.timeRange).font(.subheadline)
            }
            HStack {
                Text(classItem.location).foregroundColor(.secondary)
                Spacer()
                Text(classItem.capacityText)
                    .foregroundColor(classItem.hasAvailability ? .green : .red)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
```

**Class Detail View:**
```swift
struct ClassDetailView: View {
    let classItem: Class
    @State private var details: ClassDetails?
    @StateObject private var manager = RegiBoxManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading) {
                    Text(classItem.name).font(.largeTitle.bold())
                    Text("\(classItem.date) | \(classItem.timeRange)")
                    Text(classItem.location).foregroundColor(.secondary)
                }

                Divider()

                // Workout
                if let workout = details?.workout {
                    WorkoutView(workout: workout)
                }

                // Instructors
                if let instructors = details?.instructors, !instructors.isEmpty {
                    Section("Instructors") {
                        ForEach(instructors, id: \.name) { instructor in
                            Text(instructor.name)
                        }
                    }
                }

                // Participants
                if let participants = details?.participants, !participants.isEmpty {
                    Section("Enrolled (\(participants.count))") {
                        ForEach(participants, id: \.name) { participant in
                            Text("\(participant.position). \(participant.name)")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(classItem.name)
        .task {
            details = await manager.getClassDetails(classItem)
        }
    }
}

struct WorkoutView: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let warmUp = workout.warmUp {
                WorkoutPart(title: "Warm-Up", content: warmUp)
            }
            if let skill = workout.skill {
                WorkoutPart(title: "Skill", content: skill)
            }
            if let strength = workout.strength {
                WorkoutPart(title: "Strength", content: strength)
            }
            if let condition = workout.condition {
                WorkoutPart(title: "Conditioning", content: condition)
            }
        }
    }
}

struct WorkoutPart: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(content).font(.body)
        }
    }
}
```

### Step 4: Secure Credential Storage (Recommended)

Store credentials in Keychain instead of UserDefaults:

```swift
import Security

enum KeychainHelper {
    static func save(password: String, for account: String) {
        let data = password.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func getPassword(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

### iOS Integration Considerations

| Aspect | Status | Notes |
|--------|--------|-------|
| Async/await | Ready | All methods are async |
| SwiftUI | Ready | Models are Sendable |
| Combine | Compatible | Wrap in Future if needed |
| Background refresh | Possible | Use BGTaskScheduler |
| Offline support | Not included | Add caching layer if needed |
| Session persistence | Not included | Login again after creating a new client |

### What's NOT Included (Future Features)

- Profile management
- Push notifications
- Offline caching
- Widget support

## CLI

The `regybox` command-line tool is included in the package. Install it with Homebrew
(see [Installation](#installation)) or run it from the checkout with `regybox`.

```bash
# Set credentials for commands that require login. Keep them out of source control.
export REGIBOX_EMAIL="your@email.com"
export REGIBOX_PASSWORD="yourpassword"
export REGIBOX_BOX_ID="299"

# List boxes
regybox list-boxes

# List today's classes
regybox classes

# List classes for specific date
regybox classes --date 2026-01-15

# Get class details
regybox class-detail 84998 --date 2026-01-12

# Run full demo
regybox

# Drop-In commands
regybox dropin-boxes                              # List all drop-in boxes with GPS
regybox dropin-details --target-box-id 1          # Get box rules & schedule
regybox dropin-classes --target-box-id 1          # List classes at a box
regybox dropin-register --target-box-id 1 --class-id 57105    # Register
regybox dropin-unregister --target-box-id 1 --class-id 57105  # Unregister
```

## Models

### Box
```swift
struct Box {
    let id: String      // Box identifier
    let name: String    // Display name
}
```

### Class
```swift
struct Class {
    let id: String
    let name: String        // e.g., "CROSS TRAINING"
    let location: String    // e.g., "Black Box"
    let startTime: String   // "HH:mm"
    let endTime: String     // "HH:mm"
    let enrolled: Int
    let capacity: Int
    let status: ClassStatus // .completed, .inProgress, .available
    let date: String        // "YYYY-MM-DD"

    var timeRange: String       // "HH:mm - HH:mm"
    var capacityText: String    // "X de Y"
    var hasAvailability: Bool
}
```

### ClassDetails
```swift
struct ClassDetails {
    let classInfo: Class
    let instructors: [Instructor]
    let workout: Workout?
    let participants: [Participant]
}

struct Instructor {
    let name: String
    let photoURL: URL?
}

struct Workout {
    let warmUp: String?
    let skill: String?
    let strength: String?
    let condition: String?

    var formattedDescription: String
}

struct Participant {
    let name: String
    let position: Int
    let photoURL: URL?
}
```

### DropInBox
```swift
struct DropInBox {
    let id: String
    let name: String
    let address: String?
    let latitude: Double?
    let longitude: Double?
    var logoURL: URL?     // Auto-generated from box ID
}
```

### DropInBoxDetails
```swift
struct DropInBoxDetails {
    let box: DropInBox
    let rules: DropInRules
    let availableClassTypes: [String]  // e.g., ["WOD", "OPENBOX", "PILATES"]
    let schedule: [DaySchedule]
    let socialLinks: SocialLinks?
}

struct DropInRules {
    let registrationAdvanceDays: Int
    let registrationAdvanceMinutes: Int
    let registrationCutoffMinutes: Int
    let cancellationCutoffMinutes: Int
    let maxAllowedAbsences: Int
    let price: String              // e.g., "€12,00"
}

struct DaySchedule {
    let dayName: String            // e.g., "Segunda-feira"
    let hours: String              // e.g., "06:40 - 21:00" or "Encerrado"
    var isClosed: Bool
}

struct SocialLinks {
    let website: URL?
    let facebook: URL?
    let instagram: URL?
}
```

### DropInClass
```swift
struct DropInClass {
    let id: String
    let name: String           // e.g., "WOD", "OPENBOX"
    let location: String       // e.g., "Aves", "Box 2"
    let startTime: String      // "HH:mm"
    let endTime: String        // "HH:mm"
    let status: DropInClassStatus
    let date: String           // "YYYY-MM-DD"
    let boxId: String

    var timeRange: String      // "HH:mm -> HH:mm"
    var canRegister: Bool      // true if status == .available
    var canCancel: Bool        // true if status == .registered
}

enum DropInClassStatus {
    case completed      // Class has ended
    case inProgress     // Class is currently running
    case available      // Open for registration
    case registered     // User is already registered
    case unavailable    // Cannot register (full, closed, etc.)
}
```

## Error Handling

```swift
do {
    let classes = try await client.getClasses()
} catch RegiBoxClient.ClientError.notAuthenticated {
    print("Please login first")
} catch RegiBoxClient.ClientError.parsingError(let message) {
    print("Failed to parse response: \(message)")
} catch {
    print("Request failed: \(error)")
}
```

## Tests and credentials

Run `swift test` for the local fixture tests. Some integration tests contact the
live RegiBox service only when `REGIBOX_RUN_LIVE_TESTS=1` and
`REGIBOX_EMAIL`, `REGIBOX_PASSWORD`, and `REGIBOX_BOX_ID` are set. Use a test
account if available. Never commit credentials, cookies, session tokens, QR
codes, or captured responses containing personal data. Keep `.envrc` local.
Prefer `REGIBOX_PASSWORD` over `--password`, which can appear in shell history
and process listings.

The client parses pages from RegiBox's browser app. Their HTML and routes can
change without notice, so a passing fixture test does not guarantee that the
live service still works.

When driving duration is requested, the CLI sends your coordinates and gym
coordinates to the public OSRM demo server. Use `--no-driving` to keep location
calculations local.

## License

MIT. See [LICENSE](LICENSE).
