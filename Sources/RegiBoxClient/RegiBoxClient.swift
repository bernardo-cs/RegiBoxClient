import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import SwiftSoup

// MARK: - Cross-platform URLSession async compatibility
extension URLSession {
    public func asyncData(for request: URLRequest, cookieStorage: HTTPCookieStorage? = nil) async throws -> (Data, URLResponse) {
        #if canImport(FoundationNetworking)
        // Linux: wrap callback-based API and manually handle cookies
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response {
                    // Manually store cookies from response on Linux
                    if let httpResponse = response as? HTTPURLResponse,
                       let url = response.url,
                       let headerFields = httpResponse.allHeaderFields as? [String: String],
                       let storage = cookieStorage {
                        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
                        for cookie in cookies {
                            storage.setCookie(cookie)
                        }
                    }
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: URLError(.unknown))
                }
            }
            task.resume()
        }
        #else
        // macOS/iOS: use native async API
        return try await self.data(for: request)
        #endif
    }
}

/// Client for interacting with the RegiBox fitness platform API
public final class RegiBoxClient: @unchecked Sendable {

    // MARK: - Constants

    private enum API {
        static let currentURL = "https://www.regibox.pt/php8/app3"
    }

    // MARK: - Errors

    public enum ClientError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case parsingError(String)
        case loginFailed(String)
        case noSessionToken
        case notAuthenticated

        public var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .parsingError(let message):
                return "Parsing error: \(message)"
            case .loginFailed(let message):
                return "Login failed: \(message)"
            case .noSessionToken:
                return "No session token found in response"
            case .notAuthenticated:
                return "Not authenticated. Please login first."
            }
        }
    }

    // MARK: - Result Types

    /// Result from querying drop-in classes at a nearby box
    public struct NearbyDropInResult: Sendable {
        public let box: DropInBox
        public let distanceKm: Double?
        public let drivingDurationSeconds: Double?
        public let classes: [DropInClass]
        public let error: String?
    }

    // MARK: - Properties

    private let urlSession: URLSession
    private let cookieStorage: HTTPCookieStorage

    /// The current authenticated session, if any
    public private(set) var session: Session?

    /// Whether the client is currently authenticated
    public var isAuthenticated: Bool {
        session != nil
    }

    // MARK: - Initialization

    public init() {
        // Use ephemeral configuration which creates its own cookie storage
        // This avoids issues with HTTPCookieStorage.shared on Linux
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true

        // ephemeral configuration creates its own cookie storage
        self.cookieStorage = configuration.httpCookieStorage ?? HTTPCookieStorage.shared
        self.urlSession = URLSession(configuration: configuration)
    }

    // MARK: - Internal Networking

    /// Performs an async data request with proper cookie handling for both macOS and Linux
    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        #if canImport(FoundationNetworking)
        // On Linux, manually add cookies to request and store cookies from response
        var mutableRequest = request
        if let url = request.url, let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty {
            let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookies)
            for (key, value) in cookieHeaders {
                mutableRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, response) = try await urlSession.asyncData(for: mutableRequest, cookieStorage: cookieStorage)
        return (data, response)
        #else
        return try await urlSession.asyncData(for: request)
        #endif
    }

    // MARK: - Public Methods

    /// Lists all available boxes/gyms
    /// - Returns: Array of Box objects
    public func listBoxes() async throws -> [Box] {
        let html = try await currentHTML("/pwa/999999/pages/login/escolha_clube.php?lang=pt")
        let boxes = HTMLParserV3.boxes(html)
        guard !boxes.isEmpty else { throw ClientError.parsingError("No boxes found in current app response") }
        return boxes
    }

    /// Logs into a specific box
    /// - Parameters:
    ///   - boxId: The ID of the box to log into
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Session object containing authentication info
    @discardableResult
    public func login(boxId: String, email: String, password: String) async throws -> Session {
        guard !boxId.isEmpty, boxId.allSatisfy({ $0 >= "0" && $0 <= "9" }) else {
            throw ClientError.parsingError("Box ID must contain only digits")
        }
        // The PWA root initializes the PHP session and CSRF token. Fetching the
        // login fragment directly yields an empty token and a rejected login.
        _ = try await currentHTML("/pwa/999999/?pwa=999999&id_box=\(boxId)&lang=pt&type=direct")
        let form = try await currentHTML("/pwa/999999/pages/login/login.php?pwa=999999&id_box=\(boxId)&lang=pt&type=direct")
        guard let document = try? SwiftSoup.parse(form),
              let csrf = try? document.select("input[name=csrf_token]").first()?.attr("value"), !csrf.isEmpty,
              let acs = try? document.select("input[name=acs]").first()?.attr("value"), !acs.isEmpty,
              let emailInput = try? document.select("input[name^=login]").array().first(where: { (try? $0.attr("name")) != "login" }),
              let suffix = try? emailInput.attr("name").dropFirst(5), !suffix.isEmpty else {
            throw ClientError.parsingError("Could not read the current login form")
        }
        let body = formBody([
            "csrf_token": csrf, "id_box": boxId, "login": "", "pwa": "999999",
            "lingua": "pt", "acs": acs, "v": "", "login\(suffix)": email,
            "password\(suffix)": password, "but_dados": "LOGIN"
        ])
        let response = try await currentHTML(
            "/pwa/999999/pages/login/scripts/verifica_acesso.php?pwa=999999&id_box=\(boxId)&type=direct",
            method: "POST", body: body)
        guard let json = try? JSONSerialization.jsonObject(with: Data(response.utf8)) as? [String: Any],
              json["action"] as? String == "verifica_acesso_fun",
              (json["id"] as? String) == boxId else {
            throw ClientError.loginFailed("The current app rejected the login")
        }
        let shell = try await currentHTML("/pwa/\(boxId)/?pwa=\(boxId)&ignore=s")
        guard !shell.contains("pages/login/index.php") else {
            throw ClientError.loginFailed("The current app did not establish a session")
        }
        let cookies = cookieStorage.cookies(for: URL(string: API.currentURL)!) ?? []
        guard let userCookie = cookies.first(where: { $0.name == "regy_user" }) else {
            throw ClientError.loginFailed("The current app did not set its login cookie")
        }
        let session = Session(userToken: userCookie.value, boxId: boxId, cookies: cookies)
        self.session = session
        return session
    }

    /// Logs out and clears the current session
    public func logout() {
        session = nil

        // Clear RegiBox cookies
        if let cookies = cookieStorage.cookies {
            for cookie in cookies where cookie.domain.contains("regibox") {
                cookieStorage.deleteCookie(cookie)
            }
        }
    }

    // MARK: - Classes Methods

    /// Get classes for a specific date
    /// - Parameter date: Date to fetch classes for (defaults to today)
    /// - Returns: Array of Class objects
    /// - Throws: ClientError if not authenticated or request fails
    public func getClasses(for date: Date = Date()) async throws -> [Class] {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        let html = try await currentHTML("/pages/classes/classes_list.php?date=\(dateString)&type=1&plano=0&box=")
        guard html.contains("a_remaining") || html.contains("feed_time_slot") || html.contains("msg-image-container") else {
            throw ClientError.parsingError("Current class list response has an unexpected format")
        }
        return HTMLParserV3.classes(html, date: dateString)
    }

    /// Get detailed information about a specific class
    /// - Parameter classItem: The class to get details for
    /// - Returns: ClassDetails with instructors, workout, and participants
    /// - Throws: ClientError if not authenticated or request fails
    public func getClassDetails(_ classItem: Class) async throws -> ClassDetails {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        guard let route = classItem.detailsURL,
              route.hasPrefix("/class_details/?") else {
            throw ClientError.parsingError("Class detail link is missing from the current class list")
        }
        let path = route.replacingOccurrences(of: "/class_details/?", with: "/pages/classes/class_details.php?")
        let html = try await currentHTML(path)
        guard let details = HTMLParserV3.classDetails(html, classInfo: classItem) else {
            throw ClientError.parsingError("Could not parse current class details")
        }
        guard let feed = HTMLParserV3.workoutFeedPath(html),
              let feedHTML = try? await currentHTML(feed),
              let workout = HTMLParserV3.workout(feedHTML), !workout.isEmpty else { return details }
        return ClassDetails(classInfo: details.classInfo, instructors: details.instructors,
                            workout: workout, participants: details.participants)
    }

    /// Get the user's registered drop-in classes from the main page
    /// - Returns: Array of MyDropIn objects
    /// - Throws: ClientError if not authenticated or request fails
    public func getMyDropIns() async throws -> [MyDropIn] {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        let html = try await currentHTML("/pages/dropin/dropin.php")
        guard let entries = HTMLParserV3.myDropIns(html) else {
            throw ClientError.parsingError("Could not parse current drop-in bookings")
        }
        return entries
    }

    // MARK: - Class Registration Methods (Own Gym)

    /// Register for a class at your own gym (non-drop-in)
    /// - Parameter classItem: The class to register for (must have bookingURL)
    /// - Returns: Bool indicating success
    /// - Throws: ClientError if not authenticated, class is not bookable, or request fails
    @discardableResult
    public func registerForClass(_ classItem: Class) async throws -> Bool {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        guard let url = classItem.bookingURL else {
            throw ClientError.parsingError("This class has no current booking link")
        }
        return try await currentClassAction(url, expectedScript: "book_classes.php")
    }

    /// Unregister from a class at your own gym (non-drop-in)
    /// - Parameter classItem: The class to unregister from (must have cancelURL)
    /// - Returns: Bool indicating success
    /// - Throws: ClientError if not authenticated, class is not cancellable, or request fails
    @discardableResult
    public func unregisterFromClass(_ classItem: Class) async throws -> Bool {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        guard let url = classItem.cancelURL else {
            throw ClientError.parsingError("This class has no current cancellation link")
        }
        return try await currentClassAction(url, expectedScript: "cancel_class.php")
    }

    // MARK: - Drop-In Methods

    /// List all boxes available for drop-in visits with GPS coordinates
    /// - Returns: Array of DropInBox objects
    /// - Throws: ClientError if not authenticated or request fails
    public func listDropInBoxes() async throws -> [DropInBox] {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        let html = try await currentHTML("/pages/dropin/find_box.php")
        let boxes = HTMLParserV3.dropInBoxes(html)
        guard !boxes.isEmpty else { throw ClientError.parsingError("No drop-in boxes found in current app response") }
        return boxes
    }

    /// Search drop-in boxes by name or address (client-side filtering)
    /// The backend ignores the search parameter, so we fetch all boxes and filter locally
    /// - Parameter query: Search string to match against box name and address (case-insensitive)
    /// - Returns: Array of matching DropInBox objects
    /// - Throws: ClientError if not authenticated or request fails
    public func searchDropInBoxes(query: String) async throws -> [DropInBox] {
        let allBoxes = try await listDropInBoxes()
        guard !query.isEmpty else { return allBoxes }
        return allBoxes.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            ($0.address?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    /// Get detailed info about a box for drop-in (rules, schedule, pricing)
    /// - Parameter boxId: The box ID to get details for
    /// - Returns: DropInBoxDetails with rules and schedule
    /// - Throws: ClientError if not authenticated or request fails
    public func getDropInBoxDetails(boxId: String) async throws -> DropInBoxDetails {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        let box = try await currentDropInBox(boxId)
        guard let acs = box.acsToken else { throw ClientError.parsingError("Missing drop-in access token") }
        let path = "/pages/dropin/box_regras.php?cod=\(box.code)&acs=\(acs)" + (box.subBox > 0 ? "&sub=\(box.subBox)" : "")
        let html = try await currentHTML(path)
        guard let details = HTMLParserV3.dropInDetails(html, box: box) else {
            throw ClientError.parsingError("Could not parse current drop-in box details")
        }
        return details
    }

    /// Get drop-in classes for a specific box and date
    /// - Parameters:
    ///   - boxId: The box ID
    ///   - date: Date to fetch classes for (defaults to today)
    /// - Returns: Array of DropInClass objects
    /// - Throws: ClientError if not authenticated or request fails
    public func getDropInClasses(boxId: String, for date: Date = Date()) async throws -> [DropInClass] {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        let box = try await currentDropInBox(boxId)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return try await currentDropInClasses(box: box, dateString: formatter.string(from: date))
    }

    /// Get drop-in classes from multiple boxes in parallel
    /// - Parameters:
    ///   - boxes: Array of DropInBox objects to query
    ///   - distances: Dictionary mapping box ID to distance in km
    ///   - date: Date to fetch classes for
    /// - Returns: Array of NearbyDropInResult, one per box
    /// - Throws: ClientError if not authenticated or ACS token fetch fails
    public func getDropInClassesForMultipleBoxes(
        boxes: [DropInBox],
        distances: [String: Double],
        drivingDurations: [String: Double]? = nil,
        for date: Date
    ) async throws -> [NearbyDropInResult] {
        guard isAuthenticated else {
            throw ClientError.notAuthenticated
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        return await withTaskGroup(of: NearbyDropInResult.self, returning: [NearbyDropInResult].self) { group in
            for box in boxes {
                group.addTask {
                    do {
                        guard box.acsToken != nil else {
                            return NearbyDropInResult(
                                box: box,
                                distanceKm: distances[box.id],
                                drivingDurationSeconds: drivingDurations?[box.id],
                                classes: [],
                                error: "No ACS token for box \(box.id)"
                            )
                        }
                        let classes = try await self.currentDropInClasses(box: box, dateString: dateString)
                        return NearbyDropInResult(
                            box: box,
                            distanceKm: distances[box.id],
                            drivingDurationSeconds: drivingDurations?[box.id],
                            classes: classes,
                            error: nil
                        )
                    } catch {
                        return NearbyDropInResult(
                            box: box,
                            distanceKm: distances[box.id],
                            drivingDurationSeconds: drivingDurations?[box.id],
                            classes: [],
                            error: error.localizedDescription
                        )
                    }
                }
            }

            var results: [NearbyDropInResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }

    /// Get details for a drop-in class (workout, instructors)
    /// Uses the same class details endpoint as regular classes
    /// - Parameters:
    ///   - classId: The class ID
    ///   - date: Date string in YYYY-MM-DD format
    /// - Returns: ClassDetails with instructors, workout, and participants
    /// - Throws: ClientError if not authenticated or request fails
    public func getDropInClassDetails(classId: String, date: String, boxId: String? = nil) async throws -> ClassDetails {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        guard let boxId else {
            throw ClientError.parsingError("A box ID is required for current drop-in class details")
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let day = formatter.date(from: date) else {
            throw ClientError.parsingError("Invalid class date")
        }
        guard let item = try await getDropInClasses(boxId: boxId, for: day).first(where: { $0.id == classId }) else {
            throw ClientError.parsingError("Drop-in class was not found in the current app")
        }
        let classInfo = Class(id: item.id, name: item.name, location: item.location,
                              startTime: item.startTime, endTime: item.endTime, enrolled: 0,
                              capacity: 0, status: item.status == .completed ? .completed : .available,
                              date: item.date)
        let instructors = item.instructor.map { [Instructor(name: $0)] } ?? []
        return ClassDetails(classInfo: classInfo, instructors: instructors, workout: nil, participants: [])
    }

    /// Register for a drop-in class
    /// - Parameters:
    ///   - classId: The class ID to register for
    ///   - boxId: The box ID where the class is held
    /// - Returns: Bool indicating success
    /// - Throws: ClientError on failure
    @discardableResult
    public func registerForDropInClass(classId: String, boxId: String) async throws -> Bool {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        return try await currentDropInAction(classId: classId, boxId: boxId, script: "marca_dropin.php")
    }

    /// Unregister from a drop-in class
    /// - Parameters:
    ///   - classId: The class ID to unregister from
    ///   - boxId: The box ID where the class is held
    /// - Returns: Bool indicating success
    /// - Throws: ClientError on failure
    @discardableResult
    public func unregisterFromDropInClass(classId: String, boxId: String) async throws -> Bool {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        return try await currentDropInAction(classId: classId, boxId: boxId, script: "cancela_dropin.php")
    }

    // MARK: - Class History Methods

    /// Get the class history summary (stats + monthly chart data)
    /// - Returns: ClassHistorySummary with registration, attendance, absence counts and monthly breakdown
    /// - Throws: ClientError if not authenticated or request fails
    public func getClassHistorySummary() async throws -> ClassHistorySummary {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        let html = try await currentHTML("/pages/classes/classes_historic.php")
        guard let summary = HTMLParserV3.classHistorySummary(html) else {
            throw ClientError.parsingError("Could not parse current class history summary")
        }
        let chart = try await currentHTML("/pages/classes/scripts/classes_historic_load.php?yearOffset=0")
        guard let data = try? JSONSerialization.jsonObject(with: Data(chart.utf8)) as? [String: Any],
              let months = data["datas"] as? [String],
              let counts = data["valores"] as? [Int] else {
            throw ClientError.parsingError("Could not parse current class history chart")
        }
        let monthly = zip(months, counts).map { MonthlyAttendance(month: $0.0, count: $0.1) }
        return ClassHistorySummary(registrations: summary.registrations, attendances: summary.attendances,
                                   absences: summary.absences, monthlyData: monthly)
    }

    /// Get detailed class history entries for a date range
    /// - Parameters:
    ///   - startDate: Start date in YYYY-MM-DD format
    ///   - endDate: End date in YYYY-MM-DD format
    ///   - type: Filter type: "all", "pres" (attended), "falt" (absent), "insc" (registered)
    ///   - order: Sort order: "data_ini DESC", "data_ini ASC", or "aula ASC, data_ini DESC"
    /// - Returns: Array of ClassHistoryEntry objects
    /// - Throws: ClientError if not authenticated or request fails
    public func getClassHistory(startDate: String, endDate: String, type: String = "all", order: String = "data_ini DESC") async throws -> [ClassHistoryEntry] {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "data_ini", value: startDate), URLQueryItem(name: "data_fim", value: endDate),
                                 URLQueryItem(name: "ordem", value: order), URLQueryItem(name: "tipo", value: type)]
        let html = try await currentHTML("/pages/classes/classes_historic_list.php?" + (components.percentEncodedQuery ?? ""))
        guard html.contains("search-list") else {
            throw ClientError.parsingError("Current class history list has an unexpected format")
        }
        return HTMLParserV3.classHistory(html)
    }

    // MARK: - Drop-In History

    /// Get the user's drop-in history (summary stats and individual entries)
    /// - Returns: DropInHistorySummary with registrations, attendances, absences and entries
    /// - Throws: ClientError if not authenticated or request fails
    public func getDropInHistory() async throws -> DropInHistorySummary {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        let html = try await currentHTML("/pages/dropin/dropin.php")
        guard let history = HTMLParserV3.dropInHistory(html) else {
            throw ClientError.parsingError("Could not parse current drop-in history")
        }
        return history
    }

    // MARK: - Check-In QR Code

    /// Get the check-in QR code for gym entry
    /// - Returns: CheckInQRCode with code string, image URL, and PNG image data
    /// - Throws: ClientError if not authenticated, parsing fails, or image download fails
    public func getCheckInQRCode() async throws -> CheckInQRCode {
        guard isAuthenticated else { throw ClientError.notAuthenticated }
        let html = try await currentHTML("/pages/login/check_in.php")
        guard let document = try? SwiftSoup.parse(html),
              let source = try? document.select("img[src*=qr_code_gen.php]").first()?.attr("src"),
              let imageURL = URL(string: source, relativeTo: URL(string: API.currentURL)),
              let code = URLComponents(url: imageURL, resolvingAgainstBaseURL: true)?
                .queryItems?.first(where: { $0.name == "code" })?.value,
              !code.isEmpty else {
            throw ClientError.parsingError("Could not find current check-in QR code")
        }
        var request = URLRequest(url: imageURL)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (image, response) = try await performRequest(request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              image.starts(with: [0x89, 0x50, 0x4e, 0x47]) else {
            throw ClientError.parsingError("Current check-in endpoint did not return a PNG")
        }
        return CheckInQRCode(code: code, imageURL: imageURL.absoluteString, imageData: image)
    }

    // MARK: - Private Methods

    private var userAgent: String {
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
    }

    private func currentHTML(_ path: String, method: String = "GET", body: Data? = nil) async throws -> String {
        guard let url = URL(string: API.currentURL + path) else { throw ClientError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        if body != nil { request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type") }
        let (data, response) = try await performRequest(request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ClientError.networkError(URLError(.badServerResponse))
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw ClientError.parsingError("Could not decode current app response")
        }
        if html.contains("pages/login/index.php") && !path.contains("/pages/login/") && !path.contains("/pwa/999999/") {
            throw ClientError.notAuthenticated
        }
        return html
    }

    private func formBody(_ fields: [String: String]) -> Data {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._*"))
        let string = fields.sorted { $0.key < $1.key }.map { key, value in
            let k = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
            let v = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
            return "\(k)=\(v)"
        }.joined(separator: "&")
        return Data(string.utf8)
    }

    private func currentDropInBox(_ id: String) async throws -> DropInBox {
        guard let box = try await listDropInBoxes().first(where: { $0.id == id }) else {
            throw ClientError.parsingError("Drop-in box \(id) was not found")
        }
        return box
    }

    private func currentDropInClasses(box: DropInBox, dateString: String) async throws -> [DropInClass] {
        guard let acs = box.acsToken, !acs.isEmpty else {
            throw ClientError.parsingError("Missing drop-in access token")
        }
        let path = "/pages/dropin/aulas_dropin_list.php?date=\(dateString)&cod=\(box.code)&acs=\(acs)" +
            (box.subBox > 0 ? "&sub=\(box.subBox)" : "")
        let html = try await currentHTML(path)
        guard html.contains("a_aula") || html.contains("da-empty") || html.contains("Nenhuma") else {
            throw ClientError.parsingError("Current drop-in class list has an unexpected format")
        }
        return HTMLParserV3.dropInClasses(html, date: dateString, boxId: box.id)
    }

    private func currentClassAction(_ link: String, expectedScript: String) async throws -> Bool {
        guard link.hasPrefix("pages/classes/scripts/"),
              link.split(separator: "?", maxSplits: 1).first?.hasSuffix(expectedScript) == true else {
            throw ClientError.parsingError("Unexpected current class action URL")
        }
        let response = try await currentHTML("/" + link)
        guard let json = try? JSONSerialization.jsonObject(with: Data(response.utf8)) as? [String: Any],
              let success = json["success"] as? Bool else {
            throw ClientError.parsingError("Current class action returned an unexpected response")
        }
        return success
    }

    private func currentDropInAction(classId: String, boxId: String, script: String) async throws -> Bool {
        let box = try await currentDropInBox(boxId)
        guard let acs = box.acsToken else { throw ClientError.parsingError("Missing drop-in access token") }
        let body = formBody(["id_aula": classId, "box_id": box.code, "acs": acs])
        let response = try await currentHTML("/pages/dropin/scripts/\(script)", method: "POST", body: body)
        guard let json = try? JSONSerialization.jsonObject(with: Data(response.utf8)) as? [String: Any],
              let success = json["success"] as? Bool else {
            throw ClientError.parsingError("Current drop-in action returned an unexpected response")
        }
        return success
    }
}
