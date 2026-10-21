import Foundation
import SwiftSoup

/// Parses HTML responses from the RegiBox API using SwiftSoup
enum HTMLParser {

    // MARK: - Private Helpers

    /// Extracts a numeric ID from an onclick attribute value
    /// Example: "abre_login('299');" -> "299"
    private static func extractId(from onclick: String, pattern: String = #"(\d+)"#) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: onclick, range: NSRange(onclick.startIndex..., in: onclick)),
              let range = Range(match.range(at: 1), in: onclick) else {
            return nil
        }
        return String(onclick[range])
    }

    /// Extracts a parameter value from a query string in an onclick attribute
    /// Example: "open_page('dropin_regras','&valor1=123&acs=abc');" with param "valor1" -> "123"
    private static func extractParam(from onclick: String, param: String) -> String? {
        let pattern = "\(param)=(\\d+)"
        return extractId(from: onclick, pattern: pattern)
    }

    // MARK: - Box List Parsing

    /// Parses the box list HTML and returns an array of Box objects
    /// - Parameter html: HTML string from escolha_clube.php
    /// - Returns: Array of parsed Box objects
    static func parseBoxes(html: String) -> [Box] {
        var boxes: [Box] = []

        guard let doc = try? SwiftSoup.parse(html) else {
            return boxes
        }

        do {
            // The onclick is on a div, not an anchor
            // Structure: <div onclick="abre_login('ID');" class="item-inner">
            //               <div class="item-title">NAME</div>
            //           </div>
            let divs = try doc.select("div[onclick*=abre_login]")

            for div in divs {
                let onclick = try div.attr("onclick")

                // Extract box ID from onclick: abre_login('299');
                guard let id = extractId(from: onclick) else { continue }

                // Get the box name from item-title within this div
                let name = try div.select(".item-title").text().trimmingCharacters(in: .whitespacesAndNewlines)

                guard !name.isEmpty else { continue }

                boxes.append(Box(id: id, name: name))
            }
        } catch {
            // Return whatever we have on error
        }

        return boxes
    }

    // MARK: - Login Form Parsing

    /// Result of parsing the login form HTML
    struct LoginFormData {
        /// The ACS security token
        let acsToken: String
        /// The dynamic field suffix (e.g., "3990dca")
        let fieldSuffix: String
    }

    /// Parses the login form HTML to extract security tokens
    /// - Parameter html: HTML string from login.php
    /// - Returns: LoginFormData if parsing succeeds, nil otherwise
    static func parseLoginForm(html: String) -> LoginFormData? {
        guard let doc = try? SwiftSoup.parse(html) else {
            return nil
        }

        do {
            // Extract ACS token: <input name="acs" value="TOKEN" />
            let acsInput = try doc.select("input[name=acs]").first()
            guard let acsToken = try acsInput?.attr("value"), !acsToken.isEmpty else {
                return nil
            }

            // Extract field suffix from login field: name="login{SUFFIX}"
            // Find input where name starts with "login" but isn't just "login"
            let loginInputs = try doc.select("input[name^=login]")
            var fieldSuffix: String?

            for input in loginInputs {
                let name = try input.attr("name")
                if name.hasPrefix("login") && name != "login" {
                    fieldSuffix = String(name.dropFirst(5)) // Remove "login" prefix
                    break
                }
            }

            guard let suffix = fieldSuffix, !suffix.isEmpty else {
                return nil
            }

            return LoginFormData(acsToken: acsToken, fieldSuffix: suffix)
        } catch {
            return nil
        }
    }

    // MARK: - Classes Parsing

    /// Parses the classes list HTML from aulas.php
    /// - Parameters:
    ///   - html: HTML string from aulas.php
    ///   - date: Date string in YYYY-MM-DD format
    /// - Returns: Array of Class objects
    static func parseClasses(html: String, date: String) -> [Class] {
        var classes: [Class] = []

        // Split by class card divs (feed_time_slot) - same regex as legacy
        let cardPattern = #"id=\"feed_time_slot\d+\"[^>]*>[\s\S]*?(?=id=\"feed_time_slot|$)"#
        guard let cardRegex = try? NSRegularExpression(pattern: cardPattern, options: []) else {
            return classes
        }

        let range = NSRange(html.startIndex..., in: html)
        let cardMatches = cardRegex.matches(in: html, options: [], range: range)

        for cardMatch in cardMatches {
            guard let cardRange = Range(cardMatch.range, in: html) else { continue }
            let cardHtml = String(html[cardRange])

            // Extract class ID from popup onclick: valor3=84998
            guard let classId = extractParam(from: cardHtml, param: "valor3") else {
                continue
            }

            // Extract class name - must have align="left" and uppercase pattern (allow numbers for names like "SALT 1")
            let namePattern = #"col-50[^>]*align=\"left\"[^>]*>[\s\S]*?([A-Z][A-Z0-9\s]+[A-Z0-9])\s*<"#
            let name: String
            if let nameRegex = try? NSRegularExpression(pattern: namePattern, options: []),
               let nameMatch = nameRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
               nameMatch.numberOfRanges >= 2,
               let nameRange = Range(nameMatch.range(at: 1), in: cardHtml) {
                name = String(cardHtml[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                continue
            }

            // Extract location (right aligned col-50 after &nbsp;)
            let locationPattern = #"col-50[^>]*align=\"right\"[^>]*>[\s\S]*?&nbsp;([^<]+)<"#
            var location = ""
            if let locRegex = try? NSRegularExpression(pattern: locationPattern, options: []),
               let locMatch = locRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
               locMatch.numberOfRanges >= 2,
               let locRange = Range(locMatch.range(at: 1), in: cardHtml) {
                location = String(cardHtml[locRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Extract time: "06:00 - 07:00"
            var startTime = ""
            var endTime = ""
            let timePattern = #"(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})"#
            if let timeRegex = try? NSRegularExpression(pattern: timePattern),
               let timeMatch = timeRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
               timeMatch.numberOfRanges >= 3,
               let startRange = Range(timeMatch.range(at: 1), in: cardHtml),
               let endRange = Range(timeMatch.range(at: 2), in: cardHtml) {
                startTime = String(cardHtml[startRange])
                endTime = String(cardHtml[endRange])
            }

            // Extract capacity: "2 de 14"
            var enrolled = 0
            var capacity = 0
            let capacityPattern = #"(\d+)\s+de\s+(\d+)"#
            if let capRegex = try? NSRegularExpression(pattern: capacityPattern),
               let capMatch = capRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
               capMatch.numberOfRanges >= 3,
               let enrolledRange = Range(capMatch.range(at: 1), in: cardHtml),
               let capRange = Range(capMatch.range(at: 2), in: cardHtml) {
                enrolled = Int(cardHtml[enrolledRange]) ?? 0
                capacity = Int(cardHtml[capRange]) ?? 0
            }

            // Determine status
            let status: ClassStatus
            if cardHtml.contains("Concluído") || cardHtml.contains("Concluido") {
                status = .completed
            } else if cardHtml.contains("decorrer") {
                status = .inProgress
            } else {
                status = .available
            }

            // Extract booking URL from onclick: confirma_marca_aula('...','URL')
            var bookingURL: String?
            let bookingPattern = #"confirma_marca_aula\('[^']*','([^']+)'\)"#
            if let bookingRegex = try? NSRegularExpression(pattern: bookingPattern, options: []),
               let bookingMatch = bookingRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
               bookingMatch.numberOfRanges >= 2,
               let urlRange = Range(bookingMatch.range(at: 1), in: cardHtml) {
                bookingURL = String(cardHtml[urlRange])
            }

            // Extract cancel URL from onclick: confirma('...','URL')
            // This is the pattern for canceling regular class registrations
            var cancelURL: String?
            let cancelPattern = #"confirma\('[^']*','([^']+cancela_aula[^']+)'\)"#
            if let cancelRegex = try? NSRegularExpression(pattern: cancelPattern, options: []),
               let cancelMatch = cancelRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
               cancelMatch.numberOfRanges >= 2,
               let urlRange = Range(cancelMatch.range(at: 1), in: cardHtml) {
                cancelURL = String(cardHtml[urlRange])
            }

            // Determine booking state
            let canBook = bookingURL != nil
            let isRegistered = cancelURL != nil || cardHtml.contains("CANCELAR")

            let classItem = Class(
                id: classId,
                name: name,
                location: location,
                startTime: startTime,
                endTime: endTime,
                enrolled: enrolled,
                capacity: capacity,
                status: status,
                date: date,
                bookingURL: bookingURL,
                cancelURL: cancelURL,
                canBook: canBook,
                isRegistered: isRegistered
            )
            classes.append(classItem)
        }

        return classes
    }

    // MARK: - Class Details Parsing

    /// Parses class details HTML from detalhes_aula.php
    /// - Parameters:
    ///   - html: HTML string from detalhes_aula.php
    ///   - classInfo: Basic class info to include in result
    /// - Returns: ClassDetails with instructors, workout, and participants
    static func parseClassDetails(html: String, classInfo: Class) -> ClassDetails {
        let instructors = parseInstructors(from: html)
        let workout = parseWorkout(from: html)
        let participants = parseParticipants(from: html)

        return ClassDetails(
            classInfo: classInfo,
            instructors: instructors,
            workout: workout,
            participants: participants
        )
    }

    /// Extract instructors from the details HTML
    private static func parseInstructors(from html: String) -> [Instructor] {
        var instructors: [Instructor] = []

        guard let doc = try? SwiftSoup.parse(html) else {
            return instructors
        }

        do {
            // Find the feed_coachs section
            guard let coachsSection = try doc.select("#feed_coachs").first() else {
                return instructors
            }

            // Find all images (coach photos)
            let images = try coachsSection.select("img")

            for img in images {
                let photoPath = try img.attr("src")

                // Find the name - it's in a div with text-transform: uppercase nearby
                var name = ""
                if let parent = img.parent() {
                    // Look for sibling or nearby div with uppercase style
                    let divs = try parent.select("div")
                    for div in divs {
                        let style = try div.attr("style")
                        if style.contains("uppercase") {
                            name = try div.text().trimmingCharacters(in: .whitespacesAndNewlines)
                            break
                        }
                    }
                }

                guard !name.isEmpty else { continue }

                // Build full photo URL
                var photoURL: URL?
                if photoPath.hasPrefix("../") {
                    let cleanPath = photoPath.replacingOccurrences(of: "../", with: "")
                    photoURL = URL(string: "https://www.regibox.pt/\(cleanPath)")
                } else if !photoPath.isEmpty {
                    photoURL = URL(string: "https://www.regibox.pt\(photoPath)")
                }

                instructors.append(Instructor(name: name, photoURL: photoURL))
            }
        } catch {
            // Return whatever we have
        }

        return instructors
    }

    /// Clean HTML content from workout sections (replace br tags and entities)
    private static func cleanWorkoutContent(_ raw: String) -> String {
        raw.replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extract workout sections from the details HTML
    private static func parseWorkout(from html: String) -> Workout? {
        var warmUp: String?
        var skill: String?
        var strength: String?
        var condition: String?
        var matchedNames = Set<String>()

        // Pass 1: Match the 4 known sections (including typo variants)
        let sections: [(names: [String], setter: (String) -> Void)] = [
            (["Warm-Up", "Warm Up"], { warmUp = $0 }),
            (["Skill"], { skill = $0 }),
            (["Strength", "Strentgth"], { strength = $0 }),
            (["Condition", "CondiTion"], { condition = $0 }),
        ]

        for (sectionNames, setter) in sections {
            for sectionName in sectionNames {
                let pattern = #"<strong>\s*"# + NSRegularExpression.escapedPattern(for: sectionName) + #"\s*</strong>[\s\S]*?<div[^>]*>([^<]*(?:<br\s*/?>[\s\S]*?)*)</div>"#

                if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
                   let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
                   match.numberOfRanges >= 2,
                   let contentRange = Range(match.range(at: 1), in: html) {

                    let content = cleanWorkoutContent(String(html[contentRange]))
                    if !content.isEmpty {
                        setter(content)
                        matchedNames.insert(sectionName.lowercased())
                        break
                    }
                }
            }
        }

        // Pass 2: Generic sweep for any <strong>Name</strong>...<div>Content</div> not already captured
        var additionalSections: [WorkoutSection] = []
        let genericPattern = #"<strong>\s*([^<]+?)\s*</strong>[\s\S]*?<div[^>]*>([^<]*(?:<br\s*/?>[\s\S]*?)*)</div>"#
        if let genericRegex = try? NSRegularExpression(pattern: genericPattern, options: []) {
            let range = NSRange(html.startIndex..., in: html)
            let matches = genericRegex.matches(in: html, options: [], range: range)

            for match in matches {
                guard match.numberOfRanges >= 3,
                      let nameRange = Range(match.range(at: 1), in: html),
                      let contentRange = Range(match.range(at: 2), in: html) else {
                    continue
                }

                let name = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }

                // Skip if already matched in pass 1
                if matchedNames.contains(name.lowercased()) { continue }

                let content = cleanWorkoutContent(String(html[contentRange]))
                guard !content.isEmpty else { continue }

                // Avoid duplicates in additional sections
                if !additionalSections.contains(where: { $0.name.lowercased() == name.lowercased() }) {
                    additionalSections.append(WorkoutSection(name: name, content: content))
                }
            }
        }

        let workout = Workout(warmUp: warmUp, skill: skill, strength: strength, condition: condition, additionalSections: additionalSections)
        return workout.isEmpty ? nil : workout
    }

    /// Extract enrolled participants from the details HTML
    private static func parseParticipants(from html: String) -> [Participant] {
        var participants: [Participant] = []

        // Pattern: position number in letra_10 div, then name in item-title
        let pattern = #"<div[^>]*class=\"letra_10\"[^>]*>(\d+)</div>[\s\S]*?<div[^>]*class=\"item-title\"[^>]*>[\s\S]*?([A-Za-zÀ-ÿ\s]+?)[\s\S]*?</div>"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return participants
        }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            guard match.numberOfRanges >= 3,
                  let posRange = Range(match.range(at: 1), in: html),
                  let nameRange = Range(match.range(at: 2), in: html) else {
                continue
            }

            let position = Int(html[posRange]) ?? 0
            let name = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)

            guard !name.isEmpty else { continue }

            participants.append(Participant(name: name, position: position, photoURL: nil))
        }

        return participants
    }

    // MARK: - Drop-In Parsing

    /// Parse drop-in boxes list with GPS coordinates from dropin_find_box.php
    /// - Parameter html: HTML response from dropin_find_box.php
    /// - Returns: Array of DropInBox objects
    static func parseDropInBoxes(html: String) -> [DropInBox] {
        var boxes: [DropInBox] = []

        // Use the same pattern as legacy to match list items
        let itemPattern = #"<a[^>]*onclick="[^"]*(?:&amp;)?valor1=(\d+)[^"]*"[^>]*>[\s\S]*?</a>[\s\S]*?</li>"#
        guard let itemRegex = try? NSRegularExpression(pattern: itemPattern, options: [.caseInsensitive]) else {
            return boxes
        }

        let acsPattern = #"acs=([a-f0-9]+)"#
        let acsRegex = try? NSRegularExpression(pattern: acsPattern, options: [])

        let range = NSRange(html.startIndex..., in: html)
        let matches = itemRegex.matches(in: html, options: [], range: range)

        for match in matches {
            guard match.numberOfRanges >= 2,
                  let idRange = Range(match.range(at: 1), in: html),
                  let fullRange = Range(match.range, in: html) else {
                continue
            }

            let boxId = String(html[idRange])
            let itemHtml = String(html[fullRange])

            // Extract box name from item-title div (text directly inside, before child divs)
            let namePattern = #"class=[\"']item-title[\"'][^>]*>\s*([^<]+?)\s*<"#
            var name = ""
            if let nameRegex = try? NSRegularExpression(pattern: namePattern, options: []),
               let nameMatch = nameRegex.firstMatch(in: itemHtml, options: [], range: NSRange(itemHtml.startIndex..., in: itemHtml)),
               nameMatch.numberOfRanges >= 2,
               let nameRange = Range(nameMatch.range(at: 1), in: itemHtml) {
                name = String(itemHtml[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            guard !name.isEmpty else { continue }

            // Extract address from item-header div (before <br>)
            let addressPattern = #"class=[\"']item-header[\"'][^>]*>([^<]+)<br"#
            var address: String?
            if let addrRegex = try? NSRegularExpression(pattern: addressPattern, options: []),
               let addrMatch = addrRegex.firstMatch(in: itemHtml, options: [], range: NSRange(itemHtml.startIndex..., in: itemHtml)),
               addrMatch.numberOfRanges >= 2,
               let addrRange = Range(addrMatch.range(at: 1), in: itemHtml) {
                let addr = String(itemHtml[addrRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !addr.isEmpty {
                    address = addr
                }
            }

            // Extract GPS coordinates from item-header (after <br>)
            let coordPattern = #"<br>[\s\S]*?(-?\d+\.\d+)\s*(?:&nbsp;)?\s*(-?\d+\.\d+)"#
            var latitude: Double?
            var longitude: Double?
            if let coordRegex = try? NSRegularExpression(pattern: coordPattern, options: []),
               let coordMatch = coordRegex.firstMatch(in: itemHtml, options: [], range: NSRange(itemHtml.startIndex..., in: itemHtml)),
               coordMatch.numberOfRanges >= 3,
               let latRange = Range(coordMatch.range(at: 1), in: itemHtml),
               let lngRange = Range(coordMatch.range(at: 2), in: itemHtml) {
                latitude = Double(itemHtml[latRange])
                longitude = Double(itemHtml[lngRange])
            }

            // Extract per-box ACS token from onclick handler
            var acsToken: String?
            if let acsRegex = acsRegex,
               let acsMatch = acsRegex.firstMatch(in: itemHtml, options: [], range: NSRange(itemHtml.startIndex..., in: itemHtml)),
               acsMatch.numberOfRanges >= 2,
               let acsRange = Range(acsMatch.range(at: 1), in: itemHtml) {
                acsToken = String(itemHtml[acsRange])
            }

            boxes.append(DropInBox(
                id: boxId,
                name: name,
                address: address,
                latitude: latitude,
                longitude: longitude,
                acsToken: acsToken
            ))
        }

        return boxes
    }

    /// Parse drop-in box details (rules, schedule, class types) from dropin_regras.php
    /// - Parameters:
    ///   - html: HTML response from dropin_regras.php
    ///   - boxId: The box ID for reference
    /// - Returns: DropInBoxDetails if parsing succeeds
    static func parseDropInBoxDetails(html: String, boxId: String) -> DropInBoxDetails? {
        guard let doc = try? SwiftSoup.parse(html) else {
            return nil
        }

        var boxName = ""

        do {
            // Extract box name from page-title or h1
            if let pageTitle = try doc.select(".page-title").first() {
                boxName = try pageTitle.text().trimmingCharacters(in: .whitespacesAndNewlines)
            }

            if boxName.isEmpty {
                if let h1 = try doc.select("h1").first() {
                    boxName = try h1.text().trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        } catch {
            // Continue with empty name
        }

        let box = DropInBox(id: boxId, name: boxName.isEmpty ? "Unknown Box" : boxName)
        let rules = parseDropInRules(from: html)
        let schedule = parseDropInSchedule(from: html)
        let classTypes = parseDropInClassTypes(from: html)
        let socialLinks = parseDropInSocialLinks(from: html)

        return DropInBoxDetails(
            box: box,
            rules: rules,
            availableClassTypes: classTypes,
            schedule: schedule,
            socialLinks: socialLinks
        )
    }

    /// Parse drop-in rules from the box details page
    private static func parseDropInRules(from html: String) -> DropInRules {
        var registrationAdvanceDays = 0
        var registrationAdvanceMinutes = 0
        var registrationCutoffMinutes = 0
        var cancellationCutoffMinutes = 0
        var maxAllowedAbsences = 0
        var price = ""

        // Registration advance: "2 dias" or "0 dias e 0 minutos"
        let advancePattern = #"(?:inscrever|antecedência)[^<]*?(\d+)\s*dias?(?:\s*e\s*(\d+)\s*minutos?)?"#
        if let regex = try? NSRegularExpression(pattern: advancePattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let daysRange = Range(match.range(at: 1), in: html) {
            registrationAdvanceDays = Int(html[daysRange]) ?? 0
            if match.numberOfRanges >= 3, let minsRange = Range(match.range(at: 2), in: html) {
                registrationAdvanceMinutes = Int(html[minsRange]) ?? 0
            }
        }

        // Registration cutoff
        let regCutoffPattern = #"(?:até|limite)[^<]*?(\d+)\s*minutos?\s*(?:antes|início)"#
        if let regex = try? NSRegularExpression(pattern: regCutoffPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let minsRange = Range(match.range(at: 1), in: html) {
            registrationCutoffMinutes = Int(html[minsRange]) ?? 0
        }

        // Cancellation cutoff
        let cancelPattern = #"(?:cancelar|desmarca)[^<]*?(\d+)\s*minutos?"#
        if let regex = try? NSRegularExpression(pattern: cancelPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let minsRange = Range(match.range(at: 1), in: html) {
            cancellationCutoffMinutes = Int(html[minsRange]) ?? 0
        }

        // Max absences
        let absencePattern = #"(\d+)\s*(?:faltas?|ausências?)"#
        if let regex = try? NSRegularExpression(pattern: absencePattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let numRange = Range(match.range(at: 1), in: html) {
            maxAllowedAbsences = Int(html[numRange]) ?? 0
        }

        // Price: €12,00 format
        let pricePattern = #"€\s*(\d+[,.]?\d*)"#
        if let regex = try? NSRegularExpression(pattern: pricePattern),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let priceRange = Range(match.range, in: html) {
            price = String(html[priceRange]).trimmingCharacters(in: .whitespaces)
        }

        return DropInRules(
            registrationAdvanceDays: registrationAdvanceDays,
            registrationAdvanceMinutes: registrationAdvanceMinutes,
            registrationCutoffMinutes: registrationCutoffMinutes,
            cancellationCutoffMinutes: cancellationCutoffMinutes,
            maxAllowedAbsences: maxAllowedAbsences,
            price: price
        )
    }

    /// Parse schedule from the box details page
    private static func parseDropInSchedule(from html: String) -> [DaySchedule] {
        var schedule: [DaySchedule] = []

        let days = ["Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado", "Domingo"]

        for day in days {
            let dayPattern = NSRegularExpression.escapedPattern(for: day) + #"[\s\S]*?(?:(\d{2}:\d{2}\s*-\s*\d{2}:\d{2})|(Encerrado|Fechado))"#
            if let regex = try? NSRegularExpression(pattern: dayPattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)) {

                var hours = "Encerrado"
                if match.numberOfRanges >= 2, let hoursRange = Range(match.range(at: 1), in: html) {
                    hours = String(html[hoursRange]).trimmingCharacters(in: .whitespaces)
                } else if match.numberOfRanges >= 3, let closedRange = Range(match.range(at: 2), in: html) {
                    hours = String(html[closedRange])
                }

                schedule.append(DaySchedule(dayName: day, hours: hours))
            }
        }

        return schedule
    }

    /// Parse available class types from the box details page
    private static func parseDropInClassTypes(from html: String) -> [String] {
        var classTypes: [String] = []

        let commonTypes = ["WOD", "OPENBOX", "Open Box", "PILATES", "YOGA", "MOBILITY", "GYMNASTICS", "WEIGHTLIFTING", "ENDURANCE", "HIIT"]

        for classType in commonTypes {
            if html.range(of: classType, options: .caseInsensitive) != nil {
                let normalized = classType.uppercased()
                if !classTypes.contains(normalized) {
                    classTypes.append(normalized)
                }
            }
        }

        return classTypes
    }

    /// Parse social media links from the box details page
    private static func parseDropInSocialLinks(from html: String) -> SocialLinks? {
        var website: URL?
        var facebook: URL?
        var instagram: URL?

        guard let doc = try? SwiftSoup.parse(html) else {
            return nil
        }

        do {
            let links = try doc.select("a[href]")

            for link in links {
                let href = try link.attr("href")

                if href.contains("facebook") {
                    facebook = URL(string: href)
                } else if href.contains("instagram") {
                    instagram = URL(string: href)
                } else if href.hasPrefix("http") && !href.contains("regibox.pt") && website == nil {
                    website = URL(string: href)
                }
            }
        } catch {
            // Return whatever we have
        }

        if website == nil && facebook == nil && instagram == nil {
            return nil
        }

        return SocialLinks(website: website, facebook: facebook, instagram: instagram)
    }

    // MARK: - Check-In QR Code Parsing

    /// Extracts the QR code parameter from check_in.php HTML
    /// - Parameter html: HTML response from check_in.php containing an img tag with qr_code_gen.php
    /// - Returns: The `code` parameter value, or nil if not found
    static func parseCheckInQRCode(html: String) -> String? {
        let pattern = #"qr_code_gen\.php\?code=([^"&\s]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              match.numberOfRanges >= 2,
              let codeRange = Range(match.range(at: 1), in: html) else {
            return nil
        }
        return String(html[codeRange])
    }

    // MARK: - My Drop-Ins Parsing (Main Page)

    /// Parse the "OS MEUS DROP-INS" section from the main page HTML
    /// - Parameter html: HTML string from the main app page (index)
    /// - Returns: Array of MyDropIn objects representing registered drop-in classes
    static func parseMyDropIns(html: String) -> [MyDropIn] {
        var dropIns: [MyDropIn] = []

        // Find the "OS MEUS DROP-INS" section
        guard let sectionStart = html.range(of: "OS MEUS DROP-INS") else {
            return dropIns
        }

        // Find the closing </ul> after the section header
        let afterSection = String(html[sectionStart.upperBound...])
        guard let ulEnd = afterSection.range(of: "</ul>") else {
            return dropIns
        }

        let sectionHtml = String(afterSection[..<ulEnd.upperBound])

        // Split by <li> items (each represents a drop-in registration)
        let itemPattern = #"<li\s+id="feed_minha_aula\d+"[\s\S]*?</li>"#
        guard let itemRegex = try? NSRegularExpression(pattern: itemPattern, options: []) else {
            return dropIns
        }

        let range = NSRange(sectionHtml.startIndex..., in: sectionHtml)
        let matches = itemRegex.matches(in: sectionHtml, options: [], range: range)

        for match in matches {
            guard let matchRange = Range(match.range, in: sectionHtml) else { continue }
            let itemHtml = String(sectionHtml[matchRange])

            // Extract class ID: id_aula=24002
            guard let classId = extractParam(from: itemHtml, param: "id_aula") else { continue }

            // Extract box ID: id_box_dropin=58
            guard let boxId = extractParam(from: itemHtml, param: "id_box_dropin") else { continue }

            // Extract date and time from item-header: "16 FEV &nbsp; 06:30 -> 07:30"
            let headerPattern = #"item-header[^>]*>([^<]+)<"#
            var dateText = ""
            var startTime = ""
            var endTime = ""
            if let headerRegex = try? NSRegularExpression(pattern: headerPattern),
               let headerMatch = headerRegex.firstMatch(in: itemHtml, range: NSRange(itemHtml.startIndex..., in: itemHtml)),
               headerMatch.numberOfRanges >= 2,
               let headerRange = Range(headerMatch.range(at: 1), in: itemHtml) {
                let headerText = String(itemHtml[headerRange])
                    .replacingOccurrences(of: "&nbsp;", with: " ")
                    .replacingOccurrences(of: "\u{00A0}", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Parse: "16 FEV   06:30 -> 07:30"
                let timePattern = #"(\d{2}:\d{2})\s*-[>]?\s*(\d{2}:\d{2})"#
                if let timeRegex = try? NSRegularExpression(pattern: timePattern),
                   let timeMatch = timeRegex.firstMatch(in: headerText, range: NSRange(headerText.startIndex..., in: headerText)),
                   timeMatch.numberOfRanges >= 3,
                   let startRange = Range(timeMatch.range(at: 1), in: headerText),
                   let endRange = Range(timeMatch.range(at: 2), in: headerText) {
                    startTime = String(headerText[startRange])
                    endTime = String(headerText[endRange])
                }

                // Date is everything before the first time
                let datePattern = #"^(.+?)\s+\d{2}:\d{2}"#
                if let dateRegex = try? NSRegularExpression(pattern: datePattern),
                   let dateMatch = dateRegex.firstMatch(in: headerText, range: NSRange(headerText.startIndex..., in: headerText)),
                   dateMatch.numberOfRanges >= 2,
                   let dateRange = Range(dateMatch.range(at: 1), in: headerText) {
                    dateText = String(headerText[dateRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            // Extract box name: text node in item-title (after item-header div, before item-footer div)
            var boxName = ""
            let namePattern = #"item-header[^>]*>[^<]*</div>\s*\n?\s*([A-Z][A-Z0-9\s&;.\-]+?)\s*<div"#
            if let nameRegex = try? NSRegularExpression(pattern: namePattern, options: [.dotMatchesLineSeparators]),
               let nameMatch = nameRegex.firstMatch(in: itemHtml, range: NSRange(itemHtml.startIndex..., in: itemHtml)),
               nameMatch.numberOfRanges >= 2,
               let nameRange = Range(nameMatch.range(at: 1), in: itemHtml) {
                boxName = String(itemHtml[nameRange])
                    .replacingOccurrences(of: "&nbsp;", with: " ")
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }

            guard !boxName.isEmpty else { continue }

            // Extract Google Maps URL
            var mapsURL: String?
            let mapsPattern = #"href="(https?://maps\.google\.com/[^"]+)""#
            if let mapsRegex = try? NSRegularExpression(pattern: mapsPattern),
               let mapsMatch = mapsRegex.firstMatch(in: itemHtml, range: NSRange(itemHtml.startIndex..., in: itemHtml)),
               mapsMatch.numberOfRanges >= 2,
               let mapsRange = Range(mapsMatch.range(at: 1), in: itemHtml) {
                mapsURL = String(itemHtml[mapsRange])
            }

            // Extract logo URL
            var logoURL: String?
            let logoPattern = #"item-media[^>]*>\s*<img\s+src="([^"]+)""#
            if let logoRegex = try? NSRegularExpression(pattern: logoPattern),
               let logoMatch = logoRegex.firstMatch(in: itemHtml, range: NSRange(itemHtml.startIndex..., in: itemHtml)),
               logoMatch.numberOfRanges >= 2,
               let logoRange = Range(logoMatch.range(at: 1), in: itemHtml) {
                logoURL = String(itemHtml[logoRange])
            }

            dropIns.append(MyDropIn(
                classId: classId,
                boxId: boxId,
                boxName: boxName,
                dateText: dateText,
                startTime: startTime,
                endTime: endTime,
                mapsURL: mapsURL,
                logoURL: logoURL
            ))
        }

        return dropIns
    }

    // MARK: - Class History Parsing

    /// Parse the class history summary page (stats + monthly chart data)
    /// - Parameter html: HTML response from historico_aulas.php
    /// - Returns: ClassHistorySummary if parsing succeeds
    static func parseClassHistorySummary(html: String) -> ClassHistorySummary? {
        // Extract stats: the three big numbers in font-size:50px divs
        // They appear in order: Inscrições, Presenças, Faltas
        let statPattern = #"font-size:\s*50px[^>]*>\s*(\d+)\s*<"#
        guard let statRegex = try? NSRegularExpression(pattern: statPattern, options: []) else {
            return nil
        }

        let range = NSRange(html.startIndex..., in: html)
        let statMatches = statRegex.matches(in: html, options: [], range: range)

        var registrations = 0
        var attendances = 0
        var absences = 0

        if statMatches.count >= 1, let r = Range(statMatches[0].range(at: 1), in: html) {
            registrations = Int(html[r]) ?? 0
        }
        if statMatches.count >= 2, let r = Range(statMatches[1].range(at: 1), in: html) {
            attendances = Int(html[r]) ?? 0
        }
        if statMatches.count >= 3, let r = Range(statMatches[2].range(at: 1), in: html) {
            absences = Int(html[r]) ?? 0
        }

        // Extract monthly chart data from iframe src: datas='Mar','Abr',...&valores=6,11,...
        var monthlyData: [MonthlyAttendance] = []

        let datasPattern = #"datas=([^&]+)"#
        let valoresPattern = #"valores=([^&\"]+)"#

        if let datasRegex = try? NSRegularExpression(pattern: datasPattern),
           let valoresRegex = try? NSRegularExpression(pattern: valoresPattern),
           let datasMatch = datasRegex.firstMatch(in: html, range: range),
           let valoresMatch = valoresRegex.firstMatch(in: html, range: range),
           datasMatch.numberOfRanges >= 2,
           valoresMatch.numberOfRanges >= 2,
           let datasRange = Range(datasMatch.range(at: 1), in: html),
           let valoresRange = Range(valoresMatch.range(at: 1), in: html) {

            let datasStr = String(html[datasRange])
            let valoresStr = String(html[valoresRange])

            // Parse months: 'Mar','Abr','Mai' -> ["Mar", "Abr", "Mai"]
            let monthPattern = #"'([^']+)'"#
            var months: [String] = []
            if let monthRegex = try? NSRegularExpression(pattern: monthPattern) {
                let monthMatches = monthRegex.matches(in: datasStr, range: NSRange(datasStr.startIndex..., in: datasStr))
                for m in monthMatches {
                    if let r = Range(m.range(at: 1), in: datasStr) {
                        months.append(String(datasStr[r]))
                    }
                }
            }

            // Parse values: 6,11,14 -> [6, 11, 14]
            let values = valoresStr.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

            for (month, count) in zip(months, values) {
                monthlyData.append(MonthlyAttendance(month: month, count: count))
            }
        }

        return ClassHistorySummary(
            registrations: registrations,
            attendances: attendances,
            absences: absences,
            monthlyData: monthlyData
        )
    }

    /// Parse the class history results page (detailed list of entries)
    /// - Parameter html: HTML response from historico_aulas_resultados.php
    /// - Returns: Tuple of entries array and total count from header
    static func parseClassHistoryResults(html: String) -> (entries: [ClassHistoryEntry], totalCount: Int) {
        var entries: [ClassHistoryEntry] = []
        var totalCount = 0

        // Extract total count from header: "HISTÓRICO DE AULAS (12)"
        let countPattern = #"HIST[ÓO]RICO DE AULAS\s*\((\d+)\)"#
        if let countRegex = try? NSRegularExpression(pattern: countPattern, options: [.caseInsensitive]),
           let countMatch = countRegex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           countMatch.numberOfRanges >= 2,
           let countRange = Range(countMatch.range(at: 1), in: html) {
            totalCount = Int(html[countRange]) ?? 0
        }

        // Parse each <li> entry
        // Structure: <li> containing item-title with "17 Fev 2026 &nbsp; CROSS TRAINING"
        // and letra_small with status text like "Presente"
        let entryPattern = #"<li[^>]*>[\s\S]*?item-title[^>]*>[\s\S]*?</li>"#
        guard let entryRegex = try? NSRegularExpression(pattern: entryPattern, options: []) else {
            return (entries, totalCount)
        }

        let range = NSRange(html.startIndex..., in: html)
        let entryMatches = entryRegex.matches(in: html, options: [], range: range)

        for entryMatch in entryMatches {
            guard let entryRange = Range(entryMatch.range, in: html) else { continue }
            let entryHtml = String(html[entryRange])

            // Extract date and class name from item-title
            // Format: "17 Fev 2026 &nbsp; CROSS TRAINING" or with multiple &nbsp;
            let titlePattern = #"item-title[^>]*>\s*(.*?)\s*</div>"#
            guard let titleRegex = try? NSRegularExpression(pattern: titlePattern, options: [.dotMatchesLineSeparators]),
                  let titleMatch = titleRegex.firstMatch(in: entryHtml, range: NSRange(entryHtml.startIndex..., in: entryHtml)),
                  titleMatch.numberOfRanges >= 2,
                  let titleRange = Range(titleMatch.range(at: 1), in: entryHtml) else {
                continue
            }

            let titleText = String(entryHtml[titleRange])
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "\u{00A0}", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Split by multiple spaces to separate date from class name
            // "17 Fev 2026   CROSS TRAINING"
            let parts = titleText.components(separatedBy: "  ")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            guard parts.count >= 2 else { continue }

            let date = parts[0]
            let className = parts.dropFirst().joined(separator: " ")

            // Extract status from letra_small div
            let statusPattern = #"letra_small[^>]*>\s*(.*?)\s*</div>"#
            var status = AttendanceStatus.noRecord
            if let statusRegex = try? NSRegularExpression(pattern: statusPattern, options: [.dotMatchesLineSeparators]),
               let statusMatch = statusRegex.firstMatch(in: entryHtml, range: NSRange(entryHtml.startIndex..., in: entryHtml)),
               statusMatch.numberOfRanges >= 2,
               let statusRange = Range(statusMatch.range(at: 1), in: entryHtml) {
                let statusText = String(entryHtml[statusRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                status = AttendanceStatus(fromText: statusText)
            }

            entries.append(ClassHistoryEntry(date: date, className: className, status: status))
        }

        return (entries, totalCount)
    }

    // MARK: - Drop-In History Parsing

    /// Parse the drop-in history from dropin.php
    /// - Parameter html: HTML response from dropin.php
    /// - Returns: DropInHistorySummary if parsing succeeds
    static func parseDropInHistory(html: String) -> DropInHistorySummary? {
        // Extract summary stats using the same font-size:50px pattern as class history
        // They appear in order: Inscrições, Presenças, Faltas
        let statPattern = #"font-size:\s*50px[^>]*>\s*(\d+)\s*<"#
        guard let statRegex = try? NSRegularExpression(pattern: statPattern, options: []) else {
            return nil
        }

        let range = NSRange(html.startIndex..., in: html)
        let statMatches = statRegex.matches(in: html, options: [], range: range)

        var registrations = 0
        var attendances = 0
        var absences = 0

        if statMatches.count >= 1, let r = Range(statMatches[0].range(at: 1), in: html) {
            registrations = Int(html[r]) ?? 0
        }
        if statMatches.count >= 2, let r = Range(statMatches[1].range(at: 1), in: html) {
            attendances = Int(html[r]) ?? 0
        }
        if statMatches.count >= 3, let r = Range(statMatches[2].range(at: 1), in: html) {
            absences = Int(html[r]) ?? 0
        }

        // Parse individual entries using SwiftSoup
        var entries: [DropInHistoryEntry] = []

        if let doc = try? SwiftSoup.parse(html) {
            do {
                let items = try doc.select("li.item-content")

                for item in items {
                    // Extract box ID from logo img src: escolas/{boxId}/logotipo.jpg
                    let imgSrc = try item.select("img").attr("src")
                    let boxIdPattern = #"escolas/(\d+)/"#
                    var boxId = ""
                    if let boxIdRegex = try? NSRegularExpression(pattern: boxIdPattern),
                       let boxIdMatch = boxIdRegex.firstMatch(in: imgSrc, range: NSRange(imgSrc.startIndex..., in: imgSrc)),
                       boxIdMatch.numberOfRanges >= 2,
                       let boxIdRange = Range(boxIdMatch.range(at: 1), in: imgSrc) {
                        boxId = String(imgSrc[boxIdRange])
                    }

                    guard !boxId.isEmpty else { continue }

                    // Get item-header divs inside item-title
                    let headers = try item.select(".item-title .item-header")
                    guard headers.size() >= 2 else { continue }

                    // First header: date and time "2026-01-23  18:20 --> 19:20"
                    let dateTimeText = try headers.get(0).text()
                        .replacingOccurrences(of: "\u{00A0}", with: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    let dtPattern = #"(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s*-->\s*(\d{2}:\d{2})"#
                    var date = ""
                    var startTime = ""
                    var endTime = ""
                    if let dtRegex = try? NSRegularExpression(pattern: dtPattern),
                       let dtMatch = dtRegex.firstMatch(in: dateTimeText, range: NSRange(dateTimeText.startIndex..., in: dateTimeText)),
                       dtMatch.numberOfRanges >= 4,
                       let dateRange = Range(dtMatch.range(at: 1), in: dateTimeText),
                       let startRange = Range(dtMatch.range(at: 2), in: dateTimeText),
                       let endRange = Range(dtMatch.range(at: 3), in: dateTimeText) {
                        date = String(dateTimeText[dateRange])
                        startTime = String(dateTimeText[startRange])
                        endTime = String(dateTimeText[endRange])
                    }

                    guard !date.isEmpty else { continue }

                    // Second header: class name
                    let className = try headers.get(1).text().trimmingCharacters(in: .whitespacesAndNewlines)

                    // Box abbreviation: text node directly in item-title between the two headers
                    let titleElement = try item.select(".item-title").first()
                    var boxAbbreviation = ""
                    if let titleEl = titleElement {
                        // Get all text nodes in item-title
                        for node in titleEl.getChildNodes() {
                            if let textNode = node as? TextNode {
                                let text = textNode.getWholeText().trimmingCharacters(in: .whitespacesAndNewlines)
                                if !text.isEmpty {
                                    boxAbbreviation = text
                                    break
                                }
                            }
                        }
                    }

                    // Check if present (thumb_up icon in item-after)
                    let afterHtml = try item.select(".item-after").outerHtml()
                    let isPresent = afterHtml.contains("thumb_up")

                    entries.append(DropInHistoryEntry(
                        date: date,
                        startTime: startTime,
                        endTime: endTime,
                        boxId: boxId,
                        boxAbbreviation: boxAbbreviation,
                        className: className,
                        isPresent: isPresent
                    ))
                }
            } catch {
                // Return whatever we have
            }
        }

        return DropInHistorySummary(
            registrations: registrations,
            attendances: attendances,
            absences: absences,
            entries: entries
        )
    }

    /// Parse drop-in classes list from aulas_dropin.php
    /// - Parameters:
    ///   - html: HTML response from aulas_dropin.php
    ///   - date: Date string in YYYY-MM-DD format
    ///   - boxId: The box ID for reference
    /// - Returns: Array of DropInClass objects
    static func parseDropInClasses(html: String, date: String, boxId: String) -> [DropInClass] {
        var classes: [DropInClass] = []

        guard let doc = try? SwiftSoup.parse(html) else {
            return classes
        }

        do {
            // Drop-in classes use <div class="card"> containers (not feed_time_slot)
            let cards = try doc.select("div.card")

            for card in cards {
                let cardHtml = try card.outerHtml()

                // Extract class ID from id_aula= in onclick handlers
                guard let id = extractParam(from: cardHtml, param: "id_aula") else {
                    continue
                }

                // Extract class name from col-50 align=left (text after the colored circle div)
                var name = ""
                let leftCols = try card.select("div.col-50")
                for col in leftCols {
                    let align = try col.attr("align")
                    if align == "left" {
                        // Get text content, stripping the circle div's non-breaking spaces
                        let text = try col.text()
                            .replacingOccurrences(of: "\u{00A0}", with: " ")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        if !text.isEmpty {
                            name = text
                            break
                        }
                    }
                }

                guard !name.isEmpty else { continue }

                // Extract time from the col with time text (format "HH:MM -> HH:MM")
                var startTime = ""
                var endTime = ""
                let cardText = try card.text()
                // Match both -> and - separators (SwiftSoup may encode > as &gt; in outerHtml)
                let timePattern = #"(\d{2}:\d{2})\s*-[>]?\s*(\d{2}:\d{2})"#
                if let regex = try? NSRegularExpression(pattern: timePattern),
                   let match = regex.firstMatch(in: cardText, range: NSRange(cardText.startIndex..., in: cardText)),
                   match.numberOfRanges >= 3,
                   let startRange = Range(match.range(at: 1), in: cardText),
                   let endRange = Range(match.range(at: 2), in: cardText) {
                    startTime = String(cardText[startRange])
                    endTime = String(cardText[endRange])
                }

                // Determine status
                let hasRegisterButton = cardHtml.contains("INSCREVER") || cardHtml.contains("marca_aulas")
                let hasCancelButton = cardHtml.contains("CANCELAR") || cardHtml.contains("desmarca_aulas")
                let statusText = cardHtml.lowercased()

                let status = DropInClassStatus(
                    fromText: statusText,
                    hasRegisterButton: hasRegisterButton,
                    hasCancelButton: hasCancelButton
                )

                let classItem = DropInClass(
                    id: id,
                    name: name,
                    location: "",
                    startTime: startTime,
                    endTime: endTime,
                    status: status,
                    date: date,
                    boxId: boxId
                )
                classes.append(classItem)
            }
        } catch {
            // Return whatever we have
        }

        return classes
    }
}
