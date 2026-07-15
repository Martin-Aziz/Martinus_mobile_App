import XCTest
import SwiftData
@testable import Martinus

// MARK: - HomeViewModel Tests
@MainActor
final class ViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext:   ModelContext!

    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([FocusTask.self, Goal.self, JournalEntry.self, Quote.self, UserProfile.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext   = modelContainer.mainContext
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext   = nil
        try await super.tearDown()
    }

    // MARK: - HomeViewModel

    func test_homeViewModel_load_populatesTasks() async throws {
        let taskRepo  = TaskRepository(modelContext: modelContext)
        let goalRepo  = GoalRepository(modelContext: modelContext)
        let quoteRepo = QuoteRepository(modelContext: modelContext)

        let task = FocusTask(title: "Today's Task", scheduledDate: Date())
        taskRepo.insert(task)
        try taskRepo.save()

        let vm = HomeViewModel()
        await vm.load(taskRepo: taskRepo, goalRepo: goalRepo, quoteRepo: quoteRepo)

        XCTAssertTrue(vm.isLoaded)
        XCTAssertFalse(vm.tasks.isEmpty)
    }

    func test_homeViewModel_markComplete_updatesTaskStatus() async throws {
        let taskRepo  = TaskRepository(modelContext: modelContext)
        let goalRepo  = GoalRepository(modelContext: modelContext)
        let quoteRepo = QuoteRepository(modelContext: modelContext)

        let task = FocusTask(title: "Complete Me", scheduledDate: Date())
        taskRepo.insert(task)
        try taskRepo.save()

        let vm = HomeViewModel()
        await vm.load(taskRepo: taskRepo, goalRepo: goalRepo, quoteRepo: quoteRepo)

        vm.markComplete(task)
        XCTAssertTrue(task.isCompleted)
        XCTAssertNotNil(task.completedAt)
    }

    func test_homeViewModel_greetingText_containsTimeOfDay() {
        let vm = HomeViewModel()
        let greeting = vm.greetingText
        let containsTimeWord = greeting.contains("morning") || greeting.contains("afternoon") || greeting.contains("evening")
        XCTAssertTrue(containsTimeWord, "Expected time-of-day greeting, got: \(greeting)")
    }

    // MARK: - TaskRepository

    func test_taskRepository_fetchTodayTasks_returnsOnlyToday() throws {
        let repo = TaskRepository(modelContext: modelContext)

        let today     = FocusTask(title: "Today",     scheduledDate: Date())
        let yesterday = FocusTask(title: "Yesterday", scheduledDate: Date().addingTimeInterval(-86400))

        repo.insert(today)
        repo.insert(yesterday)
        try repo.save()

        let results = try repo.fetchTodayTasks()
        XCTAssertTrue(results.contains(where: { $0.title == "Today" }))
        XCTAssertFalse(results.contains(where: { $0.title == "Yesterday" }))
    }

    func test_taskRepository_markComplete_setsStatusAndDate() throws {
        let repo = TaskRepository(modelContext: modelContext)
        let task = FocusTask(title: "Test")
        repo.insert(task)
        try repo.save()

        repo.markComplete(task)
        XCTAssertEqual(task.status, .done)
        XCTAssertNotNil(task.completedAt)
    }

    func test_taskRepository_reschedule_incrementsCount() throws {
        let repo     = TaskRepository(modelContext: modelContext)
        let task     = FocusTask(title: "Reschedule Me")
        repo.insert(task)
        try repo.save()

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        repo.reschedule(task, to: tomorrow)
        XCTAssertEqual(task.rescheduleCount, 1)
        XCTAssertEqual(task.scheduledDate?.startOfDay, tomorrow.startOfDay)
    }

    func test_taskRepository_setMainFocus_clearsOtherMainFocus() throws {
        let repo = TaskRepository(modelContext: modelContext)

        let t1 = FocusTask(title: "First",  scheduledDate: Date())
        let t2 = FocusTask(title: "Second", scheduledDate: Date())
        t1.isMainFocus = true
        repo.insert(t1)
        repo.insert(t2)
        try repo.save()

        try repo.setMainFocus(t2)
        XCTAssertFalse(t1.isMainFocus)
        XCTAssertTrue(t2.isMainFocus)
    }

    // MARK: - GoalRepository

    func test_goalRepository_fetchActive_excludesArchived() throws {
        let repo = GoalRepository(modelContext: modelContext)

        let active   = Goal(title: "Active Goal")
        let archived = Goal(title: "Archived Goal")
        archived.isArchived = true
        archived.isActive   = false
        repo.insert(active)
        repo.insert(archived)
        try repo.save()

        let results = try repo.fetchActive()
        XCTAssertTrue(results.contains(where:  { $0.title == "Active Goal" }))
        XCTAssertFalse(results.contains(where: { $0.title == "Archived Goal" }))
    }

    func test_goalRepository_updateProgress_clampsToOneHundredPercent() throws {
        let repo = GoalRepository(modelContext: modelContext)
        let goal = Goal(title: "Clamped Goal")
        repo.insert(goal)
        try repo.save()

        repo.updateProgress(goal, progress: 1.5)
        XCTAssertEqual(goal.progress, 1.0, accuracy: 0.001)
    }

    func test_goalRepository_updateProgress_setsCompletedAt_atHundredPercent() throws {
        let repo = GoalRepository(modelContext: modelContext)
        let goal = Goal(title: "Complete Goal")
        repo.insert(goal)
        try repo.save()

        repo.updateProgress(goal, progress: 1.0)
        XCTAssertNotNil(goal.completedAt)
    }

    // MARK: - QuoteRepository

    func test_quoteRepository_fetchDailyQuote_isDeterministicForSameDate() throws {
        let repo = QuoteRepository(modelContext: modelContext)
        for q in QuotesSeed.allQuotes { repo.insert(q) }
        try repo.save()

        let date = Date()
        let first  = try repo.fetchDailyQuote(for: date)
        let second = try repo.fetchDailyQuote(for: date)
        XCTAssertEqual(first?.id, second?.id)
    }

    func test_quoteRepository_toggleFavorite_alternates() throws {
        let repo  = QuoteRepository(modelContext: modelContext)
        let quote = QuotesSeed.allQuotes[0]
        repo.insert(quote)
        try repo.save()

        XCTAssertFalse(quote.isFavorited)
        repo.toggleFavorite(quote)
        XCTAssertTrue(quote.isFavorited)
        repo.toggleFavorite(quote)
        XCTAssertFalse(quote.isFavorited)
    }

    // MARK: - FocusSessionService

    func test_focusSession_formattedRemaining_correctFormat() {
        let session = FocusSessionService.shared
        session.start(minutes: 25, title: "Test")
        XCTAssertEqual(session.formattedRemaining, "25:00")
        _ = session.stop()
    }

    func test_focusSession_progress_zeroAtStart() {
        let session = FocusSessionService.shared
        session.start(minutes: 10, title: "Test")
        XCTAssertEqual(session.progress, 0.0, accuracy: 0.01)
        _ = session.stop()
    }

    func test_focusSession_isRunningAfterStart() {
        let session = FocusSessionService.shared
        session.start(minutes: 5, title: "Test")
        XCTAssertTrue(session.isRunning)
        _ = session.stop()
    }

    func test_focusSession_isPausedAfterPause() {
        let session = FocusSessionService.shared
        session.start(minutes: 5, title: "Test")
        session.pause()
        XCTAssertTrue(session.isPaused)
        _ = session.stop()
    }

    func test_focusSession_notRunningAfterStop() {
        let session = FocusSessionService.shared
        session.start(minutes: 5, title: "Test")
        _ = session.stop()
        XCTAssertFalse(session.isRunning)
    }
}
