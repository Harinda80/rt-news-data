import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var paymentMethods: [PaymentMethod]
    @Query private var categories: [Category]
    @AppStorage("homeCurrency") private var homeCurrency = "USD"
    @AppStorage("faceIDLockEnabled") private var faceIDLockEnabled = true

    var body: some View {
        Form {
            Section("Currencies") {
                Picker("Home currency", selection: $homeCurrency) {
                    ForEach(["USD", "GBP", "EUR", "JPY", "CAD", "AUD"], id: \.self) { code in
                        Text(code)
                    }
                }
            }
            Section("Payment methods") {
                ForEach(paymentMethods) { method in
                    Text(method.label)
                }
            }
            Section("Categories") {
                Text("\(categories.count) categories")
                    .foregroundStyle(.secondary)
            }
            Section("Security") {
                Toggle("Face ID lock", isOn: $faceIDLockEnabled)
            }
            Section("Data & Privacy") {
                Text("Nothing leaves your phone except daily exchange-rate lookups.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}
