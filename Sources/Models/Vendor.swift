import Foundation
import SwiftData

@Model
final class Vendor {
    var displayName: String
    var rawAliases: [String]
    var defaultCurrency: String
    var defaultCategory: Category?

    init(displayName: String, rawAliases: [String] = [], defaultCurrency: String = "USD", defaultCategory: Category? = nil) {
        self.displayName = displayName
        self.rawAliases = rawAliases
        self.defaultCurrency = defaultCurrency
        self.defaultCategory = defaultCategory
    }
}
