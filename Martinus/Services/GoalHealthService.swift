import Foundation
import SwiftData

// MARK: - GoalHealthService
/// PM artifact: implements the focus-recommendation heuristic (P1 bet) and
/// goal-health velocity computation (P3 bet).
///
/// All logic is pure / in-memory — no network, no ML model.
/// Kill metrics are observable via AnalyticsService.
struct GoalHealthService {

    // MARK: - Focus Recommendation (P1 Bet)

    /// Score a task for daily focus suitability. Higher = more recommended.
    /// Heuristic: explicit main focus > overdue high-priority > due today + high priority >
    ///            due today > at-risk goal task > high priority general
    static func focusScore(for task: FocusTask, goals: [Goal]) -> Double {
        guard !task.isCompleted, task.status != .cancelled, task.status != .irrelevant else {
            return -1
        }

        var score: Double = 0

        // Explicit main focus always wins
        if task.isMainFocus { return 1000 }

        // Overdue penalty flips to urgency boost
        if task.isOverdue { score += 50 }

        // Priority weight
        switch task.priority {
        case .high:   score += 30
        case .medium: score += 15
        case .low:    score += 5
        }

        // Due today
        if task.dueDate?.isToday == true { score += 25 }
        if task.scheduledDate?.isToday == true { score += 20 }

        // Goal health boost — if parent goal is at-risk or missed, its tasks become urgent
        if let goalID = task.goalID,
           let goal = goals.first(where: { $0.id == goalID }) {
            switch goal.healthStatus {
            case .missed:  score += 40
            case .atRisk:  score += 20
            default: break
            }
        }

        // Promise urgency
        if task.isPromise { score += 10 }

        // Rescheduled many times — either important or should be archived
        if task.rescheduleCount >= 3 { score += 8 }

        return score
    }

    /// Return the recommended main focus from a list of tasks.
    /// Respects an existing explicit main-focus selection.
    static func recommendedFocus(tasks: [FocusTask], goals: [Goal]) -> FocusTask? {
        if let explicit = tasks.first(where: { $0.isMainFocus && !$0.isCompleted }) {
            return explicit
        }
        return tasks
            .filter { !$0.isCompleted && $0.status != .cancelled && $0.status != .irrelevant }
            .max { focusScore(for: $0, goals: goals) < focusScore(for: $1, goals: goals) }
    }

    // MARK: - Progress Velocity Computation (P3 Bet)

    /// Update a goal's progressVelocity when its progress changes.
    /// Velocity = progress delta / weeks elapsed since last update.
    static func updateVelocity(for goal: Goal) {
        let now = Date()
        guard let lastDate = goal.lastProgressDate else {
            // First update — record the date, no velocity yet
            goal.lastProgressDate = now
            return
        }

        let weeksElapsed = max(
            0.0143, // floor at 15 min — prevents divide-by-zero on rapid edits
            Calendar.current.dateComponents([.minute], from: lastDate, to: now).minute.map { Double($0) / (60 * 24 * 7) } ?? 0.0143
        )

        let progressDelta = goal.progress - (goal.progressVelocity.map { $0 * weeksElapsed } ?? 0)
        let newVelocity   = max(0, progressDelta / weeksElapsed)

        // Smooth over previous velocity with an exponential moving average (α=0.4)
        if let prev = goal.progressVelocity {
            goal.progressVelocity = 0.4 * newVelocity + 0.6 * prev
        } else {
            goal.progressVelocity = newVelocity
        }

        goal.lastProgressDate = now
        goal.updatedAt        = now
    }

    // MARK: - Stale Goal Detection (PM insight: neglected-goal assistant card)

    /// Goals that haven't been updated in 7+ days and are below 20% progress.
    static func neglectedGoals(from goals: [Goal]) -> [Goal] {
        let threshold = Date().addingTimeInterval(-7 * 24 * 3600)
        return goals.filter {
            !$0.isCompleted && !$0.isArchived &&
            $0.progress < 0.2 &&
            $0.updatedAt < threshold
        }
    }

    // MARK: - Kill Metric Signals

    /// Returns the recommendation override rate for the past N sessions.
    /// Caller compares against the 60% threshold defined in the P1 kill metric.
    static func recommendationOverrideRate(events: [AnalyticsEvent]) -> Double {
        let shown     = events.filter { $0.name == "focus_recommendation_shown" }.count
        let overridden = events.filter { $0.name == "focus_recommendation_overridden" }.count
        guard shown > 0 else { return 0 }
        return Double(overridden) / Double(shown)
    }
}
