import Foundation
@preconcurrency import UserNotifications
import SwiftData

// MARK: - NotificationService
/// Manages all local push notifications for tasks, reminders, promises, and daily reviews.
@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    @Published var isAuthorized = false

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Task Reminders

    func scheduleTaskReminder(for task: FocusTask) async -> String? {
        guard isAuthorized else { return nil }

        // Use scheduledTime if set, otherwise skip
        guard let reminderDate = task.scheduledTime ?? task.dueDate else { return nil }
        guard reminderDate > Date() else { return nil }

        let id = "task-\(task.id.uuidString)"

        let content = UNMutableNotificationContent()
        content.title = task.isPromise ? "You promised yourself:" : "Reminder"
        content.body  = task.title
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskID": task.id.uuidString]

        if task.isPromise, let statement = task.originalStatement {
            content.body = statement
        }

        content.interruptionLevel = task.priority == .high ? .timeSensitive : .active

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try? await center.add(request)
        return id
    }

    func scheduleMorningBriefing(hour: Int, minute: Int) async {
        guard isAuthorized else { return }

        removeNotifications(withPrefix: "morning-briefing")

        let content = UNMutableNotificationContent()
        content.title = "Good morning ☀️"
        content.body  = "Your day is ready. See what matters most."
        content.sound = .default
        content.categoryIdentifier = "MORNING_BRIEFING"

        var components = DateComponents()
        components.hour   = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morning-briefing", content: content, trigger: trigger)

        try? await center.add(request)
    }

    func scheduleEveningReview(hour: Int, minute: Int) async {
        guard isAuthorized else { return }

        removeNotifications(withPrefix: "evening-review")

        let content = UNMutableNotificationContent()
        content.title = "Evening reflection 🌙"
        content.body  = "Take 2 minutes to review your day and set tomorrow's focus."
        content.sound = .default
        content.categoryIdentifier = "EVENING_REVIEW"

        var components = DateComponents()
        components.hour   = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "evening-review", content: content, trigger: trigger)

        try? await center.add(request)
    }

    func cancelNotifications(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func removeNotifications(withPrefix prefix: String) {
        let notificationCenter = center
        notificationCenter.getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix(prefix) }.map { $0.identifier }
            notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Action Categories
    func registerNotificationCategories() {
        let start   = UNNotificationAction(identifier: "START",    title: "Start Now",       options: .foreground)
        let done    = UNNotificationAction(identifier: "DONE",     title: "Mark Done",       options: [])
        let later   = UNNotificationAction(identifier: "LATER",    title: "In 30 Minutes",   options: [])
        let tomorrow = UNNotificationAction(identifier: "TOMORROW", title: "Move to Tomorrow", options: [])
        let skip    = UNNotificationAction(identifier: "SKIP",     title: "Skip",            options: .destructive)

        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [start, done, later, tomorrow, skip],
            intentIdentifiers: [],
            options: []
        )

        let morningCategory = UNNotificationCategory(
            identifier: "MORNING_BRIEFING",
            actions: [UNNotificationAction(identifier: "OPEN", title: "Open Martinus", options: .foreground)],
            intentIdentifiers: [],
            options: []
        )

        let eveningCategory = UNNotificationCategory(
            identifier: "EVENING_REVIEW",
            actions: [UNNotificationAction(identifier: "REVIEW", title: "Start Review", options: .foreground)],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([taskCategory, morningCategory, eveningCategory])
    }
}
