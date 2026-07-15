import XCTest
@testable import FocusFlow

// MARK: - AssistantService Tests
final class AssistantServiceTests: XCTestCase {

    // MARK: - greetingSubtitle

    func test_greetingSubtitle_noTasks_returnsOpenDay() {
        let subtitle = AssistantService.greetingSubtitle(tasks: [], goals: [])
        XCTAssertTrue(
            subtitle.contains("open") || subtitle.contains("clear"),
            "Expected open-day message for empty task list, got: \(subtitle)"
        )
    }

    func test_greetingSubtitle_withOverdueTasks_mentionsOverdue() {
        let overdueTask = makeTask(dueDate: Date().addingTimeInterval(-86400), status: .todo)
        let subtitle = AssistantService.greetingSubtitle(tasks: [overdueTask], goals: [])
        XCTAssertTrue(subtitle.contains("overdue"), "Expected overdue mention, got: \(subtitle)")
    }

    func test_greetingSubtitle_manyCompletedToday_returnsProgress() {
        let tasks = (0..<4).map { _ -> FocusTask in
            let t = makeTask()
            t.status      = .done
            t.completedAt = Date()
            return t
        }
        let subtitle = AssistantService.greetingSubtitle(tasks: tasks, goals: [])
        XCTAssertTrue(
            subtitle.contains("progress") || subtitle.contains("solid"),
            "Expected progress message, got: \(subtitle)"
        )
    }

    // MARK: - generateInsight

    func test_generateInsight_overdueHighPriority_returnsOverdueInsight() {
        let task = makeTask(priority: .high, dueDate: Date().addingTimeInterval(-3600), status: .todo)
        let insight = AssistantService.generateInsight(tasks: [task], goals: [], profile: nil)
        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.type, .overdueTask)
        XCTAssertEqual(insight?.taskID, task.id)
    }

    func test_generateInsight_noData_returnsNil() {
        let insight = AssistantService.generateInsight(tasks: [], goals: [], profile: nil)
        XCTAssertNil(insight)
    }

    func test_generateInsight_celebration_threeCompletedToday() {
        let tasks = (0..<3).map { _ -> FocusTask in
            let t = makeTask()
            t.status      = .done
            t.completedAt = Date()
            return t
        }
        let insight = AssistantService.generateInsight(tasks: tasks, goals: [], profile: nil)
        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.type, .celebration)
    }

    func test_generateInsight_selfPromiseDueToday() {
        let task = makeTask(scheduledDate: Date(), isPromise: true)
        let insight = AssistantService.generateInsight(tasks: [task], goals: [], profile: nil)
        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.type, .selfPromise)
    }

    // MARK: - recommendedMainFocus

    func test_recommendedMainFocus_picksExplicitMainFocusFirst() {
        let t1 = makeTask(priority: .high)
        let t2 = makeTask(priority: .medium)
        t2.isMainFocus  = true
        t2.scheduledDate = Date()
        let result = AssistantService.recommendedMainFocus(tasks: [t1, t2], goals: [])
        XCTAssertEqual(result?.id, t2.id)
    }

    func test_recommendedMainFocus_picksHighPriorityWhenNoMainFocusSet() {
        let low  = makeTask(priority: .low, scheduledDate: Date())
        let high = makeTask(priority: .high, scheduledDate: Date())
        let result = AssistantService.recommendedMainFocus(tasks: [low, high], goals: [])
        XCTAssertEqual(result?.id, high.id)
    }

    func test_recommendedMainFocus_completedTasksExcluded() {
        let done = makeTask(priority: .high, scheduledDate: Date())
        done.status = .done
        let result = AssistantService.recommendedMainFocus(tasks: [done], goals: [])
        XCTAssertNil(result)
    }

    // MARK: - Helpers

    private func makeTask(
        priority:      Priority  = .medium,
        dueDate:       Date?     = nil,
        scheduledDate: Date?     = nil,
        status:        TaskStatus = .todo,
        isPromise:     Bool      = false
    ) -> FocusTask {
        let task = FocusTask(
            title:         "Test Task",
            priority:      priority,
            scheduledDate: scheduledDate,
            dueDate:       dueDate,
            isPromise:     isPromise
        )
        task.status = status
        return task
    }
}
