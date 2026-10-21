import Foundation
import SwiftSoup

/// Parsers for the current /php8/app3 application. The app renders HTML fragments
/// and embeds JSON for the larger drop-in views.
enum HTMLParserV3 {
    static func boxes(_ html: String) -> [Box] {
        guard let document = try? SwiftSoup.parse(html),
              let items = try? document.select("li.lista_clubes[onclick]") else { return [] }
        return items.compactMap { item in
            let action = (try? item.attr("onclick")) ?? ""
            guard let id = match("id_box=(\\d+)", in: action) else { return nil }
            let name = text(item, ".item-title")
            return name.isEmpty ? nil : Box(id: id, name: name)
        }
    }

    static func embeddedJSON(_ html: String, variable: String) -> Any? {
        guard let marker = html.range(of: "var \(variable)\\s*=\\s*", options: .regularExpression) else { return nil }
        let bytes = Array(html[marker.upperBound...].utf8)
        guard let first = bytes.first, first == 91 || first == 123 else { return nil }
        var depth = 0
        var quoted = false
        var escaped = false
        for (index, byte) in bytes.enumerated() {
            if quoted {
                if escaped { escaped = false }
                else if byte == 92 { escaped = true }
                else if byte == 34 { quoted = false }
            } else if byte == 34 {
                quoted = true
            } else if byte == 91 || byte == 123 {
                depth += 1
            } else if byte == 93 || byte == 125 {
                depth -= 1
                if depth == 0 {
                    return try? JSONSerialization.jsonObject(with: Data(bytes[0...index]))
                }
            }
        }
        return nil
    }

    private static func string(_ object: [String: Any], _ key: String) -> String {
        if let value = object[key] as? String { return value }
        if let value = object[key] as? NSNumber { return value.stringValue }
        return ""
    }

    private static func text(_ element: Element?, _ selector: String) -> String {
        guard let element, let found = try? element.select(selector).first() else { return "" }
        return ((try? found.text()) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func attribute(_ element: Element?, _ selector: String, _ name: String) -> String {
        guard let element, let found = try? element.select(selector).first() else { return "" }
        return (try? found.attr(name)) ?? ""
    }

    private static func match(_ pattern: String, in value: String, group: Int = 1) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let found = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
              found.numberOfRanges > group,
              let range = Range(found.range(at: group), in: value) else { return nil }
        return String(value[range])
    }

    static func classes(_ html: String, date: String) -> [Class] {
        guard let document = try? SwiftSoup.parse(html),
              let cards = try? document.select("div[id^=feed_time_slot]") else { return [] }
        return cards.compactMap { card in
            let details = attribute(card, "a[href*=/class_details/]", "href")
            guard let id = match("[?&]id=(\\d+)", in: details) else { return nil }
            let name = text(card, ".a_nome_aula")
            let time = text(card, ".a_hora")
            guard !name.isEmpty,
                  let start = match("(\\d{2}:\\d{2})\\s*[-–]", in: time),
                  let end = match("[-–]\\s*(\\d{2}:\\d{2})", in: time) else { return nil }
            let count = text(card, ".a_insc")
            let enrolled = Int(match("(\\d+)\\s+de", in: count) ?? "") ?? 0
            let capacity = Int(match("de\\s+(\\d+)", in: count) ?? "") ?? 0
            let statusText = text(card, ".a_info")
            let status = statusText.localizedCaseInsensitiveContains("terminad") ? ClassStatus.completed : ClassStatus(fromText: statusText)
            let button = attribute(card, "button[onclick]", "onclick")
            let bookingURL = match("book_class\\s*\\('([^']+)'", in: button)
            let cancelURL = match("cancel_class\\s*\\('([^']+)'", in: button)
            return Class(id: id, name: name, location: text(card, ".a_prof"), startTime: start,
                         endTime: end, enrolled: enrolled, capacity: capacity, status: status,
                         date: date, bookingURL: bookingURL, cancelURL: cancelURL, detailsURL: details,
                         canBook: bookingURL != nil, isRegistered: cancelURL != nil)
        }
    }

    static func classDetails(_ html: String, classInfo: Class) -> ClassDetails? {
        guard let document = try? SwiftSoup.parse(html),
              let page = try? document.select(".page").first() else { return nil }
        let name = text(page, ".nome_prof")
        let image = attribute(page, ".foto_prof img", "src")
        let instructor = name.isEmpty ? [] : [Instructor(name: name, photoURL: URL(string: image))]
        let cards = (try? page.select(".card_insc").array()) ?? []
        let participants = cards.compactMap { card -> Participant? in
            let name = text(card, ".item-title2")
            guard !name.isEmpty else { return nil }
            let position = Int(text(card, ".n_insc")) ?? 0
            let photo = attribute(card, ".item-media img", "src")
            return Participant(name: name, position: position, photoURL: URL(string: photo))
        }
        return ClassDetails(classInfo: classInfo, instructors: instructor, workout: nil, participants: participants)
    }

    static func dropInBoxes(_ html: String) -> [DropInBox] {
        guard let items = embeddedJSON(html, variable: "boxes") as? [[String: Any]] else { return [] }
        return items.compactMap { item in
            let id = string(item, "id")
            let name = string(item, "nome")
            guard !id.isEmpty, !name.isEmpty else { return nil }
            return DropInBox(id: id, name: name,
                             address: string(item, "morada").replacingOccurrences(of: "*", with: ", "),
                             latitude: Double(string(item, "lat")), longitude: Double(string(item, "lon")),
                             acsToken: string(item, "acs"), code: string(item, "cod"),
                             subBox: Int(string(item, "sub")) ?? 0)
        }
    }

    static func dropInDetails(_ html: String, box: DropInBox) -> DropInBoxDetails? {
        guard let data = embeddedJSON(html, variable: "d") as? [String: Any] else { return nil }
        let advance = string(data, "ruleAdvance")
        let booking = string(data, "ruleBooking")
        let cancellation = string(data, "ruleCancel")
        let rules = DropInRules(
            registrationAdvanceDays: Int(match("(\\d+)\\s*dia", in: advance) ?? "") ?? 0,
            registrationAdvanceMinutes: (Int(match("(\\d+)\\s*hora", in: advance) ?? "") ?? 0) * 60 +
                (Int(match("(\\d+)\\s*minuto", in: advance) ?? "") ?? 0),
            registrationCutoffMinutes: Int(match("(\\d+)\\s*minuto", in: booking) ?? "") ?? 0,
            cancellationCutoffMinutes: Int(match("(\\d+)\\s*minuto", in: cancellation) ?? "") ?? 0,
            maxAllowedAbsences: Int(match("(\\d+)", in: string(data, "ruleAbsences")) ?? "") ?? 0,
            price: string(data, "valorDropin"))
        let schedule = ((data["schedule"] as? [[String: Any]]) ?? []).map { day in
            let times = day["times"] as? [String] ?? []
            return DaySchedule(dayName: string(day, "label"), hours: times.isEmpty ? "Encerrado" : times.joined(separator: " - "))
        }
        let types = ((data["tipoAulas"] as? [[String: Any]]) ?? []).map { string($0, "nome") }.filter { !$0.isEmpty }
        return DropInBoxDetails(box: box, rules: rules, availableClassTypes: types, schedule: schedule, socialLinks: nil)
    }

    static func dropInClasses(_ html: String, date: String, boxId: String) -> [DropInClass] {
        guard let document = try? SwiftSoup.parse(html),
              let cards = try? document.select(".a_aula") else { return [] }
        return cards.enumerated().compactMap { index, card in
            let name = text(card, ".a_nome_aula")
            let time = text(card, ".a_hora")
            guard !name.isEmpty,
                  let start = match("(\\d{2}:\\d{2})\\s*[-–]", in: time),
                  let end = match("[-–]\\s*(\\d{2}:\\d{2})", in: time) else { return nil }
            let book = (try? card.select(".da-book-btn").first()) != nil
            let cancel = (try? card.select(".da-cancel-btn").first()) != nil
            let id = attribute(card, ".da-book-btn, .da-cancel-btn", "data-id")
            let status = DropInClassStatus(fromText: text(card, ".a_info"), hasRegisterButton: book, hasCancelButton: cancel)
            return DropInClass(id: id.isEmpty ? "unavailable-\(index + 1)" : id,
                               name: name, location: "", instructor: text(card, ".a_prof"), startTime: start,
                               endTime: end, status: status, date: date, boxId: boxId)
        }
    }

    static func classHistorySummary(_ html: String) -> ClassHistorySummary? {
        let values = matches("font-size:\\s*50px[^>]*>\\s*(\\d+)", in: html).compactMap(Int.init)
        guard values.count >= 3 else { return nil }
        return ClassHistorySummary(registrations: values[0], attendances: values[1], absences: values[2], monthlyData: [])
    }

    static func classHistory(_ html: String) -> [ClassHistoryEntry] {
        guard let document = try? SwiftSoup.parse(html),
              let items = try? document.select(".search-list li") else { return [] }
        return items.compactMap { item in
            let title = text(item, ".item-title").replacingOccurrences(of: "\u{00A0}", with: " ")
            guard let date = match("^(\\d{1,2}\\s+\\S+\\s+\\d{4})", in: title) else { return nil }
            let name = String(title.dropFirst(date.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return ClassHistoryEntry(date: date, className: name, status: AttendanceStatus(fromText: text(item, ".letra11")))
        }
    }

    static func dropInHistory(_ html: String) -> DropInHistorySummary? {
        guard let entries = embeddedJSON(html, variable: "historico") as? [[String: Any]],
              let registrations = Int(match("var\\s+totalDropin\\s*=\\s*(\\d+)", in: html) ?? ""),
              let attendances = Int(match("var\\s+presencas\\s*=\\s*(\\d+)", in: html) ?? ""),
              let absences = Int(match("var\\s+faltasNum\\s*=\\s*(\\d+)", in: html) ?? "") else { return nil }
        let history = entries.map { item in
            let logo = string(item, "logo")
            let boxId = match("escolas/(\\d+)/", in: logo) ?? ""
            let name = string(item, "nome_box")
            return DropInHistoryEntry(date: string(item, "data_ini"), startTime: string(item, "hora_ini"),
                                      endTime: string(item, "hora_fim"), boxId: boxId,
                                      boxAbbreviation: String(name.prefix(1)), className: string(item, "nome_aula"),
                                      isPresent: string(item, "assiduidade") == "P")
        }
        return DropInHistorySummary(registrations: registrations, attendances: attendances,
                                    absences: absences, entries: history)
    }

    static func myDropIns(_ html: String) -> [MyDropIn]? {
        guard let entries = embeddedJSON(html, variable: "upcoming") as? [[String: Any]] else { return nil }
        return entries.map { item in
            let logo = string(item, "logo")
            let boxId = match("escolas/(\\d+)/", in: logo) ?? ""
            let classId = string(item, "id_aula")
            let name = string(item, "nome_box")
            return MyDropIn(classId: classId, boxId: boxId, boxName: name,
                            dateText: string(item, "data_ini"), startTime: string(item, "hora_ini"),
                            endTime: string(item, "hora_fim"), logoURL: logo)
        }
    }

    private static func matches(_ pattern: String, in value: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        return regex.matches(in: value, range: NSRange(value.startIndex..., in: value)).compactMap { found in
            guard let range = Range(found.range(at: 1), in: value) else { return nil }
            return String(value[range])
        }
    }
}
