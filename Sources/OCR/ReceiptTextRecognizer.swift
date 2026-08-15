import Foundation
import Vision
import UIKit

struct ExpenseDraft {
    var vendorName: String
    var amount: Decimal
    var currencyCode: String
    var date: Date
    var rawText: String
}

enum ReceiptTextRecognizer {
    static func draft(from images: [UIImage]) async -> ExpenseDraft {
        var allLines: [String] = []
        for image in images {
            allLines += await recognizeLines(in: image)
        }

        let vendor = allLines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? "New Vendor"
        let amount = guessTotal(in: allLines) ?? 0
        let currency = guessCurrency(in: allLines) ?? "USD"

        return ExpenseDraft(
            vendorName: vendor.trimmingCharacters(in: .whitespaces),
            amount: amount,
            currencyCode: currency,
            date: .now,
            rawText: allLines.joined(separator: "\n")
        )
    }

    private static func recognizeLines(in image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    private static func guessTotal(in lines: [String]) -> Decimal? {
        let totalLines = lines.filter { $0.localizedCaseInsensitiveContains("total") }
        let searchLines = totalLines.isEmpty ? lines : totalLines
        for line in searchLines.reversed() {
            if let amount = firstDecimal(in: line) {
                return amount
            }
        }
        return nil
    }

    private static func firstDecimal(in line: String) -> Decimal? {
        let pattern = #"\d+[.,]\d{2}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              let matchRange = Range(match.range, in: line) else { return nil }
        let raw = line[matchRange].replacingOccurrences(of: ",", with: ".")
        return Decimal(string: raw)
    }

    private static func guessCurrency(in lines: [String]) -> String? {
        let joined = lines.joined()
        if joined.contains("$") { return "USD" }
        if joined.contains("£") { return "GBP" }
        if joined.contains("€") { return "EUR" }
        if joined.contains("¥") { return "JPY" }
        return nil
    }
}
