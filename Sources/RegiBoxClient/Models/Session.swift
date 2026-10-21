import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Represents an authenticated session with a RegiBox box
public struct Session: Sendable {
    /// The user's authentication token
    public let userToken: String

    /// The ID of the box the user is logged into
    public let boxId: String

    /// HTTP cookies from the authentication response
    public let cookies: [HTTPCookie]

    public init(userToken: String, boxId: String, cookies: [HTTPCookie]) {
        self.userToken = userToken
        self.boxId = boxId
        self.cookies = cookies
    }
}

extension Session {
    /// Returns cookies formatted for use in HTTP requests
    public var cookieHeader: String {
        cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
    }
}
