# RegiBoxClient development guide

RegiBoxClient is an unofficial Swift client for RegiBox's browser app. The current
implementation targets `https://www.regibox.pt/php8/app3`. It parses HTML and JSON
from browser-facing routes, so upstream page changes may require parser updates.
This project is independent of RegiBox.

## Repository layout

- `Package.swift`: Swift Package Manager manifest (Swift 5.9, iOS 15+, macOS 12+).
- `Sources/RegiBoxClient/RegiBoxClient.swift`: authentication, requests, and public API.
- `Sources/RegiBoxClient/HTMLParser.swift`: parser for legacy page structures and test fixtures.
- `Sources/RegiBoxClient/HTMLParserV3.swift`: parser for the current app.
- `Sources/RegiBoxClient/HTMLParserLegacy.swift`: legacy parser retained for comparison.
- `Sources/RegiBoxClient/Models/`: public models.
- `Sources/RegiBoxClient/OSRMClient.swift`: optional driving-time lookup.
- `Sources/RegiBoxDemo/RegiBoxDemo.swift`: `regybox` command-line app.
- `Tests/RegiBoxClientTests/`: fixture tests and opt-in live integration tests.

## Current app routes

All paths below are relative to the current app base URL. They document the
client's implementation, not a stable or official API.

| Operation | Route and method |
| --- | --- |
| List boxes | `GET /pwa/999999/pages/login/escolha_clube.php?lang=pt` |
| Initialize login session | `GET /pwa/999999/?pwa=999999&id_box={boxId}&lang=pt&type=direct` |
| Get login form | `GET /pwa/999999/pages/login/login.php?pwa=999999&id_box={boxId}&lang=pt&type=direct` |
| Submit login | `POST /pwa/999999/pages/login/scripts/verifica_acesso.php?pwa=999999&id_box={boxId}&type=direct` |
| Establish user app session | `GET /pwa/{boxId}/?pwa={boxId}&ignore=s` |
| List classes | `GET /pages/classes/classes_list.php?date={yyyy-MM-dd}&type=1&plano=0&box=` |
| Class details | `GET /pages/classes/class_details.php?...` (derived from the class card's `/class_details/?...` link) |
| Book / cancel class | `GET /pages/classes/scripts/book_classes.php?...` / `cancel_class.php?...` (links parsed from class cards) |
| List drop-in boxes | `GET /pages/dropin/find_box.php` |
| Drop-in box rules | `GET /pages/dropin/box_regras.php?cod={code}&acs={acs}[&sub={subBox}]` |
| Drop-in classes | `GET /pages/dropin/aulas_dropin_list.php?date={yyyy-MM-dd}&cod={code}&acs={acs}[&sub={subBox}]` |
| Book / cancel drop-in | `POST /pages/dropin/scripts/marca_dropin.php` / `cancela_dropin.php` |
| Drop-in history and bookings | `GET /pages/dropin/dropin.php` |
| Class history summary | `GET /pages/classes/classes_historic.php` |
| Class history chart | `GET /pages/classes/scripts/classes_historic_load.php?yearOffset=0` |
| Class history list | `GET /pages/classes/classes_historic_list.php?data_ini=...&data_fim=...&ordem=...&tipo=...` |
| Check-in QR page | `GET /pages/login/check_in.php` (image URL is parsed from its HTML) |

The login form supplies a CSRF token, an `acs` token, and a dynamic suffix for the
email and password field names. Login submission returns JSON; the client then
loads the user's PWA shell and reads the `regy_user` cookie. The client's
`URLSession` uses an ephemeral cookie store. Call `login` again for a new client
instance and `logout` to clear its session.

Drop-in box records contain per-box `acs` tokens and a `code`/`subBox` pair.
Preserve those values when building drop-in requests. Search is a local filter
through `searchDropInBoxes(query:)`. Booking and cancellation responses are JSON
with a `success` boolean. These calls change real registrations.

## Development and tests

```bash
swift build
swift test
swift run regybox --help
```

Fixture tests run without an account. `CurrentAppIntegrationTests` and the login
integration test run only when explicitly enabled with these environment variables:

```bash
export REGIBOX_EMAIL="your@email.com"
export REGIBOX_PASSWORD="yourpassword"
export REGIBOX_BOX_ID="your-box-id"
export REGIBOX_RUN_LIVE_TESTS=1
swift test
```

Keep credentials in your shell or a local, ignored `.envrc`. Never commit
credentials, cookies, session tokens, QR codes, or personal data in test
fixtures. The current live tests read the service; they do not perform booking
or cancellation. Use an intentionally disposable booking if manually checking
those actions. A fixture pass does not verify that RegiBox's live pages still
match the parser.

The CLI supports `login`, `doctor`, `workflows`, `list-boxes`, `classes`, `class-detail`, `register`,
`unregister`, `dropin-boxes`, `dropin-details`, `dropin-classes`,
`dropin-register`, `dropin-unregister`, `dropin-nearby-classes`, `check-in`,
`class-history`, and `dropin-history`. Run `swift run regybox --help` for the
current options.

`OSRMClient` calls the public OSRM demo server for driving duration when the CLI
receives coordinates. The CLI can use straight-line distance with `--no-driving`.
