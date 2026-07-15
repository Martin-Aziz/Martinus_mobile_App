import SwiftUI
import SwiftData
import UserNotifications

// MARK: - AppState (global observable state)
@MainActor
@Observable
final class AppState {
    // Navigation
    var selectedTab: AppTab = .home
    var showAddTask      = false
    var showAddGoal      = false
    var showAddJournal   = false
    var showFocusSession = false
    var showOnboarding   = false
    /// PM artifact P5: re-entry flow after 7+ days absence
    var showReentry      = false
    var reentryAbsenceDays  = 0
    var reentryOverdueCount = 0
    var reentryAtRiskGoals: [Goal] = []

    // User profile (loaded on launch)
    var userProfile: UserProfile?

    // Repositories (injected)
    var taskRepo:    TaskRepository!
    var goalRepo:    GoalRepository!
    var journalRepo: JournalRepository!
    var quoteRepo:   QuoteRepository!
    var profileRepo: UserProfileRepository!

    // Services
    let notifications = NotificationService.shared
    let calendar      = CalendarService.shared
    let focusSession  = FocusSessionService.shared
    let analytics     = AnalyticsService.shared

    // Quick stats cache (refreshed on foreground)
    var todayTaskCount:    Int    = 0
    var completedToday:    Int    = 0
    var currentStreak:     Int    = 0

    func bootstrap(modelContext: ModelContext) async {
        taskRepo    = TaskRepository(modelContext: modelContext)
        goalRepo    = GoalRepository(modelContext: modelContext)
        journalRepo = JournalRepository(modelContext: modelContext)
        quoteRepo   = QuoteRepository(modelContext: modelContext)
        profileRepo = UserProfileRepository(modelContext: modelContext)

        analytics.configure(modelContext: modelContext)

        userProfile = try? profileRepo.fetchOrCreate()
        showOnboarding = userProfile?.onboardingDone == false

        await notifications.checkAuthorizationStatus()
        calendar.checkAuthorizationStatus()
        notifications.registerNotificationCategories()

        // Seed quotes if first launch
        let quoteCount = (try? quoteRepo.count()) ?? 0
        if quoteCount == 0 {
            QuotesSeed.seed(into: modelContext)
            try? quoteRepo.save()
        }

        analytics.record(EventName.sessionStart)
        await refreshStats(modelContext: modelContext)
        checkReentryFlow()
    }

    /// Call every time the app comes to foreground.
    func handleForeground(modelContext: ModelContext) async {
        userProfile?.recordAppOpen()
        try? profileRepo.save()
        await refreshStats(modelContext: modelContext)
        checkReentryFlow()
    }

    func refreshStats(modelContext: ModelContext) async {
        let today = (try? taskRepo.fetchTodayTasks()) ?? []
        todayTaskCount = today.count
        completedToday = today.filter { $0.isCompleted }.count
        currentStreak  = userProfile?.currentStreakDays ?? 0
    }

    // MARK: - Re-entry Flow (P5 bet)

    private func checkReentryFlow() {
        guard userProfile?.onboardingDone == true else { return }
        guard userProfile?.shouldShowReentryFlow == true else { return }

        let absenceDays   = userProfile?.consecutiveAbsenceDays ?? 0
        let overdueTasks  = (try? taskRepo.fetchOverdue()) ?? []
        let activeGoals   = (try? goalRepo.fetchActive()) ?? []
        let atRisk        = activeGoals.filter { $0.healthStatus == .atRisk || $0.healthStatus == .missed }

        reentryAbsenceDays  = absenceDays
        reentryOverdueCount = overdueTasks.count
        reentryAtRiskGoals  = Array(atRisk.prefix(2))
        showReentry         = true
    }
}

// MARK: - AppTab
enum AppTab: Int, CaseIterable {
    case home    = 0
    case today   = 1
    case goals   = 2
    case journal = 3
    case quotes  = 4
    case more    = 5

    var title: String {
        switch self {
        case .home:    return "Home"
        case .today:   return "Today"
        case .goals:   return "Goals"
        case .journal: return "Journal"
        case .quotes:  return "Quotes"
        case .more:    return "More"
        }
    }

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .today:   return "calendar"
        case .goals:   return "target"
        case .journal: return "book.fill"
        case .quotes:  return "quote.bubble.fill"
        case .more:    return "ellipsis"
        }
    }
}
