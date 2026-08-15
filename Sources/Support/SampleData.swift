import Foundation
import SwiftData

enum SampleData {
    static let defaultCategoryNames: [(String, String)] = [
        ("Groceries", "5B7C99"),
        ("Dining & Coffee", "B9832E"),
        ("Transport", "5B7C99"),
        ("Fuel", "5B7C99"),
        ("Utilities", "8B958C"),
        ("Rent & Housing", "8B958C"),
        ("Health & Pharmacy", "4C7A5E"),
        ("Shopping", "8B5D7A"),
        ("Electronics", "8B5D7A"),
        ("Entertainment & Subscriptions", "8B5D7A"),
        ("Travel", "4C7A5E"),
        ("Fees & Charges", "A23E32"),
        ("Gifts", "8B5D7A"),
        ("Education", "5B7C99"),
        ("Business", "8B958C"),
        ("Cash Withdrawal", "8B958C"),
        ("Other", "8B958C")
    ]

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let existingCategories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        guard existingCategories.isEmpty else { return }

        for (name, hex) in defaultCategoryNames {
            context.insert(Category(name: name, colorHex: hex))
        }
        context.insert(PaymentMethod(label: "Cash", kind: .cash, defaultCurrency: "USD"))
        try? context.save()
    }
}
