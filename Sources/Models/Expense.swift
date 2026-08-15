import Foundation
import SwiftData

enum SourceChannel: String, Codable, CaseIterable {
    case inPerson, online, inApp, recurring
}

@Model
final class Expense {
    var dateTime: Date
    var vendor: Vendor?
    var sourceChannel: SourceChannel
    var paymentMethod: PaymentMethod?

    var originalCurrency: String
    var originalAmount: Decimal
    var exchangeRateToHome: Decimal
    var homeCurrency: String
    var homeAmount: Decimal

    var notes: String
    var hasReceipt: Bool

    @Relationship(deleteRule: .cascade) var items: [LineItem]
    @Relationship(deleteRule: .cascade) var photos: [ReceiptPhoto]
    var tags: [Tag]

    var createdAt: Date
    var deletedAt: Date?

    init(
        dateTime: Date = .now,
        vendor: Vendor? = nil,
        sourceChannel: SourceChannel = .inPerson,
        paymentMethod: PaymentMethod? = nil,
        originalCurrency: String = "USD",
        originalAmount: Decimal,
        exchangeRateToHome: Decimal = 1,
        homeCurrency: String = "USD",
        notes: String = "",
        hasReceipt: Bool = true,
        items: [LineItem] = [],
        photos: [ReceiptPhoto] = [],
        tags: [Tag] = []
    ) {
        self.dateTime = dateTime
        self.vendor = vendor
        self.sourceChannel = sourceChannel
        self.paymentMethod = paymentMethod
        self.originalCurrency = originalCurrency
        self.originalAmount = originalAmount
        self.exchangeRateToHome = exchangeRateToHome
        self.homeCurrency = homeCurrency
        self.homeAmount = originalAmount * exchangeRateToHome
        self.notes = notes
        self.hasReceipt = hasReceipt
        self.items = items
        self.photos = photos
        self.tags = tags
        self.createdAt = .now
    }
}
