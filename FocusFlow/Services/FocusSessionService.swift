import Foundation
import SwiftData

// MARK: - FocusSessionService
/// Manages the in-progress Pomodoro/deep-work focus timer.
@MainActor
final class FocusSessionService: ObservableObject {
    static let shared = FocusSessionService()

    @Published var isRunning:        Bool   = false
    @Published var isPaused:         Bool   = false
    @Published var remainingSeconds: Int    = 25 * 60
    @Published var totalSeconds:     Int    = 25 * 60
    @Published var sessionTitle:     String = "Deep Work"
    @Published var elapsedSeconds:   Int    = 0

    private var timer: Timer?
    private var startTime: Date?
    private var pauseTime: Date?

    // Current session context
    var currentTaskID: UUID?
    var currentGoalID: UUID?

    private init() {}

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var formattedRemaining: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    func start(minutes: Int = 25, title: String = "Deep Work", taskID: UUID? = nil, goalID: UUID? = nil) {
        totalSeconds     = minutes * 60
        remainingSeconds = totalSeconds
        elapsedSeconds   = 0
        sessionTitle     = title
        currentTaskID    = taskID
        currentGoalID    = goalID
        isRunning        = true
        isPaused         = false
        startTime        = Date()

        scheduleTimer()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused  = true
        pauseTime = Date()
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        scheduleTimer()
    }

    func stop() -> Int {
        let elapsed = elapsedSeconds
        resetState()
        return elapsed
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            handleSessionComplete()
            return
        }
        remainingSeconds -= 1
        elapsedSeconds   += 1
    }

    private func handleSessionComplete() {
        timer?.invalidate()
        timer        = nil
        isRunning    = false
        HapticManager.success()
        NotificationService.shared.removeNotifications(withPrefix: "focus-complete")
        postSessionCompleteNotification()
    }

    private func postSessionCompleteNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Session Complete 🎉"
        content.body  = "\(sessionTitle) — \(totalSeconds / 60) minutes done."
        content.sound = .defaultCritical

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "focus-complete-\(UUID())", content: content, trigger: trigger)

        Task {
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    private func resetState() {
        timer?.invalidate()
        timer            = nil
        isRunning        = false
        isPaused         = false
        remainingSeconds = 25 * 60
        totalSeconds     = 25 * 60
        elapsedSeconds   = 0
        startTime        = nil
        pauseTime        = nil
        currentTaskID    = nil
        currentGoalID    = nil
    }
}

// Needed for notification in service file
import UserNotifications
