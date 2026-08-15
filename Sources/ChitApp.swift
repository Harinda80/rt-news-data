import SwiftUI
import SwiftData

@main
struct ChitApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
            LineItem.self,
            Vendor.self,
            Category.self,
            PaymentMethod.self,
            ReceiptPhoto.self,
            Tag.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create Chit's data store: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .modelContainer(sharedModelContainer)
                .task {
                    SampleData.seedIfNeeded(context: sharedModelContainer.mainContext)
                }
        }
    }
}
