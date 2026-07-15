import XCTest
@testable import FocusFlow

// MARK: - FocusTask Model Tests
final class ModelTests: XCTestCase {

    // MARK: - FocusTask

    func test_task_isOverdue_whenDueDateIsPastAndNotDone() {
        let task = FocusTask(title: "Overdue Task", dueDate: Date().addingTimeInterval(-3600))
        XCTAssertTrue(task.isOverdue)
    }

    func test_task_isNotOverdue_whenStatusIsDone() {
        let task = FocusTask(title: "Done Task", dueDate: Date().addingTimeInterval(-3600))
        task.status = .done
        XCTAssertFalse(task.isOverdue)
    }

    func test_task_isNotOverdue_whenNoDueDate() {
        let task = FocusTask(title: "No Due Date")
        XCTAssertFalse(task.isOverdue)
    }

    func test_task_isNotOverdue_whenFutureDueDate() {
        let task = FocusTask(title: "Future", dueDate: Date().addingTimeInterval(86400))
        XCTAssertFalse(task.isOverdue)
    }

    func test_task_isCompleted_whenStatusIsDone() {
        let task = FocusTask(title: "Done")
        task.status = .done
        XCTAssertTrue(task.isCompleted)
    }

    func test_task_isNotCompleted_byDefault() {
        let task = FocusTask(title: "New Task")
        XCTAssertFalse(task.isCompleted)
    }

    func test_task_defaultsAreCorrect() {
        let task = FocusTask(title: "Test")
        XCTAssertEqual(task.status, .todo)
        XCTAssertEqual(task.priority, .medium)
        XCTAssertFalse(task.isMainFocus)
        XCTAssertFalse(task.isPromise)
        XCTAssertEqual(task.rescheduleCount, 0)
        XCTAssertNotNil(task.id)
    }

    // MARK: - Goal

    func test_goal_defaultProgressIsZero() {
        let goal = Goal(title: "Launch App")
        XCTAssertEqual(goal.progress, 0.0, accuracy: 0.001)
    }

    func test_goal_daysUntilDeadline_withFutureDate() {
        let future = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let goal   = Goal(title: "Goal", targetDate: future)
        let days   = goal.daysUntilDeadline
        XCTAssertNotNil(days)
        XCTAssertEqual(days!, 5, accuracy: 0)
    }

    func test_goal_daysUntilDeadline_isNilWithNoTargetDate() {
        let goal = Goal(title: "Goal")
        XCTAssertNil(goal.daysUntilDeadline)
    }

    func test_goal_isNotCompletedByDefault() {
        let goal = Goal(title: "Goal")
        XCTAssertFalse(goal.isCompleted)
    }

    // MARK: - GoalMilestone

    func test_goalMilestones_encodeAndDecodeRoundtrip() {
        let goal = Goal(title: "With Milestones")
        let milestones = [
            GoalMilestone(title: "Step 1"),
            GoalMilestone(title: "Step 2", isCompleted: true)
        ]
        goal.milestones = milestones
        let decoded = goal.milestones
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].title, "Step 1")
        XCTAssertFalse(decoded[0].isCompleted)
        XCTAssertEqual(decoded[1].title, "Step 2")
        XCTAssertTrue(decoded[1].isCompleted)
    }

    // MARK: - JournalEntry

    func test_journalEntry_defaults() {
        let entry = JournalEntry()
        XCTAssertEqual(entry.mood, .neutral)
        XCTAssertEqual(entry.energy, .medium)
        XCTAssertEqual(entry.focus, 5)
        XCTAssertTrue(entry.tags.isEmpty)
    }

    // MARK: - Quote

    func test_quote_displayAuthor_whenFocusFlow() {
        let q = Quote(text: "Stay focused.", author: "", category: .focus, explanation: "Test", isFocusFlow: true)
        XCTAssertEqual(q.displayAuthor, "FocusFlow Guidance")
    }

    func test_quote_displayAuthor_whenRealAuthor() {
        let q = Quote(text: "Test quote.", author: "Jim Rohn", category: .discipline, explanation: "Test")
        XCTAssertEqual(q.displayAuthor, "Jim Rohn")
    }

    func test_quote_isFavoritedDefaultsFalse() {
        let q = Quote(text: "Test.", author: "Author", category: .motivation, explanation: "Explanation")
        XCTAssertFalse(q.isFavorited)
    }

    // MARK: - Priority

    func test_priority_sortOrder_highBeforeMediumBeforeLow() {
        XCTAssertLessThan(Priority.high.sortOrder,   Priority.medium.sortOrder)
        XCTAssertLessThan(Priority.medium.sortOrder, Priority.low.sortOrder)
    }

    // MARK: - Mood

    func test_mood_emojiNotEmpty() {
        for mood in Mood.allCases {
            XCTAssertFalse(mood.emoji.isEmpty, "Mood \(mood) has empty emoji")
        }
    }

    // MARK: - Date Extensions

    func test_date_startOfDay_isAtMidnight() {
        let now = Date()
        let start = now.startOfDay
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(components.hour,   0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func test_date_relativeString_today() {
        XCTAssertEqual(Date().relativeString, "Today")
    }

    func test_date_relativeString_tomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertEqual(tomorrow.relativeString, "Tomorrow")
    }

    func test_date_isSameDay() {
        let d1 = Date()
        let d2 = Calendar.current.date(byAdding: .hour, value: 2, to: d1)!
        XCTAssertTrue(d1.isSameDay(as: d2))
    }

    func test_date_daysUntil_positive() {
        let future = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        XCTAssertEqual(Date().daysUntil(future), 3)
    }

    // MARK: - Double Extensions

    func test_double_percentString() {
        XCTAssertEqual((0.75).percentString, "75%")
        XCTAssertEqual((1.0).percentString,  "100%")
        XCTAssertEqual((0.0).percentString,  "0%")
    }

    func test_double_clampedProgress() {
        XCTAssertEqual((-0.5).clampedProgress, 0.0, accuracy: 0.001)
        XCTAssertEqual((1.5).clampedProgress,  1.0, accuracy: 0.001)
        XCTAssertEqual((0.5).clampedProgress,  0.5, accuracy: 0.001)
    }

    // MARK: - String Extensions

    func test_string_isBlank_withOnlySpaces() {
        XCTAssertTrue("   ".isBlank)
    }

    func test_string_isBlank_emptyString() {
        XCTAssertTrue("".isBlank)
    }

    func test_string_isNotBlank() {
        XCTAssertFalse("hello".isBlank)
    }

    func test_string_trimmed() {
        XCTAssertEqual("  hello  ".trimmed, "hello")
    }
}
