import Foundation
import SwiftData

// MARK: - AnalyticsEvent (persisted locally — no network calls ever)
/// PM artifact: local kill-metric tracker for the 30/60/90-day bets.
/// All data stays on device. Used only for in-app kill-metric computation.
@Model
final class AnalyticsEvent {
    var id:        UUID
    var name:      String    // event name — see EventName constants below
    var date:      Date
    var metaJSON:  String    // JSON-encoded metadata (optional key-value pairs)

    init(name: String, meta: [String: String] = [:]) {
        self.id       = UUID()
        self.name     = name
        self.date     = Date()
        self.metaJSON = (try? String(data: JSONEncoder().encode(meta), encoding: .utf8)) ?? "{}"
    }
}

// MARK: - Event Name Constants
enum EventName {
    // P1 — Focus Recommendation (kill metric: override rate > 60% at day 21)
    static let focusRecommendationShown      = "focus_recommendation_shown"
    static let focusRecommendationAccepted   = "focus_recommendation_accepted"
    static let focusRecommendationOverridden = "focus_recommendation_overridden"

    // P2 — Promise Capture (kill metric: < 30% create a promise in 7 days)
    static let promiseCreated   = "promise_created"
    static let promiseCompleted = "promise_completed"
    static let promiseDismissed = "promise_dismissed"

    // P3 — Goal Health Signal (kill metric: no completion-rate lift at 30 days)
    static let goalHealthBadgeSeen   = "goal_health_badge_seen"
    static let goalAtRiskTaskStarted = "goal_at_risk_task_started"

    // P5 — Re-entry Flow (kill metric: < 40% complete a task in re-entry session)
    static let reentryFlowShown     = "reentry_flow_shown"
    static let reentryFlowCompleted = "reentry_flow_completed"   // user set a focus or completed a task
    static let reentryFlowDismissed = "reentry_flow_dismissed"

    // General engagement
    static let sessionStart   = "session_start"
    static let taskCompleted  = "task_completed"
    static let taskArchived   = "task_archived"
    static let journalCreated = "journal_created"
}

// MARK: - AnalyticsService
/// Lightweight local event recorder. No network. No third-party SDK.
/// Data is used exclusively to evaluate PM kill metrics in-app.
@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func record(_ name: String, meta: [String: String] = [:]) {
        guard let ctx = modelContext else { return }
        let event = AnalyticsEvent(name: name, meta: meta)
        ctx.insert(event)
        // Fire-and-forget; don't block the calling thread on save
        try? ctx.save()
    }

    // MARK: - Kill Metric Queries

    func events(named name: String, since date: Date) -> [AnalyticsEvent] {
        guard let ctx = modelContext else { return [] }
        let descriptor = FetchDescriptor<AnalyticsEvent>(
            predicate: #Predicate { $0.name == name && $0.date >= date }
        )
        return (try? ctx.fetch(descriptor)) ?? []
    }

    /// P1 kill metric: recommendation override rate over the past 21 days.
    func focusRecommendationOverrideRate() -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -21, to: Date()) ?? Date()
        let shown      = events(named: EventName.focusRecommendationShown,      since: cutoff).count
        let overridden = events(named: EventName.focusRecommendationOverridden,  since: cutoff).count
        guard shown > 0 else { return 0 }
        return Double(overridden) / Double(shown)
    }

    /// P2 kill metric: % of users who created a promise in first 7 days.
    /// (Approximated here as: did any promise event occur in last 7 days?)
    func promiseCreationRate7Days() -> Bool {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return !events(named: EventName.promiseCreated, since: cutoff).isEmpty
    }

    /// P5 kill metric: re-entry completion rate.
    func reentryCompletionRate() -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let shown     = events(named: EventName.reentryFlowShown,     since: cutoff).count
        let completed = events(named: EventName.reentryFlowCompleted, since: cutoff).count
        guard shown > 0 else { return 0 }
        return Double(completed) / Double(shown)
    }
}
