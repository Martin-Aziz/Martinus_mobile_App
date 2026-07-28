import SwiftUI
import SwiftData

// MARK: - HomeViewModel
@MainActor
@Observable
final class HomeViewModel {
    var tasks:         [FocusTask] = []
    var goals:         [Goal]      = []
    var dailyQuote:    Quote?      = nil
    var insight:       DailyInsight? = nil
    var mainFocus:     FocusTask?  = nil
    var upcomingItems: [FocusTask] = []
    var isLoaded       = false
    var showChangeFocus = false
    var showAllUpcoming = false
    var motivationMoment: MotivationMoment?
    // PM artifact P1: was the recommendation accepted or overridden?
    var recommendationWasShown = false

    private var taskRepo:  TaskRepository?
    private var goalRepo:  GoalRepository?
    private var quoteRepo: QuoteRepository?
    private var analytics: AnalyticsService { AnalyticsService.shared }

    func load(
        taskRepo:  TaskRepository,
        goalRepo:  GoalRepository,
        quoteRepo: QuoteRepository,
        userName:  String = "there"
    ) async {
        self.taskRepo   = taskRepo
        self.goalRepo   = goalRepo
        self.quoteRepo  = quoteRepo
        self._userName  = userName
        await refresh()
    }

    func refresh() async {
        guard let taskRepo, let goalRepo, let quoteRepo else { return }
        tasks      = (try? taskRepo.fetchTodayTasks()) ?? []
        goals      = (try? goalRepo.fetchActive()) ?? []
        dailyQuote = try? quoteRepo.fetchDailyQuote(for: Date())

        // PM artifact P1: use GoalHealthService heuristic instead of naive sort
        let heuristicFocus = GoalHealthService.recommendedFocus(tasks: tasks, goals: goals)
        mainFocus = heuristicFocus

        if heuristicFocus != nil && !recommendationWasShown {
            analytics.record(EventName.focusRecommendationShown)
            recommendationWasShown = true
        }

        upcomingItems = tasks
            .filter { !$0.isCompleted && $0.status != .irrelevant }
            .prefix(6).map { $0 }
        insight = AssistantService.generateInsight(tasks: tasks, goals: goals, profile: nil)
        isLoaded = true
    }

    func markComplete(_ task: FocusTask) {
        taskRepo?.markComplete(task)
        analytics.record(EventName.taskCompleted)
        motivationMoment = AssistantService.motivation(for: .taskCompleted, taskTitle: task.title)
        HapticManager.success()
        Task { await refresh() }
    }

    func setMainFocus(_ task: FocusTask) {
        // User is manually overriding the heuristic recommendation — record for P1 kill metric
        if mainFocus?.id != task.id {
            analytics.record(EventName.focusRecommendationOverridden)
        }
        try? taskRepo?.setMainFocus(task)
        Task { await refresh() }
    }

    var focusCandidates: [FocusTask] {
        tasks.filter { !$0.isCompleted && $0.status != .irrelevant }
    }

    func focusProgress(for task: FocusTask) -> Double {
        switch task.status {
        case .done:       return 1
        case .inProgress: return 0.5
        default:          return 0
        }
    }

    /// PM artifact P6: archive a task (no-shame path for irrelevant items).
    func archiveTask(_ task: FocusTask) {
        task.status    = .irrelevant
        task.updatedAt = Date()
        analytics.record(EventName.taskArchived)
        HapticManager.medium()
        Task { await refresh() }
    }

    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning, \(_userName)"
        case 12..<17: return "Good afternoon, \(_userName)"
        default:      return "Good evening, \(_userName)"
        }
    }

    var greetingSubtitle: String {
        AssistantService.greetingSubtitle(tasks: tasks, goals: goals)
    }

    private var _userName: String = "there"
}
