import Foundation
import SwiftData

enum PaymentKind: String, Codable, CaseIterable {
    case cash, credit, debit, wallet
}

@Model
final class PaymentMethod {
    var label: String
    var kind: PaymentKind
    var lastFour: String?
    var defaultCurrency: String

    init(label: String, kind: PaymentKind, lastFour: String? = nil, defaultCurrency: String = "USD") {
        self.label = label
        self.kind = kind
        self.lastFour = lastFour
        self.defaultCurrency = defaultCurrency
    }
}
