import SwiftUI
import SwiftData
import AppIntents

enum MartinusDataStore {
    static let shared: ModelContainer = {
        let schema = Schema([
            FocusTask.self,
            Goal.self,
            JournalEntry.self,
            Quote.self,
            FocusSessionRecord.self,
            UserProfile.self,
            AnalyticsEvent.self
        ])
        let config = ModelConfiguration("Martinus", schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

struct AddMartinusTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Add a Martinus Task"
    static let description = IntentDescription("Creates a task in Martinus using Siri.")
    static let openAppWhenRun = false

    @Parameter(title: "Task")
    var taskTitle: String

    @Parameter(title: "When should it happen?", description: "The date and time for the task")
    var scheduledDate: Date

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let cleanTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            return .result(dialog: "Please tell me the name of the task.")
        }

        let calendar = Calendar.current
        let repository = TaskRepository(modelContext: MartinusDataStore.shared.mainContext)
        let task = FocusTask(
            title: cleanTitle,
            scheduledDate: calendar.startOfDay(for: scheduledDate),
            scheduledTime: scheduledDate
        )
        repository.insert(task)
        try repository.save()

        return .result(dialog: "I added \(cleanTitle) to Martinus for \(scheduledDate.formatted(date: .abbreviated, time: .shortened)).")
    }
}

struct ScheduleMartinusEventIntent: AppIntent {
    static let title: LocalizedStringResource = "Schedule a Martinus Event"
    static let description = IntentDescription("Creates an event with a start and end time in Martinus.")
    static let openAppWhenRun = false

    @Parameter(title: "Event")
    var eventTitle: String

    @Parameter(title: "When does it start?")
    var startsAt: Date

    @Parameter(title: "When does it end?")
    var endsAt: Date

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let cleanTitle = eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            return .result(dialog: "Please tell me the name of the event.")
        }
        guard endsAt > startsAt else {
            return .result(dialog: "The end time must be after the start time. Please try again.")
        }

        let repository = TaskRepository(modelContext: MartinusDataStore.shared.mainContext)
        let event = FocusTask(
            title: cleanTitle,
            type: .event,
            scheduledDate: Calendar.current.startOfDay(for: startsAt),
            scheduledTime: startsAt,
            dueDate: endsAt
        )
        repository.insert(event)
        try repository.save()
        return .result(dialog: "I scheduled \(cleanTitle) from \(startsAt.formatted(date: .abbreviated, time: .shortened)) until \(endsAt.formatted(date: .omitted, time: .shortened)).")
    }
}

struct GetTodayMartinusTasksIntent: AppIntent {
    static let title: LocalizedStringResource = "Today's Martinus Tasks"
    static let description = IntentDescription("Reads the tasks that are scheduled for today in Martinus.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let repository = TaskRepository(modelContext: MartinusDataStore.shared.mainContext)
        let tasks = try repository.fetchTodayTasks().filter {
            $0.status != .done && $0.status != .cancelled && $0.status != .irrelevant
        }

        guard !tasks.isEmpty else {
            return .result(dialog: "You have no open tasks in Martinus today.")
        }

        let spokenTitles = tasks.prefix(5).map(\.title).joined(separator: ", ")
        if tasks.count > 5 {
            return .result(dialog: "You have \(tasks.count) open tasks today. The first five are: \(spokenTitles).")
        }
        return .result(dialog: "You have \(tasks.count) open tasks today: \(spokenTitles).")
    }
}

struct MartinusShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddMartinusTaskIntent(),
            phrases: [
                "Add a task to \(.applicationName)",
                "Create a task in \(.applicationName)",
                "Make a new task in \(.applicationName)",
                "Plan a task in \(.applicationName)",
                "Add something to \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "plus.circle.fill"
        )
        AppShortcut(
            intent: GetTodayMartinusTasksIntent(),
            phrases: [
                "What are my tasks in \(.applicationName)",
                "What do I have today in \(.applicationName)",
                "Show my tasks in \(.applicationName)",
                "Read my tasks from \(.applicationName)",
                "Do I have tasks today in \(.applicationName)"
            ],
            shortTitle: "Today's Tasks",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: ScheduleMartinusEventIntent(),
            phrases: [
                "Schedule an event in \(.applicationName)",
                "Add an event to \(.applicationName)",
                "Plan an appointment in \(.applicationName)"
            ],
            shortTitle: "Schedule Event",
            systemImageName: "calendar.badge.plus"
        )
    }
}

@main
struct MartinusApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer = MartinusDataStore.shared

    init() {
        MartinusShortcuts.updateAppShortcutParameters()
    }

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
