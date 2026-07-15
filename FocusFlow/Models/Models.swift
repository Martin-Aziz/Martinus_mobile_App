import Foundation
import SwiftData

// MARK: - Priority
enum Priority: String, Codable, CaseIterable, Identifiable {
    case high   = "high"
    case medium = "medium"
    case low    = "low"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .high:   return "High"
        case .medium: return "Medium"
        case .low:    return "Low"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high:   return 0
        case .medium: return 1
        case .low:    return 2
        }
    }
}

// MARK: - Task Type
enum TaskType: String, Codable, CaseIterable {
    case task       = "task"
    case reminder   = "reminder"
    case habit      = "habit"
    case event      = "event"
    case promise    = "promise"
    case focus      = "focus"
}

// MARK: - Task Status
enum TaskStatus: String, Codable, CaseIterable {
    case todo        = "todo"
    case inProgress  = "inProgress"
    case done        = "done"
    case skipped     = "skipped"
    case cancelled   = "cancelled"
    /// Deliberately retired — different from cancelled (no shame, just no longer relevant).
    case irrelevant  = "irrelevant"
}

// MARK: - Goal Health Status (PM artifact: P3 kill metric signal)
enum GoalHealthStatus: String, Codable {
    case onTrack   = "onTrack"   // velocity ≥ required rate
    case atRisk    = "atRisk"    // velocity < 50% of required rate for 2+ weeks
    case missed    = "missed"    // targetDate passed, progress < 1.0
    case noDeadline = "noDeadline" // no target date set — neutral

    var label: String {
        switch self {
        case .onTrack:    return "On Track"
        case .atRisk:     return "At Risk"
        case .missed:     return "Overdue"
        case .noDeadline: return "Active"
        }
    }

    var color: String {
        switch self {
        case .onTrack:    return "#22C55E"
        case .atRisk:     return "#F59E0B"
        case .missed:     return "#EF4444"
        case .noDeadline: return "#8C65FF"
        }
    }

    var icon: String {
        switch self {
        case .onTrack:    return "checkmark.circle.fill"
        case .atRisk:     return "exclamationmark.triangle.fill"
        case .missed:     return "xmark.circle.fill"
        case .noDeadline: return "circle.fill"
        }
    }
}

// MARK: - Goal Category
enum GoalCategory: String, Codable, CaseIterable, Identifiable {
    case startup    = "startup"
    case career     = "career"
    case health     = "health"
    case financial  = "financial"
    case personal   = "personal"
    case learning   = "learning"
    case family     = "family"
    case creative   = "creative"
    case travel     = "travel"
    case other      = "other"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .startup:   return "Startup"
        case .career:    return "Career"
        case .health:    return "Health"
        case .financial: return "Financial"
        case .personal:  return "Personal"
        case .learning:  return "Learning"
        case .family:    return "Family"
        case .creative:  return "Creative"
        case .travel:    return "Travel"
        case .other:     return "Other"
        }
    }

    var emoji: String {
        switch self {
        case .startup:   return "🚀"
        case .career:    return "💼"
        case .health:    return "💪"
        case .financial: return "💰"
        case .personal:  return "⭐"
        case .learning:  return "📚"
        case .family:    return "👨‍👩‍👧"
        case .creative:  return "🎨"
        case .travel:    return "✈️"
        case .other:     return "📌"
        }
    }
}

// MARK: - Mood
enum Mood: Int, Codable, CaseIterable, Identifiable {
    case terrible = 1
    case bad      = 2
    case neutral  = 3
    case good     = 4
    case great    = 5

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .terrible: return "😞"
        case .bad:      return "😕"
        case .neutral:  return "😐"
        case .good:     return "🙂"
        case .great:    return "😊"
        }
    }

    var label: String {
        switch self {
        case .terrible: return "Terrible"
        case .bad:      return "Bad"
        case .neutral:  return "Neutral"
        case .good:     return "Good"
        case .great:    return "Great"
        }
    }
}

// MARK: - Energy Level
enum EnergyLevel: Int, Codable, CaseIterable, Identifiable {
    case veryLow  = 1
    case low      = 2
    case medium   = 3
    case high     = 4
    case veryHigh = 5

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .veryLow:  return "Very Low"
        case .low:      return "Low"
        case .medium:   return "Medium"
        case .high:     return "High"
        case .veryHigh: return "Very High"
        }
    }
}

// MARK: - Quote Category
enum QuoteCategory: String, Codable, CaseIterable, Identifiable {
    case discipline     = "discipline"
    case courage        = "courage"
    case leadership     = "leadership"
    case stress         = "stress"
    case focus          = "focus"
    case consistency    = "consistency"
    case startups       = "startups"
    case failure        = "failure"
    case patience       = "patience"
    case health         = "health"
    case confidence     = "confidence"
    case decisions      = "decisions"
    case learning       = "learning"
    case resilience     = "resilience"
    case motivation     = "motivation"
    case success        = "success"
    case mindset        = "mindset"

    var id: String { rawValue }

    var label: String { rawValue.capitalized }
}

// MARK: - FocusTask
@Model
final class FocusTask {
    var id:            UUID
    var title:         String
    var notes:         String
    var type:          TaskType
    var status:        TaskStatus
    var priority:      Priority
    var isMainFocus:   Bool
    var scheduledDate: Date?
    var scheduledTime: Date?
    var dueDate:       Date?
    var completedAt:   Date?
    var createdAt:     Date
    var updatedAt:     Date

    // Promise fields
    var isPromise:       Bool
    var promisedTo:      String?       // person name, nil = self-promise
    var originalStatement: String?
    var rescheduleCount: Int

    // Recurrence
    var isRecurring:       Bool
    var recurrenceRule:    String?     // simple daily/weekly/weekdays

    // Relationships (stored as IDs to avoid SwiftData relationship complexity)
    var goalID:       UUID?
    var notificationIDs: [String]

    init(
        title:         String,
        type:          TaskType    = .task,
        priority:      Priority    = .medium,
        scheduledDate: Date?       = nil,
        scheduledTime: Date?       = nil,
        dueDate:       Date?       = nil,
        goalID:        UUID?       = nil,
        isPromise:     Bool        = false,
        promisedTo:    String?     = nil,
        originalStatement: String? = nil,
        notes:         String      = ""
    ) {
        self.id               = UUID()
        self.title            = title
        self.notes            = notes
        self.type             = type
        self.status           = .todo
        self.priority         = priority
        self.isMainFocus      = false
        self.scheduledDate    = scheduledDate
        self.scheduledTime    = scheduledTime
        self.dueDate          = dueDate
        self.completedAt      = nil
        self.createdAt        = Date()
        self.updatedAt        = Date()
        self.isPromise        = isPromise
        self.promisedTo       = promisedTo
        self.originalStatement = originalStatement
        self.rescheduleCount  = 0
        self.isRecurring      = false
        self.recurrenceRule   = nil
        self.goalID           = goalID
        self.notificationIDs  = []
    }

    var isOverdue: Bool {
        guard status != .done, status != .cancelled else { return false }
        if let due = dueDate { return due < Date() }
        if let sched = scheduledDate { return sched < Date().startOfDay }
        return false
    }

    var isCompleted: Bool { status == .done }

    var displayDate: Date? { scheduledDate ?? dueDate }
}

// MARK: - Goal
@Model
final class Goal {
    var id:          UUID
    var title:       String
    var notes:       String
    var category:    GoalCategory
    var priority:    Priority
    var progress:    Double           // 0.0 – 1.0
    var targetValue: Double?          // e.g. target number
    var currentValue: Double?
    var unit:        String?          // e.g. "pages", "kg", "%"
    var startDate:   Date
    var targetDate:  Date?
    var completedAt: Date?
    var isArchived:  Bool
    var isActive:    Bool
    var createdAt:   Date
    var updatedAt:   Date
    var colorHex:    String           // accent color for goal card
    var emoji:       String

    // Milestones as encoded JSON strings for SwiftData compatibility
    var milestonesData: Data?

    init(
        title:       String,
        category:    GoalCategory = .personal,
        priority:    Priority     = .medium,
        targetDate:  Date?        = nil,
        targetValue: Double?      = nil,
        unit:        String?      = nil,
        notes:       String       = "",
        colorHex:    String       = "#8C65FF",
        emoji:       String       = "⭐"
    ) {
        self.id           = UUID()
        self.title        = title
        self.notes        = notes
        self.category     = category
        self.priority     = priority
        self.progress     = 0.0
        self.targetValue  = targetValue
        self.currentValue = 0
        self.unit         = unit
        self.startDate    = Date()
        self.targetDate   = targetDate
        self.completedAt  = nil
        self.isArchived   = false
        self.isActive     = true
        self.createdAt    = Date()
        self.updatedAt    = Date()
        self.colorHex     = colorHex
        self.emoji        = emoji
        self.milestonesData = nil
    }

    // PM artifact: progressVelocity — progress delta per week, computed on each update.
    // Used by GoalHealthService to derive goalHealthStatus.
    var progressVelocity: Double?       // progress points gained per week (0.0–1.0 scale)
    var lastProgressDate: Date?         // when progress was last updated (for velocity calc)

    var isCompleted: Bool { completedAt != nil }

    var daysUntilDeadline: Int? {
        guard let target = targetDate else { return nil }
        return Date().daysUntil(target)
    }

    /// Derived (not stored): computed from velocity, targetDate, and progress.
    var healthStatus: GoalHealthStatus {
        if isCompleted { return .onTrack }
        guard let target = targetDate else { return .noDeadline }
        if target < Date() && progress < 1.0 { return .missed }
        guard let velocity = progressVelocity else {
            // No velocity data yet — treat as on track until we have 2 weeks of data
            return .onTrack
        }
        let weeksLeft = max(1.0, Double(Date().daysUntil(target)) / 7.0)
        let requiredVelocity = (1.0 - progress) / weeksLeft
        if velocity >= requiredVelocity * 0.5 { return .onTrack }
        return .atRisk
    }
}

// MARK: - Goal Milestone (Codable, stored as JSON in Goal.milestonesData)
struct GoalMilestone: Codable, Identifiable {
    var id:          UUID = UUID()
    var title:       String
    var isCompleted: Bool = false
    var completedAt: Date?
    var sortOrder:   Int  = 0
}

extension Goal {
    var milestones: [GoalMilestone] {
        get {
            guard let data = milestonesData else { return [] }
            return (try? JSONDecoder().decode([GoalMilestone].self, from: data)) ?? []
        }
        set {
            milestonesData = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - JournalEntry
@Model
final class JournalEntry {
    var id:         UUID
    var body:       String
    var mood:       Mood
    var energy:     EnergyLevel
    var focus:      Int            // 1–10
    var wins:       String         // comma-separated or paragraph
    var intentions: String         // what I want tomorrow
    var gratitude:  String
    var tags:       [String]
    var date:       Date
    var createdAt:  Date
    var updatedAt:  Date
    var goalIDs:    [UUID]         // goals mentioned

    init(
        body:       String       = "",
        mood:       Mood         = .neutral,
        energy:     EnergyLevel  = .medium,
        focus:      Int          = 5,
        wins:       String       = "",
        intentions: String       = "",
        gratitude:  String       = "",
        tags:       [String]     = [],
        goalIDs:    [UUID]       = []
    ) {
        self.id         = UUID()
        self.body       = body
        self.mood       = mood
        self.energy     = energy
        self.focus      = focus
        self.wins       = wins
        self.intentions = intentions
        self.gratitude  = gratitude
        self.tags       = tags
        self.date       = Date()
        self.createdAt  = Date()
        self.updatedAt  = Date()
        self.goalIDs    = goalIDs
    }
}

// MARK: - Quote
@Model
final class Quote {
    var id:          UUID
    var text:        String
    var author:      String        // empty string = Martinus Guidance
    var source:      String?       // book title, speech, etc.
    var category:    QuoteCategory
    var explanation: String        // simple language explanation
    var isFavorited: Bool
    var isFocusFlow: Bool          // true = original FocusFlow guidance
    var createdAt:   Date

    init(
        text:        String,
        author:      String,
        category:    QuoteCategory,
        explanation: String,
        source:      String? = nil,
        isFocusFlow: Bool    = false
    ) {
        self.id          = UUID()
        self.text        = text
        self.author      = author
        self.source      = source
        self.category    = category
        self.explanation = explanation
        self.isFavorited = false
        self.isFocusFlow = isFocusFlow
        self.createdAt   = Date()
    }

    var displayAuthor: String {
        isFocusFlow ? "Martinus Guidance" : author
    }
}

// MARK: - FocusSession
@Model
final class FocusSessionRecord {
    var id:           UUID
    var taskID:       UUID?
    var goalID:       UUID?
    var title:        String
    var plannedMinutes: Int
    var actualMinutes:  Int
    var completedAt:  Date?
    var startedAt:    Date
    var musicTrack:   String?
    var notes:        String

    init(
        title:          String,
        plannedMinutes: Int    = 25,
        taskID:         UUID?  = nil,
        goalID:         UUID?  = nil,
        musicTrack:     String? = nil
    ) {
        self.id             = UUID()
        self.title          = title
        self.plannedMinutes = plannedMinutes
        self.actualMinutes  = 0
        self.taskID         = taskID
        self.goalID         = goalID
        self.startedAt      = Date()
        self.completedAt    = nil
        self.musicTrack     = musicTrack
        self.notes          = ""
    }

    var isCompleted: Bool { completedAt != nil }
}

// MARK: - UserProfile
@Model
final class UserProfile {
    var id:               UUID
    var name:             String
    var onboardingDone:   Bool
    var currentStreakDays: Int
    var longestStreakDays: Int
    var lastStreakDate:    Date?
    var dailyStartHour:   Int   // 0–23
    var dailyEndHour:     Int
    var morningReminderEnabled: Bool
    var morningReminderHour:    Int
    var morningReminderMinute:  Int
    var eveningReviewEnabled:   Bool
    var eveningReviewHour:      Int
    var eveningReviewMinute:    Int
    var preferDarkMode:         Bool
    var notificationsAuthorized: Bool
    var calendarAuthorized:      Bool
    // PM artifact: last-open tracking for re-entry flow trigger (P5 kill metric)
    var lastAppOpenDate: Date?
    var consecutiveAbsenceDays: Int  // updated each foreground event

    var createdAt:               Date

    init(name: String = "Friend") {
        self.id                      = UUID()
        self.name                    = name
        self.onboardingDone          = false
        self.currentStreakDays        = 0
        self.longestStreakDays        = 0
        self.lastStreakDate           = nil
        self.dailyStartHour           = 8
        self.dailyEndHour             = 22
        self.morningReminderEnabled   = true
        self.morningReminderHour      = 8
        self.morningReminderMinute    = 0
        self.eveningReviewEnabled     = true
        self.eveningReviewHour        = 21
        self.eveningReviewMinute      = 0
        self.preferDarkMode           = true
        self.notificationsAuthorized  = false
        self.calendarAuthorized       = false
        self.lastAppOpenDate          = nil
        self.consecutiveAbsenceDays   = 0
        self.createdAt                = Date()
    }

    /// Call on every foreground event. Updates absence counter and last-open date.
    func recordAppOpen() {
        let now = Date()
        if let last = lastAppOpenDate {
            let daysSince = Calendar.current.dateComponents([.day], from: last.startOfDay, to: now.startOfDay).day ?? 0
            consecutiveAbsenceDays = daysSince >= 1 ? daysSince : 0
        }
        lastAppOpenDate = now
    }

    /// True when user has been absent ≥ 7 days — triggers re-entry flow.
    var shouldShowReentryFlow: Bool {
        consecutiveAbsenceDays >= 7
    }
}

// MARK: - DailyInsight (for assistant card, transient — not persisted)
struct DailyInsight {
    enum InsightType {
        case overdueTask, upcomingDeadline, postponedHabit,
             goalNeglected, calendarBusy, selfPromise, celebration
    }

    var type:    InsightType
    var message: String
    var actions: [InsightAction]
    var taskID:  UUID?
    var goalID:  UUID?
}

struct InsightAction: Identifiable {
    var id    = UUID()
    var label: String
    var style: ActionStyle
    enum ActionStyle { case primary, secondary, destructive }
}
