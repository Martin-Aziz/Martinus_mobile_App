import Foundation
import SwiftData

// MARK: - AssistantService
/// Analyzes the user's current data to produce contextual nudges and insights
/// shown on the Home screen assistant card.
struct AssistantService {

    // MARK: - Public API

    /// Generate the single most relevant insight for right now.
    static func generateInsight(
        tasks:   [FocusTask],
        goals:   [Goal],
        profile: UserProfile?
    ) -> DailyInsight? {
        let candidates = [
            findOverdueHighPriorityTask(tasks: tasks),
            findUpcomingDeadline(goals: goals),
            findPostponedTask(tasks: tasks),
            findNeglectedGoal(goals: goals),
            findSelfPromiseDue(tasks: tasks),
            findCelebration(tasks: tasks)
        ].compactMap { $0 }

        return candidates.first
    }

    /// Build the contextual greeting subtitle shown below the user's name.
    static func greetingSubtitle(tasks: [FocusTask], goals: [Goal]) -> String {
        let todayTasks = tasks.filter { task in
            guard !task.isCompleted else { return false }
            guard let d = task.scheduledDate else { return false }
            return d.isToday
        }

        let overdueTasks = tasks.filter { $0.isOverdue }

        if !overdueTasks.isEmpty {
            return "You have \(overdueTasks.count) overdue \(overdueTasks.count == 1 ? "item" : "items"). Let us clear the path."
        }

        if todayTasks.count > 5 {
            return "Today looks busy. Let us protect your focus."
        }

        if todayTasks.count == 0 {
            return "Your day is open. A great moment to move a goal forward."
        }

        let completed = tasks.filter { $0.isCompleted && $0.completedAt?.isToday == true }
        if completed.count >= 3 {
            return "You are making solid progress today."
        }

        return "One clear step is enough to begin."
    }

    /// Pick the recommended main focus task for today.
    static func recommendedMainFocus(tasks: [FocusTask], goals: [Goal]) -> FocusTask? {
        let eligible = tasks.filter {
            !$0.isCompleted &&
            $0.status != .cancelled &&
            ($0.scheduledDate?.isToday == true || $0.dueDate?.isToday == true || $0.priority == .high)
        }

        return eligible.sorted { lhs, rhs in
            // Sort by: explicit main focus > high priority > due today > created date
            if lhs.isMainFocus != rhs.isMainFocus { return lhs.isMainFocus }
            if lhs.priority.sortOrder != rhs.priority.sortOrder { return lhs.priority.sortOrder < rhs.priority.sortOrder }
            let lhsDue = lhs.dueDate ?? .distantFuture
            let rhsDue = rhs.dueDate ?? .distantFuture
            return lhsDue < rhsDue
        }.first
    }

    // MARK: - Private Generators

    private static func findOverdueHighPriorityTask(tasks: [FocusTask]) -> DailyInsight? {
        guard let task = tasks.first(where: { $0.isOverdue && $0.priority == .high }) else { return nil }
        return DailyInsight(
            type:    .overdueTask,
            message: "“\(task.title)” was due \(task.dueDate?.relativeString ?? "earlier"). It is still marked high priority.",
            actions: [
                InsightAction(label: "Start Now",         style: .primary),
                InsightAction(label: "Move to Tomorrow",  style: .secondary)
            ],
            taskID: task.id
        )
    }

    private static func findUpcomingDeadline(goals: [Goal]) -> DailyInsight? {
        let urgent = goals.filter { goal in
            guard !goal.isCompleted, let days = goal.daysUntilDeadline else { return false }
            return days >= 0 && days <= 3
        }.sorted { ($0.daysUntilDeadline ?? 999) < ($1.daysUntilDeadline ?? 999) }

        guard let goal = urgent.first, let days = goal.daysUntilDeadline else { return nil }
        let timeLabel = days == 0 ? "today" : days == 1 ? "tomorrow" : "in \(days) days"
        return DailyInsight(
            type:    .upcomingDeadline,
            message: "Your goal “\(goal.title)” has a deadline \(timeLabel). Consider protecting time for it.",
            actions: [
                InsightAction(label: "Schedule Time", style: .primary),
                InsightAction(label: "View Goal",     style: .secondary)
            ],
            goalID: goal.id
        )
    }

    private static func findPostponedTask(tasks: [FocusTask]) -> DailyInsight? {
        guard let task = tasks.first(where: { $0.rescheduleCount >= 2 && !$0.isCompleted }) else { return nil }
        return DailyInsight(
            type:    .postponedHabit,
            message: "You have moved “\(task.title)” \(task.rescheduleCount) times. Would you like to simplify or break it down?",
            actions: [
                InsightAction(label: "Start Anyway",    style: .primary),
                InsightAction(label: "Break It Down",   style: .secondary),
                InsightAction(label: "Mark Irrelevant", style: .destructive)
            ],
            taskID: task.id
        )
    }

    private static func findNeglectedGoal(goals: [Goal]) -> DailyInsight? {
        // A goal is neglected if it has not been updated in 7+ days and is < 20% progress
        let threshold = Date().addingTimeInterval(-7 * 24 * 3600)
        guard let goal = goals.first(where: {
            !$0.isCompleted && $0.progress < 0.2 && $0.updatedAt < threshold
        }) else { return nil }

        return DailyInsight(
            type:    .goalNeglected,
            message: "Your “\(goal.title)” goal has not received attention this week. Even one small step matters.",
            actions: [
                InsightAction(label: "Add a Step", style: .primary),
                InsightAction(label: "View Goal",  style: .secondary)
            ],
            goalID: goal.id
        )
    }

    private static func findSelfPromiseDue(tasks: [FocusTask]) -> DailyInsight? {
        let promises = tasks.filter {
            $0.isPromise && !$0.isCompleted &&
            ($0.scheduledDate?.isToday == true || $0.dueDate?.isToday == true)
        }
        guard let promise = promises.first else { return nil }
        return DailyInsight(
            type:    .selfPromise,
            message: promise.originalStatement ?? "You planned to \(promise.title.lowercased()) today.",
            actions: [
                InsightAction(label: "Start",             style: .primary),
                InsightAction(label: "Remind Me Later",   style: .secondary),
                InsightAction(label: "Move to Tomorrow",  style: .secondary)
            ],
            taskID: promise.id
        )
    }

    private static func findCelebration(tasks: [FocusTask]) -> DailyInsight? {
        let completedToday = tasks.filter { $0.isCompleted && $0.completedAt?.isToday == true }
        guard completedToday.count >= 3 else { return nil }
        return DailyInsight(
            type:    .celebration,
            message: "You have completed \(completedToday.count) tasks today. That is real momentum.",
            actions: [
                InsightAction(label: "Keep Going", style: .primary)
            ]
        )
    }
}
