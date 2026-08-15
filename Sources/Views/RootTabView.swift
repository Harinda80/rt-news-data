import SwiftUI

struct RootTabView: View {
    @State private var showingCapture = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(showingCapture: $showingCapture)
            }
            .tabItem { Label("Ledger", systemImage: "book.closed") }

            NavigationStack {
                SearchView()
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .fullScreenCover(isPresented: $showingCapture) {
            CaptureView(isPresented: $showingCapture)
        }
    }
}
