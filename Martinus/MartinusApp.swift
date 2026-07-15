import SwiftUI
import SwiftData

@main
struct MartinusApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FocusTask.self,
            Goal.self,
            JournalEntry.self,
            Quote.self,
            FocusSessionRecord.self,
            UserProfile.self,
            AnalyticsEvent.self      // PM artifact: kill-metric tracking
        ])
        let config = ModelConfiguration("Martinus", schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task {
                    await appState.bootstrap(modelContext: sharedModelContainer.mainContext)
                }
                .onChange(of: scenePhase) { _, new in
                    if new == .active {
                        Task {
                            await appState.handleForeground(
                                modelContext: sharedModelContainer.mainContext
                            )
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
