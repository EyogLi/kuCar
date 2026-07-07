import SwiftUI
import SwiftData

@main
struct kuCarApp: App {
    @StateObject private var appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appContainer)
        }
        .modelContainer(appContainer.modelContainer)
    }
}
