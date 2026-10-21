import XCTest
@testable import RegiBoxClient

final class RegiBoxClientTests: XCTestCase {

    // MARK: - Box Model Tests

    func testBoxInit() {
        let box = Box(id: "299", name: "REP Training Academy")

        XCTAssertEqual(box.id, "299")
        XCTAssertEqual(box.name, "REP Training Academy")
        XCTAssertEqual(box.logoURL?.absoluteString, "https://www.regibox.pt/escolas/299/logotipo.jpg")
    }

    func testBoxEquality() {
        let box1 = Box(id: "299", name: "REP Training Academy")
        let box2 = Box(id: "299", name: "REP Training Academy")
        let box3 = Box(id: "300", name: "Other Box")

        XCTAssertEqual(box1, box2)
        XCTAssertNotEqual(box1, box3)
    }

    // MARK: - HTMLParser Tests

    func testParseBoxesFromHTML() {
        // Using HTML structure similar to actual API response
        let html = """
        <ul>
            <li class="item-content"><img src="/escolas/299/logotipo.jpg" />&nbsp;&nbsp;
            <div onclick="abre_login('299');" class="item-inner">
            <div class="item-title" style="padding-left:10px;">REP Training Academy</div>
            </div>
            </li>
            <li class="item-content"><img src="/escolas/252/logotipo.jpg" />&nbsp;&nbsp;
            <div onclick="abre_login('252');" class="item-inner">
            <div class="item-title" style="padding-left:10px;">12.79 Crossfit Lousã</div>
            </div>
            </li>
        </ul>
        """

        let boxes = HTMLParser.parseBoxes(html: html)

        XCTAssertEqual(boxes.count, 2)
        XCTAssertEqual(boxes[0].id, "299")
        XCTAssertEqual(boxes[0].name, "REP Training Academy")
        XCTAssertEqual(boxes[1].id, "252")
        XCTAssertEqual(boxes[1].name, "12.79 Crossfit Lousã")
    }

    func testParseBoxesEmptyHTML() {
        let html = "<html><body></body></html>"
        let boxes = HTMLParser.parseBoxes(html: html)

        XCTAssertTrue(boxes.isEmpty)
    }

    func testParseLoginForm() {
        let html = """
        <form action="verifica_acesso.php" method="post">
            <input name="id_box" type="hidden" value="299" />
            <input name="acs" type="hidden" value="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" />
            <input type="text" name="login3990dca" />
            <input type="password" name="password3990dca" />
        </form>
        """

        let formData = HTMLParser.parseLoginForm(html: html)

        XCTAssertNotNil(formData)
        XCTAssertEqual(formData?.acsToken, String(repeating: "a", count: 64))
        XCTAssertEqual(formData?.fieldSuffix, "3990dca")
    }

    func testParseLoginFormMissingACS() {
        let html = """
        <form>
            <input type="text" name="login3990dca" />
        </form>
        """

        let formData = HTMLParser.parseLoginForm(html: html)
        XCTAssertNil(formData)
    }

    // MARK: - Session Tests

    func testSessionCookieHeader() {
        let cookie1 = HTTPCookie(properties: [
            .name: "regybox_user",
            .value: "token123",
            .domain: "regibox.pt",
            .path: "/"
        ])!

        let cookie2 = HTTPCookie(properties: [
            .name: "PHPSESSID",
            .value: "session456",
            .domain: "regibox.pt",
            .path: "/"
        ])!

        let session = Session(userToken: "token123", boxId: "299", cookies: [cookie1, cookie2])

        XCTAssertTrue(session.cookieHeader.contains("regybox_user=token123"))
        XCTAssertTrue(session.cookieHeader.contains("PHPSESSID=session456"))
    }

    // MARK: - Client Tests

    func testClientInitialization() {
        let client = RegiBoxClient()

        XCTAssertFalse(client.isAuthenticated)
        XCTAssertNil(client.session)
    }

    func testLoginRejectsNonNumericBoxId() async {
        let client = RegiBoxClient()
        do {
            _ = try await client.login(boxId: "299&extra=1", email: "user@example.com", password: "example")
            XCTFail("Expected invalid box ID to be rejected before a request")
        } catch RegiBoxClient.ClientError.parsingError(let message) {
            XCTAssertEqual(message, "Box ID must contain only digits")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testClientLogout() {
        let client = RegiBoxClient()
        client.logout()

        XCTAssertFalse(client.isAuthenticated)
        XCTAssertNil(client.session)
    }
}

// MARK: - Integration Tests (require network)

final class RegiBoxClientIntegrationTests: XCTestCase {

    private func requireLiveTests() throws {
        guard ProcessInfo.processInfo.environment["REGIBOX_RUN_LIVE_TESTS"] == "1" else {
            throw XCTSkip("Set REGIBOX_RUN_LIVE_TESTS=1 to run live RegiBox tests")
        }
    }

    func testListBoxes() async throws {
        try requireLiveTests()
        let client = RegiBoxClient()
        let boxes = try await client.listBoxes()

        XCTAssertFalse(boxes.isEmpty, "Should return at least some boxes")
        XCTAssertTrue(boxes.count > 100, "Should return many boxes")

        // Check that boxes have valid data
        for box in boxes.prefix(5) {
            XCTAssertFalse(box.id.isEmpty)
            XCTAssertFalse(box.name.isEmpty)
            XCTAssertNotNil(box.logoURL)
        }
    }

    /// Integration test for login - requires explicit opt-in and credentials.
    func testLogin() async throws {
        try requireLiveTests()
        guard let email = ProcessInfo.processInfo.environment["REGIBOX_EMAIL"],
              let password = ProcessInfo.processInfo.environment["REGIBOX_PASSWORD"],
              let boxId = ProcessInfo.processInfo.environment["REGIBOX_BOX_ID"] else {
            throw XCTSkip("Set REGIBOX_EMAIL, REGIBOX_PASSWORD, and REGIBOX_BOX_ID for live login test")
        }

        let client = RegiBoxClient()

        let session = try await client.login(
            boxId: boxId,
            email: email,
            password: password
        )

        XCTAssertTrue(client.isAuthenticated)
        XCTAssertEqual(session.boxId, boxId)
        XCTAssertFalse(session.userToken.isEmpty)
    }
}
