import Foundation
import SwiftData

@Model
final class ReceiptPhoto {
    var originalFileName: String
    var workingFileName: String
    var sha256: String
    var capturedAt: Date
    var latitude: Double?
    var longitude: Double?

    init(
        originalFileName: String,
        workingFileName: String,
        sha256: String,
        capturedAt: Date = .now,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.originalFileName = originalFileName
        self.workingFileName = workingFileName
        self.sha256 = sha256
        self.capturedAt = capturedAt
        self.latitude = latitude
        self.longitude = longitude
    }
}
