import SwiftUI
import UIKit

struct ExpenseDetailView: View {
    let expense: Expense

    private var firstPhotoImage: UIImage? {
        guard let photo = expense.photos.first else { return nil }
        let url = ReceiptStore.receiptsDirectory().appendingPathComponent(photo.workingFileName)
        return UIImage(contentsOfFile: url.path)
    }

    var body: some View {
        List {
            if let firstPhotoImage {
                Section {
                    Image(uiImage: firstPhotoImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(CurrencyFormat.string(expense.originalAmount, currencyCode: expense.originalCurrency))
                        .font(.system(.title, design: .serif))
                        .fontWeight(.semibold)
                    if expense.originalCurrency != expense.homeCurrency {
                        Text("≈ " + CurrencyFormat.string(expense.homeAmount, currencyCode: expense.homeCurrency))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !expense.items.isEmpty {
                Section("Items") {
                    ForEach(expense.items) { item in
                        HStack {
                            Text(item.itemDescription)
                            Spacer()
                            Text(CurrencyFormat.string(item.lineTotal, currencyCode: expense.originalCurrency))
                                .monospacedDigit()
                        }
                    }
                }
            }

            Section("Details") {
                LabeledContent("Vendor", value: expense.vendor?.displayName ?? "Unknown")
                LabeledContent("Paid with", value: expense.paymentMethod?.label ?? "Cash")
                LabeledContent("Date", value: expense.dateTime.formatted(date: .abbreviated, time: .shortened))
                if !expense.hasReceipt {
                    Label("No receipt attached", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle(expense.vendor?.displayName ?? "Expense")
    }
}
