import Foundation

/// Represents a check-in QR code used for gym entry
public struct CheckInQRCode: Sendable {
    /// The raw code string (format: "boxId*userId*timestamp*hash")
    public let code: String

    /// Full URL to the QR code image
    public let imageURL: String

    /// The QR code image data (PNG)
    public let imageData: Data

    public init(code: String, imageURL: String, imageData: Data) {
        self.code = code
        self.imageURL = imageURL
        self.imageData = imageData
    }
}
