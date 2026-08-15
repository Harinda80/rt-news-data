import SwiftUI
import SwiftData
import UIKit

struct ConfirmExpenseView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \PaymentMethod.label) private var paymentMethods: [PaymentMethod]

    @State private var draft: ExpenseDraft
    let images: [UIImage]
    var onSaved: () -> Void

    @State private var vendorName: String
    @State private var amountText: String
    @State private var currencyCode: String
    @State private var selectedCategory: Category?
    @State private var selectedPaymentMethod: PaymentMethod?

    init(draft: ExpenseDraft, images: [UIImage], onSaved: @escaping () -> Void) {
        _draft = State(initialValue: draft)
        self.images = images
        self.onSaved = onSaved
        _vendorName = State(initialValue: draft.vendorName)
        _amountText = State(initialValue: NSDecimalNumber(decimal: draft.amount).stringValue)
        _currencyCode = State(initialValue: draft.currencyCode)
    }

    var body: some View {
        Form {
            Section("Vendor") {
                TextField("Vendor", text: $vendorName)
            }
            Section("Amount") {
                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)
                Picker("Currency", selection: $currencyCode) {
                    ForEach(["USD", "GBP", "EUR", "JPY", "CAD", "AUD"], id: \.self) { code in
                        Text(code)
                    }
                }
            }
            Section("Category") {
                Picker("Category", selection: $selectedCategory) {
                    Text("Uncategorized").tag(Optional<Category>.none)
                    ForEach(categories) { category in
                        Text(category.name).tag(Optional(category))
                    }
                }
            }
            Section("Paid with") {
                Picker("Payment method", selection: $selectedPaymentMethod) {
                    Text("Cash").tag(Optional<PaymentMethod>.none)
                    ForEach(paymentMethods) { method in
                        Text(method.label).tag(Optional(method))
                    }
                }
            }
        }
        .navigationTitle("Confirm")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Looks right") { save() }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onSaved() }
            }
        }
    }

    private func save() {
        let vendor = Vendor(displayName: vendorName, defaultCurrency: currencyCode)
        context.insert(vendor)

        let amount = Decimal(string: amountText) ?? 0
        let expense = Expense(
            vendor: vendor,
            paymentMethod: selectedPaymentMethod,
            originalCurrency: currencyCode,
            originalAmount: amount,
            exchangeRateToHome: 1,
            homeCurrency: "USD",
            hasReceipt: !images.isEmpty
        )
        if let selectedCategory {
            let item = LineItem(itemDescription: vendorName, unitPrice: amount, lineTotal: amount, category: selectedCategory)
            expense.items = [item]
        }
        expense.photos = images.compactMap { ReceiptStore.save($0) }
        context.insert(expense)
        try? context.save()
        onSaved()
    }
}
