import XCTest
@testable import RegiBoxClient

final class CurrentAppParserTests: XCTestCase {
    func testClassCardsAndActions() {
        let html = """
        <div class="a_remaining">Ter, 20 Out 2026</div>
        <div id="feed_time_slot1"><div class="a_aula">
          <div class="a_nome_aula">CROSS TRAINING</div><span class="a_prof">Black Box</span>
          <div class="a_hora">06:00 - 07:00</div><div class="a_insc">1 de 14</div>
          <a href="/class_details/?id=103708&amp;acs=abc&amp;type=1">Details</a>
          <button onclick="book_class('pages/classes/scripts/book_classes.php?id_aula=103708&amp;acs=abc')">RESERVAR</button>
        </div></div>
        """
        let classes = HTMLParserV3.classes(html, date: "2026-10-20")
        XCTAssertEqual(classes.count, 1)
        XCTAssertEqual(classes.first?.id, "103708")
        XCTAssertEqual(classes.first?.name, "CROSS TRAINING")
        XCTAssertEqual(classes.first?.capacity, 14)
        XCTAssertTrue(classes.first?.canBook == true)
        XCTAssertTrue(classes.first?.bookingURL?.contains("book_classes.php") == true)
    }

    func testEmbeddedDropInBoxes() {
        let html = #"<script>var boxes = [{"id":314,"cod":"314","sub":0,"nome":"CrossFit Alges","morada":"Rua A*Lisboa","lat":"38.7","lon":"-9.1","acs":"abc"}];</script>"#
        let boxes = HTMLParserV3.dropInBoxes(html)
        XCTAssertEqual(boxes.count, 1)
        XCTAssertEqual(boxes.first?.id, "314")
        XCTAssertEqual(boxes.first?.address, "Rua A, Lisboa")
        XCTAssertEqual(boxes.first?.latitude, 38.7)
    }

    func testClassDetailPageExposesWorkoutFeed() {
        let html = """
        <div class="page"><div class="nome_prof">Coach</div><div id="cd_wod_feed"></div></div>
        <script>
        var cd_wod_url = 'pages/cross/load_wod_dia.php?date=2026-10-26&tipo=1&src=aula';
        $('#cd_wod_feed').load(cd_wod_url);
        </script>
        """
        XCTAssertEqual(HTMLParserV3.workoutFeedPath(html), "/pages/cross/load_wod_dia.php?date=2026-10-26&tipo=1&src=aula")
        XCTAssertNil(HTMLParserV3.workoutFeedPath("<div class=\"page\"></div>"))
    }

    func testWorkoutFeed() throws {
        let html = """
        <script>window.wod_play_video = function(el){};</script>
        <div class="wod-group"><div class="wod-group-body">
          <div class="card wod-card"><div class="wod-card-head"><div class="wod-card-title">Warm-Up</div></div>
            <div class="wod-card-desc texto14">3 rounds<br/>10 air squats</div></div>
          <div class="card wod-card"><div class="wod-card-head"><div class="wod-card-title">Skill</div></div>
            <div class="wod-card-types">Qualidade</div></div>
          <div class="card wod-card"><div class="wod-card-head"><div class="wod-card-title">Conditioning</div>
            <div class="wod-badges"><span class="wod-badge">2</span></div></div>
            <div class="wod-card-desc texto14">Annie &amp; Karen<br/><br/>FOR TIME:<br/><br/>50-40-30-20-10<br/>Double Unders each</div></div>
          <div class="card wod-card"><div class="wod-card-head"><div class="wod-card-title">Cool Down</div></div>
            <div class="wod-card-desc">Stretch</div></div>
        </div></div>
        """
        let workout = try XCTUnwrap(HTMLParserV3.workout(html))
        XCTAssertEqual(workout.warmUp, "3 rounds\n10 air squats")
        XCTAssertNil(workout.skill, "Sections without a description are skipped")
        XCTAssertEqual(workout.condition, "Annie & Karen\n\nFOR TIME:\n\n50-40-30-20-10\nDouble Unders each")
        XCTAssertEqual(workout.additionalSections, [WorkoutSection(name: "Cool Down", content: "Stretch")])
    }

    func testWorkoutFeedWithUnknownLayoutIsEmpty() {
        XCTAssertTrue(HTMLParserV3.workout("<div class=\"wod\">Annie</div>")?.isEmpty ?? true)
    }

    func testUnexpectedPayloadDoesNotBecomeEmptyResults() {
        XCTAssertTrue(HTMLParserV3.classes("<h1>Esta APP deixou de funcionar</h1>", date: "2026-10-20").isEmpty)
        XCTAssertTrue(HTMLParserV3.dropInBoxes("<h1>Login</h1>").isEmpty)
        XCTAssertNil(HTMLParserV3.classHistorySummary("<h1>Login</h1>"))
    }
}

final class CurrentAppIntegrationTests: XCTestCase {
    private func signedInClient() async throws -> RegiBoxClient {
        guard ProcessInfo.processInfo.environment["REGIBOX_RUN_LIVE_TESTS"] == "1" else {
            throw XCTSkip("Set REGIBOX_RUN_LIVE_TESTS=1 to run live RegiBox tests")
        }
        guard let email = ProcessInfo.processInfo.environment["REGIBOX_EMAIL"],
              let password = ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"],
              let box = ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] else {
            throw XCTSkip("Set REGIBOX_EMAIL, REGIBOX_PASSWORD, and REGIBOX_BOX_ID for live app checks")
        }
        let client = RegiBoxClient()
        _ = try await client.login(boxId: box, email: email, password: password)
        return client
    }

    func testCurrentReadEndpoints() async throws {
        let client = try await signedInClient()
        defer { client.logout() }
        let boxes = try await client.listBoxes()
        XCTAssertGreaterThan(boxes.count, 0)
        _ = try await client.getClasses(for: Date())
        let dropInBoxes = try await client.listDropInBoxes()
        XCTAssertGreaterThan(dropInBoxes.count, 0)
        let details = try await client.getDropInBoxDetails(boxId: dropInBoxes[0].id)
        XCTAssertFalse(details.box.name.isEmpty)
        let summary = try await client.getClassHistorySummary()
        XCTAssertEqual(summary.monthlyData.count, 12)
        _ = try await client.getDropInHistory()
        let qr = try await client.getCheckInQRCode()
        XCTAssertTrue(qr.imageData.starts(with: [0x89, 0x50, 0x4e, 0x47]))
    }

    /// Fails when no Cross Training class in the next days shows a workout.
    /// That usually means the class detail page or the workout feed changed.
    func testClassDetailsIncludeWorkout() async throws {
        let client = try await signedInClient()
        defer { client.logout() }
        for offset in 0..<4 {
            let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
            let classes = try await client.getClasses(for: date)
            guard let cross = classes.first(where: { $0.name.uppercased().contains("CROSS") && $0.detailsURL != nil }) else { continue }
            let details = try await client.getClassDetails(cross)
            if let workout = details.workout, !workout.isEmpty { return }
        }
        XCTFail("No Cross Training class in the next 4 days returned a workout")
    }
}
