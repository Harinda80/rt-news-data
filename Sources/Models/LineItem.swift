import Foundation
import SwiftData

@Model
final class LineItem {
    var itemDescription: String
    var quantity: Double
    var unitPrice: Decimal
    var lineTotal: Decimal
    var category: Category?
    var expense: Expense?

    init(
        itemDescription: String,
        quantity: Double = 1,
        unitPrice: Decimal,
        lineTotal: Decimal,
        category: Category? = nil
    ) {
        self.itemDescription = itemDescription
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.lineTotal = lineTotal
        self.category = category
    }
}
