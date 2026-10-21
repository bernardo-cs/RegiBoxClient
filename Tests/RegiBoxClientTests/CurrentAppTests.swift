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
}
