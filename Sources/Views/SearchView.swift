import SwiftUI
import SwiftData

struct SearchView: View {
    @Query(sort: \Expense.dateTime, order: .reverse) private var expenses: [Expense]
    @State private var query = ""

    private var results: [Expense] {
        let active = expenses.filter { $0.deletedAt == nil }
        guard !query.isEmpty else { return active }
        return active.filter { expense in
            (expense.vendor?.displayName.localizedCaseInsensitiveContains(query) ?? false) ||
            expense.notes.localizedCaseInsensitiveContains(query) ||
            expense.items.contains { $0.itemDescription.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        List(results) { expense in
            NavigationLink(value: expense) {
                ExpenseRow(expense: expense)
            }
        }
        .navigationDestination(for: Expense.self) { ExpenseDetailView(expense: $0) }
        .searchable(text: $query, prompt: "Search vendors, items, notes")
        .navigationTitle("Search")
    }
}
