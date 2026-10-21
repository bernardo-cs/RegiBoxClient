import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Client for the OSRM (Open Source Routing Machine) Table API.
/// Uses the free demo server to get driving durations between coordinates.
public enum OSRMClient {

    // MARK: - Types

    private struct TableResponse: Decodable {
        let code: String
        let durations: [[Double?]]?
    }

    // MARK: - Public API

    /// Get driving durations from a user location to multiple drop-in boxes.
    /// - Parameters:
    ///   - latitude: User's latitude
    ///   - longitude: User's longitude
    ///   - boxes: Array of DropInBox destinations
    /// - Returns: Dictionary mapping box ID to driving duration in seconds
    public static func getDrivingDurations(
        from latitude: Double,
        longitude: Double,
        to boxes: [DropInBox]
    ) async -> [String: Double] {
        // Filter to boxes with GPS coordinates
        let validBoxes = boxes.filter { $0.latitude != nil && $0.longitude != nil }
        guard !validBoxes.isEmpty else { return [:] }

        // OSRM demo server handles ~100 coordinates per request.
        // We use source index 0 + up to 99 destinations per batch.
        let batchSize = 99
        var result: [String: Double] = [:]

        for batchStart in stride(from: 0, to: validBoxes.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, validBoxes.count)
            let batch = Array(validBoxes[batchStart..<batchEnd])

            do {
                let batchResult = try await fetchBatch(
                    userLat: latitude,
                    userLng: longitude,
                    boxes: batch
                )
                result.merge(batchResult) { _, new in new }
            } catch {
                fputs("Warning: OSRM batch \(batchStart/batchSize + 1) failed: \(error.localizedDescription)\n", stderr)
            }
        }

        return result
    }

    // MARK: - Private

    private static func fetchBatch(
        userLat: Double,
        userLng: Double,
        boxes: [DropInBox]
    ) async throws -> [String: Double] {
        // Build coordinates string: source first, then destinations
        // OSRM uses lng,lat order (opposite of lat,lng)
        var coords = "\(userLng),\(userLat)"
        for box in boxes {
            coords += ";\(box.longitude!),\(box.latitude!)"
        }

        let urlString = "https://router.project-osrm.org/table/v1/driving/\(coords)?sources=0&annotations=duration"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, _) = try await URLSession.shared.asyncData(for: request)

        let response = try JSONDecoder().decode(TableResponse.self, from: data)

        guard response.code == "Ok",
              let durations = response.durations,
              !durations.isEmpty else {
            throw URLError(.cannotParseResponse)
        }

        // durations[0] is the row for source (index 0)
        // durations[0][0] is source-to-source (0), durations[0][1..] are source-to-destinations
        let row = durations[0]
        var result: [String: Double] = [:]
        for (i, box) in boxes.enumerated() {
            // Index i+1 because index 0 is the source itself
            if i + 1 < row.count, let duration = row[i + 1] {
                result[box.id] = duration
            }
        }

        return result
    }
}
