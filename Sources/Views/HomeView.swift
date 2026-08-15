import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var showingCapture: Bool
    @Query(sort: \Expense.dateTime, order: .reverse) private var expenses: [Expense]

    private var activeExpenses: [Expense] {
        expenses.filter { $0.deletedAt == nil }
    }

    private var groupedByDay: [(Date, [Expense])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: activeExpenses) { calendar.startOfDay(for: $0.dateTime) }
        return groups.sorted { $0.key > $1.key }
    }

    private var monthTotal: Decimal {
        let calendar = Calendar.current
        return activeExpenses
            .filter { calendar.isDate($0.dateTime, equalTo: .now, toGranularity: .month) }
            .reduce(Decimal(0)) { $0 + $1.homeAmount }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(CurrencyFormat.string(monthTotal, currencyCode: "USD"))
                        .font(.system(.largeTitle, design: .serif))
                        .fontWeight(.semibold)
                    Text("This month")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .listRowSeparator(.hidden)
            }

            ForEach(groupedByDay, id: \.0) { day, dayExpenses in
                Section(day.formatted(.dateTime.month(.abbreviated).day())) {
                    ForEach(dayExpenses) { expense in
                        NavigationLink(value: expense) {
                            ExpenseRow(expense: expense)
                        }
                    }
                }
            }
        }
        .navigationTitle("Ledger")
        .navigationDestination(for: Expense.self) { ExpenseDetailView(expense: $0) }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showingCapture = true
            } label: {
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(radius: 8, y: 4)
            }
            .padding(20)
        }
        .overlay {
            if activeExpenses.isEmpty {
                ContentUnavailableView(
                    "No expenses yet",
                    systemImage: "receipt",
                    description: Text("Tap the camera button to log your first purchase.")
                )
            }
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.vendor?.displayName ?? "Unknown vendor")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(expense.items.first?.category?.name ?? "Uncategorized")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormat.string(expense.originalAmount, currencyCode: expense.originalCurrency))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                if expense.originalCurrency != expense.homeCurrency {
                    Text("≈ " + CurrencyFormat.string(expense.homeAmount, currencyCode: expense.homeCurrency))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
