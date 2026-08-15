import UIKit
import CryptoKit

enum ReceiptStore {
    static func save(_ image: UIImage) -> ReceiptPhoto? {
        guard let data = image.jpegData(compressionQuality: 0.92) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let url = receiptsDirectory().appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .completeFileProtection)
        } catch {
            return nil
        }
        let hash = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        return ReceiptPhoto(originalFileName: fileName, workingFileName: fileName, sha256: hash)
    }

    static func receiptsDirectory() -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("Receipts", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}
