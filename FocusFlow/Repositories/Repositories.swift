import Foundation
import SwiftData

// MARK: - TaskRepository
/// Abstracts all SwiftData operations for FocusTask.
@MainActor
final class TaskRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch

    func fetchAll() throws -> [FocusTask] {
        let descriptor = FetchDescriptor<FocusTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchForDate(_ date: Date) throws -> [FocusTask] {
        let start = date.startOfDay
        let end   = date.endOfDay
        let descriptor = FetchDescriptor<FocusTask>(
            predicate: #Predicate { task in
                if let scheduled = task.scheduledDate {
                    return scheduled >= start && scheduled <= end
                } else if let due = task.dueDate {
                    return due >= start && due <= end
                } else {
                    return false
                }
            },
            sortBy: [SortDescriptor(\.scheduledTime)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchTodayTasks() throws -> [FocusTask] {
        try fetchForDate(Date())
    }

    func fetchOverdue() throws -> [FocusTask] {
        let now = Date()
        // SwiftData #Predicate cannot compare the custom TaskStatus enum, so filter in memory.
        // Data volume for a single user is trivial.
        return try fetchAll().filter { task in
            guard let due = task.dueDate else { return false }
            return due < now && task.status != .done && task.status != .cancelled
        }
    }

    func fetchByGoal(goalID: UUID) throws -> [FocusTask] {
        let descriptor = FetchDescriptor<FocusTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).filter { $0.goalID == goalID }
    }

    func fetchMainFocus() throws -> FocusTask? {
        try fetchAll().first { $0.isMainFocus && $0.status != .done }
    }

    // MARK: - Create / Update / Delete

    func insert(_ task: FocusTask) {
        modelContext.insert(task)
    }

    func markComplete(_ task: FocusTask) {
        task.status      = .done
        task.completedAt = Date()
        task.updatedAt   = Date()
    }

    func reschedule(_ task: FocusTask, to date: Date) {
        task.scheduledDate   = date
        task.dueDate         = date
        task.rescheduleCount += 1
        task.updatedAt       = Date()
    }

    func setMainFocus(_ task: FocusTask) throws {
        // Clear existing main focus first
        let all = try fetchAll()
        all.filter { $0.isMainFocus }.forEach { $0.isMainFocus = false; $0.updatedAt = Date() }
        task.isMainFocus = true
        task.updatedAt   = Date()
    }

    func delete(_ task: FocusTask) {
        modelContext.delete(task)
    }

    func save() throws {
        try modelContext.save()
    }
}

// MARK: - GoalRepository
@MainActor
final class GoalRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchActive() throws -> [Goal] {
        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { $0.isActive && !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAll() throws -> [Goal] {
        let descriptor = FetchDescriptor<Goal>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchByCategory(_ category: GoalCategory) throws -> [Goal] {
        try fetchAll().filter { $0.category == category }
    }

    func insert(_ goal: Goal) {
        modelContext.insert(goal)
    }

    func updateProgress(_ goal: Goal, progress: Double) {
        goal.progress  = min(max(progress, 0), 1)
        goal.updatedAt = Date()
        if goal.progress >= 1.0 { goal.completedAt = Date() }
        // PM artifact P3: compute velocity for goal-health signal
        GoalHealthService.updateVelocity(for: goal)
    }

    func archive(_ goal: Goal) {
        goal.isArchived = true
        goal.isActive   = false
        goal.updatedAt  = Date()
    }

    func delete(_ goal: Goal) {
        modelContext.delete(goal)
    }

    func save() throws {
        try modelContext.save()
    }
}

// MARK: - JournalRepository
@MainActor
final class JournalRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchForDate(_ date: Date) throws -> JournalEntry? {
        let start = date.startOfDay
        let end   = date.endOfDay
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.date >= start && $0.date <= end }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchRecent(limit: Int) throws -> [JournalEntry] {
        var descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func averageMood(lastDays: Int) throws -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -lastDays, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.date >= cutoff }
        )
        let entries = try modelContext.fetch(descriptor)
        guard !entries.isEmpty else { return 0 }
        let total = entries.reduce(0) { $0 + $1.mood.rawValue }
        return Double(total) / Double(entries.count)
    }

    func insert(_ entry: JournalEntry) {
        modelContext.insert(entry)
    }

    func delete(_ entry: JournalEntry) {
        modelContext.delete(entry)
    }

    func save() throws {
        try modelContext.save()
    }
}

// MARK: - QuoteRepository
@MainActor
final class QuoteRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchFavorites() throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { $0.isFavorited }
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchByCategory(_ category: QuoteCategory) throws -> [Quote] {
        try fetchAll().filter { $0.category == category }
    }

    func fetchDailyQuote(for date: Date) throws -> Quote? {
        let all = try fetchAll()
        guard !all.isEmpty else { return nil }
        // Deterministic pick based on day-of-year so it changes daily
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return all[dayOfYear % all.count]
    }

    func toggleFavorite(_ quote: Quote) {
        quote.isFavorited.toggle()
    }

    func insert(_ quote: Quote) {
        modelContext.insert(quote)
    }

    func count() throws -> Int {
        let descriptor = FetchDescriptor<Quote>()
        return try modelContext.fetchCount(descriptor)
    }

    func save() throws {
        try modelContext.save()
    }
}

// MARK: - UserProfileRepository
@MainActor
final class UserProfileRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchOrCreate() throws -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let profile = UserProfile()
        modelContext.insert(profile)
        try modelContext.save()
        return profile
    }

    func save() throws {
        try modelContext.save()
    }
}
