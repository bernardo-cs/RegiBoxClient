import Foundation

/// Legacy regex-based HTML parser (kept for comparison testing during SwiftSoup migration)
enum HTMLParserLegacy {

    // MARK: - Box List Parsing

    /// Parses the box list HTML and returns an array of Box objects
    /// - Parameter html: HTML string from escolha_clube.php
    /// - Returns: Array of parsed Box objects
    static func parseBoxes(html: String) -> [Box] {
        var boxes: [Box] = []

        // Pattern to match: onclick="abre_login('ID');" ... item-title...>NAME</div>
        // The onclick handler contains the box ID, and item-title div contains the name
        // Note: onclick ends with ");" before the closing quote
        let pattern = #"onclick=[\"']abre_login\([\"'](\d+)[\"']\);?[\"'][^>]*>.*?class=[\"']item-title[\"'][^>]*>([^<]*)<"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return boxes
        }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            guard match.numberOfRanges >= 3,
                  let idRange = Range(match.range(at: 1), in: html),
                  let nameRange = Range(match.range(at: 2), in: html) else {
                continue
            }

            let id = String(html[idRange])
            let name = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip boxes without names
            guard !name.isEmpty else { continue }

            boxes.append(Box(id: id, name: name))
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
        // Extract ACS token: <input name="acs" ... value="TOKEN" />
        let acsPattern = #"name=[\"']acs[\"'][^>]*value=[\"']([a-f0-9]+)[\"']"#
        guard let acsRegex = try? NSRegularExpression(pattern: acsPattern, options: []),
              let acsMatch = acsRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
              acsMatch.numberOfRanges >= 2,
              let acsRange = Range(acsMatch.range(at: 1), in: html) else {
            return nil
        }
        let acsToken = String(html[acsRange])

        // Extract field suffix from login field: name="login{SUFFIX}"
        let suffixPattern = #"name=[\"']login([a-f0-9]+)[\"']"#
        guard let suffixRegex = try? NSRegularExpression(pattern: suffixPattern, options: []),
              let suffixMatch = suffixRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
              suffixMatch.numberOfRanges >= 2,
              let suffixRange = Range(suffixMatch.range(at: 1), in: html) else {
            return nil
        }
        let fieldSuffix = String(html[suffixRange])

        return LoginFormData(acsToken: acsToken, fieldSuffix: fieldSuffix)
    }

    // MARK: - Classes Parsing

    /// Parses the classes list HTML from aulas.php
    /// - Parameters:
    ///   - html: HTML string from aulas.php
    ///   - date: Date string in YYYY-MM-DD format
    /// - Returns: Array of Class objects
    static func parseClasses(html: String, date: String) -> [Class] {
        var classes: [Class] = []

        // Split by class card divs (feed_time_slot)
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
            let idPattern = #"valor3=(\d+)"#
            guard let idRegex = try? NSRegularExpression(pattern: idPattern, options: []),
                  let idMatch = idRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
                  idMatch.numberOfRanges >= 2,
                  let idRange = Range(idMatch.range(at: 1), in: cardHtml) else {
                continue
            }
            let classId = String(cardHtml[idRange])

            // Extract class name (first col-50 content, uppercase)
            let namePattern = #"col-50[^>]*align=\"left\"[^>]*>[\s\S]*?([A-Z][A-Z\s]+[A-Z])\s*<"#
            let name: String
            if let nameRegex = try? NSRegularExpression(pattern: namePattern, options: []),
               let nameMatch = nameRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
               nameMatch.numberOfRanges >= 2,
               let nameRange = Range(nameMatch.range(at: 1), in: cardHtml) {
                name = String(cardHtml[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                continue
            }

            // Extract location (second col-50, right aligned)
            let locationPattern = #"col-50[^>]*align=\"right\"[^>]*>[\s\S]*?&nbsp;([^<]+)<"#
            var location = ""
            if let locRegex = try? NSRegularExpression(pattern: locationPattern, options: []),
               let locMatch = locRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
               locMatch.numberOfRanges >= 2,
               let locRange = Range(locMatch.range(at: 1), in: cardHtml) {
                location = String(cardHtml[locRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Extract time: "06:00 - 07:00"
            let timePattern = #"(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})"#
            var startTime = ""
            var endTime = ""
            if let timeRegex = try? NSRegularExpression(pattern: timePattern, options: []),
               let timeMatch = timeRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
               timeMatch.numberOfRanges >= 3,
               let startRange = Range(timeMatch.range(at: 1), in: cardHtml),
               let endRange = Range(timeMatch.range(at: 2), in: cardHtml) {
                startTime = String(cardHtml[startRange])
                endTime = String(cardHtml[endRange])
            }

            // Extract capacity: "2 de 14"
            let capacityPattern = #"(\d+)\s+de\s+(\d+)"#
            var enrolled = 0
            var capacity = 0
            if let capRegex = try? NSRegularExpression(pattern: capacityPattern, options: []),
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

            let classItem = Class(
                id: classId,
                name: name,
                location: location,
                startTime: startTime,
                endTime: endTime,
                enrolled: enrolled,
                capacity: capacity,
                status: status,
                date: date
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

        // Find the feed_coachs section
        guard let coachsStart = html.range(of: "id=\"feed_coachs\""),
              let coachsEnd = html.range(of: "</div>", range: coachsStart.upperBound..<html.endIndex) else {
            return instructors
        }

        let coachsSection = String(html[coachsStart.lowerBound..<coachsEnd.upperBound])

        // Pattern: <img src="...photo..." /> ... <div ...>Name</div>
        let pattern = #"<img\s+src=\"([^\"]+)\"[^>]*/>[\s\S]*?text-transform:\s*uppercase[^>]*>\s*([^<]+)<"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return instructors
        }

        let range = NSRange(coachsSection.startIndex..., in: coachsSection)
        let matches = regex.matches(in: coachsSection, options: [], range: range)

        for match in matches {
            guard match.numberOfRanges >= 3,
                  let photoRange = Range(match.range(at: 1), in: coachsSection),
                  let nameRange = Range(match.range(at: 2), in: coachsSection) else {
                continue
            }

            let photoPath = String(coachsSection[photoRange])
            let name = String(coachsSection[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)

            guard !name.isEmpty else { continue }

            // Build full photo URL
            var photoURL: URL?
            if photoPath.hasPrefix("../") {
                // Relative path like ../../../escolas/299/fotos_profs/...
                let cleanPath = photoPath.replacingOccurrences(of: "../", with: "")
                photoURL = URL(string: "https://www.regibox.pt/\(cleanPath)")
            } else {
                photoURL = URL(string: "https://www.regibox.pt\(photoPath)")
            }

            instructors.append(Instructor(name: name, photoURL: photoURL))
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
        let sections = [
            ("Warm-Up", \Workout.warmUp),
            ("Warm Up", \Workout.warmUp),
            ("Skill", \Workout.skill),
            ("Strength", \Workout.strength),
            ("Strentgth", \Workout.strength),
            ("Condition", \Workout.condition),
            ("CondiTion", \Workout.condition),
        ]

        for (sectionName, _) in sections {
            let pattern = #"<strong>\s*"# + NSRegularExpression.escapedPattern(for: sectionName) + #"\s*</strong>[\s\S]*?<div[^>]*>([^<]*(?:<br\s*/?>[\s\S]*?)*)</div>"#

            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               match.numberOfRanges >= 2,
               let contentRange = Range(match.range(at: 1), in: html) {

                let content = cleanWorkoutContent(String(html[contentRange]))
                if !content.isEmpty {
                    let lowercased = sectionName.lowercased()
                    if lowercased.contains("warm") {
                        warmUp = content
                    } else if lowercased.contains("skill") {
                        skill = content
                    } else if lowercased.contains("strength") || lowercased.contains("strentgth") {
                        strength = content
                    } else if lowercased.contains("condition") {
                        condition = content
                    }
                    matchedNames.insert(sectionName.lowercased())
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

        // Pattern: position number and name in item-title
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

        // The HTML contains list items with <a> tags containing onclick handlers
        // Updated pattern to match actual HTML structure:
        // <li>
        //   <a onclick="open_page('dropin_regras','&valor1=ID&acs=...');">
        //     <div class="item-media">...</div>
        //     <div class="item-inner">
        //       <div class="item-title">Box Name
        //         <div class="item-header">Address<br>lat &nbsp;lng</div>
        //       </div>
        //     </div>
        //   </a>
        // </li>

        // Match <a> elements with onclick containing valor1=ID and capture surrounding content up to </li>
        // Pattern: <a onclick="...valor1=ID..."...>...content...</a>...</li>
        // Note: HTML may use &amp; entity for ampersand, so match both & and &amp;
        // The onclick attribute value may contain single quotes (e.g., open_page('...')), so only match double quotes as delimiters
        let itemPattern = #"<a[^>]*onclick="[^"]*(?:&amp;)?valor1=(\d+)[^"]*"[^>]*>[\s\S]*?</a>[\s\S]*?</li>"#
        guard let itemRegex = try? NSRegularExpression(pattern: itemPattern, options: [.caseInsensitive]) else {
            return boxes
        }

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

            // Extract box name from item-title div
            // The name is the text directly inside item-title, before any child divs
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
            // Format: "41.364957865724875 &nbsp;-8.399160335276123" or "lat lng"
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

            boxes.append(DropInBox(
                id: boxId,
                name: name,
                address: address,
                latitude: latitude,
                longitude: longitude
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
        // Extract box name from page-title or header
        let namePattern = #"class=[\"']page-title[\"'][^>]*>([^<]+)<"#
        var boxName = ""
        if let nameRegex = try? NSRegularExpression(pattern: namePattern, options: []),
           let nameMatch = nameRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           nameMatch.numberOfRanges >= 2,
           let nameRange = Range(nameMatch.range(at: 1), in: html) {
            boxName = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // If we couldn't find the name, try alternative patterns
        if boxName.isEmpty {
            let altNamePattern = #"<h1[^>]*>([^<]+)</h1>"#
            if let altRegex = try? NSRegularExpression(pattern: altNamePattern, options: []),
               let altMatch = altRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               altMatch.numberOfRanges >= 2,
               let altRange = Range(altMatch.range(at: 1), in: html) {
                boxName = String(html[altRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Create basic box info
        let box = DropInBox(id: boxId, name: boxName.isEmpty ? "Unknown Box" : boxName)

        // Parse rules
        let rules = parseDropInRules(from: html)

        // Parse schedule
        let schedule = parseDropInSchedule(from: html)

        // Parse available class types
        let classTypes = parseDropInClassTypes(from: html)

        // Parse social links
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

        // Registration advance: look for patterns like "2 dias" or "0 dias e 0 minutos"
        let advancePattern = #"(?:inscrever|antecedência)[^<]*?(\d+)\s*dias?(?:\s*e\s*(\d+)\s*minutos?)?"#
        if let advRegex = try? NSRegularExpression(pattern: advancePattern, options: [.caseInsensitive]),
           let advMatch = advRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           advMatch.numberOfRanges >= 2,
           let daysRange = Range(advMatch.range(at: 1), in: html) {
            registrationAdvanceDays = Int(html[daysRange]) ?? 0
            if advMatch.numberOfRanges >= 3, let minsRange = Range(advMatch.range(at: 2), in: html) {
                registrationAdvanceMinutes = Int(html[minsRange]) ?? 0
            }
        }

        // Registration cutoff: minutes before class
        let regCutoffPattern = #"(?:até|limite)[^<]*?(\d+)\s*minutos?\s*(?:antes|início)"#
        if let cutoffRegex = try? NSRegularExpression(pattern: regCutoffPattern, options: [.caseInsensitive]),
           let cutoffMatch = cutoffRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           cutoffMatch.numberOfRanges >= 2,
           let minsRange = Range(cutoffMatch.range(at: 1), in: html) {
            registrationCutoffMinutes = Int(html[minsRange]) ?? 0
        }

        // Cancellation cutoff
        let cancelPattern = #"(?:cancelar|desmarca)[^<]*?(\d+)\s*minutos?"#
        if let cancelRegex = try? NSRegularExpression(pattern: cancelPattern, options: [.caseInsensitive]),
           let cancelMatch = cancelRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           cancelMatch.numberOfRanges >= 2,
           let minsRange = Range(cancelMatch.range(at: 1), in: html) {
            cancellationCutoffMinutes = Int(html[minsRange]) ?? 0
        }

        // Max absences
        let absencePattern = #"(\d+)\s*(?:faltas?|ausências?)"#
        if let absRegex = try? NSRegularExpression(pattern: absencePattern, options: [.caseInsensitive]),
           let absMatch = absRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           absMatch.numberOfRanges >= 2,
           let numRange = Range(absMatch.range(at: 1), in: html) {
            maxAllowedAbsences = Int(html[numRange]) ?? 0
        }

        // Price: €12,00 format
        let pricePattern = #"€\s*(\d+[,.]?\d*)"#
        if let priceRegex = try? NSRegularExpression(pattern: pricePattern, options: []),
           let priceMatch = priceRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           priceMatch.numberOfRanges >= 2,
           let priceRange = Range(priceMatch.range, in: html) {
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

        // Pattern: Day name followed by hours (e.g., "Segunda-feira" ... "06:40 - 21:00" or "Encerrado")
        let days = ["Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado", "Domingo"]

        for day in days {
            // Look for the day name and capture the hours that follow
            let dayPattern = NSRegularExpression.escapedPattern(for: day) + #"[\s\S]*?(?:(\d{2}:\d{2}\s*-\s*\d{2}:\d{2})|(Encerrado|Fechado))"#
            if let dayRegex = try? NSRegularExpression(pattern: dayPattern, options: [.caseInsensitive]),
               let dayMatch = dayRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)) {

                var hours = "Encerrado"
                if dayMatch.numberOfRanges >= 2, let hoursRange = Range(dayMatch.range(at: 1), in: html) {
                    hours = String(html[hoursRange]).trimmingCharacters(in: .whitespaces)
                } else if dayMatch.numberOfRanges >= 3, let closedRange = Range(dayMatch.range(at: 2), in: html) {
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

        // Look for common class type names in the HTML
        let commonTypes = ["WOD", "OPENBOX", "Open Box", "PILATES", "YOGA", "MOBILITY", "GYMNASTICS", "WEIGHTLIFTING", "ENDURANCE", "HIIT"]

        for classType in commonTypes {
            if html.range(of: classType, options: .caseInsensitive) != nil {
                // Normalize the name
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

        // Website link
        let websitePattern = #"href=[\"'](https?://(?!.*facebook|.*instagram)[^\"']+)[\"']"#
        if let webRegex = try? NSRegularExpression(pattern: websitePattern, options: []),
           let webMatch = webRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           webMatch.numberOfRanges >= 2,
           let urlRange = Range(webMatch.range(at: 1), in: html) {
            let urlStr = String(html[urlRange])
            if !urlStr.contains("regibox.pt") {
                website = URL(string: urlStr)
            }
        }

        // Facebook link
        let fbPattern = #"href=[\"'](https?://[^\"']*facebook[^\"']+)[\"']"#
        if let fbRegex = try? NSRegularExpression(pattern: fbPattern, options: []),
           let fbMatch = fbRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           fbMatch.numberOfRanges >= 2,
           let urlRange = Range(fbMatch.range(at: 1), in: html) {
            facebook = URL(string: String(html[urlRange]))
        }

        // Instagram link
        let igPattern = #"href=[\"'](https?://[^\"']*instagram[^\"']+)[\"']"#
        if let igRegex = try? NSRegularExpression(pattern: igPattern, options: []),
           let igMatch = igRegex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           igMatch.numberOfRanges >= 2,
           let urlRange = Range(igMatch.range(at: 1), in: html) {
            instagram = URL(string: String(html[urlRange]))
        }

        if website == nil && facebook == nil && instagram == nil {
            return nil
        }

        return SocialLinks(website: website, facebook: facebook, instagram: instagram)
    }

    /// Parse drop-in classes list from aulas_dropin.php
    /// - Parameters:
    ///   - html: HTML response from aulas_dropin.php
    ///   - date: Date string in YYYY-MM-DD format
    ///   - boxId: The box ID for reference
    /// - Returns: Array of DropInClass objects
    static func parseDropInClasses(html: String, date: String, boxId: String) -> [DropInClass] {
        var classes: [DropInClass] = []

        // Similar to regular classes parsing, but for drop-in format
        // Split by class card divs (feed_time_slot)
        let cardPattern = #"id=\"feed_time_slot\d+\"[^>]*>[\s\S]*?(?=id=\"feed_time_slot|$)"#
        guard let cardRegex = try? NSRegularExpression(pattern: cardPattern, options: []) else {
            return classes
        }

        let range = NSRange(html.startIndex..., in: html)
        let cardMatches = cardRegex.matches(in: html, options: [], range: range)

        for cardMatch in cardMatches {
            guard let cardRange = Range(cardMatch.range, in: html) else { continue }
            let cardHtml = String(html[cardRange])

            // Extract class ID from onclick handler: id_aula=CLASSID or valor3=CLASSID
            let idPattern = #"(?:id_aula|valor3)=(\d+)"#
            guard let idRegex = try? NSRegularExpression(pattern: idPattern, options: []),
                  let idMatch = idRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
                  idMatch.numberOfRanges >= 2,
                  let idRange = Range(idMatch.range(at: 1), in: cardHtml) else {
                continue
            }
            let classId = String(cardHtml[idRange])

            // Extract class name
            let namePattern = #"col-50[^>]*align=\"left\"[^>]*>[\s\S]*?([A-Z][A-Z\s]+[A-Z])\s*<"#
            let name: String
            if let nameRegex = try? NSRegularExpression(pattern: namePattern, options: []),
               let nameMatch = nameRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
               nameMatch.numberOfRanges >= 2,
               let nameRange = Range(nameMatch.range(at: 1), in: cardHtml) {
                name = String(cardHtml[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                // Try alternative name pattern
                let altNamePattern = #"class=[\"']item-title[\"'][^>]*>([^<]+)<"#
                if let altRegex = try? NSRegularExpression(pattern: altNamePattern, options: []),
                   let altMatch = altRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
                   altMatch.numberOfRanges >= 2,
                   let altRange = Range(altMatch.range(at: 1), in: cardHtml) {
                    name = String(cardHtml[altRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    continue
                }
            }

            // Extract location
            let locationPattern = #"col-50[^>]*align=\"right\"[^>]*>[\s\S]*?&nbsp;([^<]+)<"#
            var location = ""
            if let locRegex = try? NSRegularExpression(pattern: locationPattern, options: []),
               let locMatch = locRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
               locMatch.numberOfRanges >= 2,
               let locRange = Range(locMatch.range(at: 1), in: cardHtml) {
                location = String(cardHtml[locRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Extract time: "06:00 - 07:00"
            let timePattern = #"(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})"#
            var startTime = ""
            var endTime = ""
            if let timeRegex = try? NSRegularExpression(pattern: timePattern, options: []),
               let timeMatch = timeRegex.firstMatch(in: cardHtml, options: [], range: NSRange(cardHtml.startIndex..., in: cardHtml)),
               timeMatch.numberOfRanges >= 3,
               let startRange = Range(timeMatch.range(at: 1), in: cardHtml),
               let endRange = Range(timeMatch.range(at: 2), in: cardHtml) {
                startTime = String(cardHtml[startRange])
                endTime = String(cardHtml[endRange])
            }

            // Determine status based on buttons and text
            let hasRegisterButton = cardHtml.contains("INSCREVER") || cardHtml.contains("marca_aulas")
            let hasCancelButton = cardHtml.contains("CANCELAR") || cardHtml.contains("desmarca_aulas")
            let statusText = cardHtml.lowercased()

            let status = DropInClassStatus(
                fromText: statusText,
                hasRegisterButton: hasRegisterButton,
                hasCancelButton: hasCancelButton
            )

            let classItem = DropInClass(
                id: classId,
                name: name,
                location: location,
                startTime: startTime,
                endTime: endTime,
                status: status,
                date: date,
                boxId: boxId
            )
            classes.append(classItem)
        }

        return classes
    }
}
