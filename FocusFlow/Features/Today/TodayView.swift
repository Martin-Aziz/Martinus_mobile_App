import SwiftUI
import SwiftData

// MARK: - TodayViewModel
@MainActor
@Observable
final class TodayViewModel {
    var selectedDate:    Date          = Date()
    var tasks:           [FocusTask]   = []
    var goals:           [Goal]        = []          // PM artifact P3: needed for health badge
    var calendarEvents:  [CalendarEvent] = []
    var weekDates:       [Date]        = []
    var isLoaded         = false
    var showAddTask      = false
    var showEndOfDay     = false

    private var taskRepo: TaskRepository?
    private var goalRepo: GoalRepository?

    func load(taskRepo: TaskRepository, goalRepo: GoalRepository) async {
        self.taskRepo = taskRepo
        self.goalRepo = goalRepo
        buildWeekDates()
        await loadItems(for: selectedDate)
        isLoaded = true
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        Task { await loadItems(for: date) }
    }

    func advanceWeek(by offset: Int) {
        let newAnchor = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: weekDates.first ?? Date()) ?? Date()
        buildWeekDates(anchor: newAnchor)
        Task { await loadItems(for: selectedDate) }
    }

    func markComplete(_ task: FocusTask) {
        taskRepo?.markComplete(task)
        AnalyticsService.shared.record(EventName.taskCompleted)
        HapticManager.success()
        Task { await loadItems(for: selectedDate) }
    }

    func reschedule(_ task: FocusTask, to date: Date) {
        taskRepo?.reschedule(task, to: date)
        Task { await loadItems(for: selectedDate) }
    }

    /// PM artifact P6: no-shame archive — marks task as "no longer relevant".
    func archiveTask(_ task: FocusTask) {
        task.status    = .irrelevant
        task.updatedAt = Date()
        AnalyticsService.shared.record(EventName.taskArchived)
        try? taskRepo?.save()
        HapticManager.medium()
        Task { await loadItems(for: selectedDate) }
    }

    // MARK: - Computed

    var scheduledTasks: [FocusTask] {
        tasks
            .filter { $0.scheduledTime != nil && $0.status != .irrelevant }
            .sorted { ($0.scheduledTime ?? .distantFuture) < ($1.scheduledTime ?? .distantFuture) }
    }

    var unscheduledTasks: [FocusTask] {
        tasks.filter { $0.scheduledTime == nil && $0.status != .irrelevant }
    }

    var completionPercent: Double {
        let active = tasks.filter { $0.status != .irrelevant }
        guard !active.isEmpty else { return 0 }
        return Double(active.filter { $0.isCompleted }.count) / Double(active.count)
    }

    var isNearEndOfDay: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return selectedDate.isToday && hour >= 20
    }

    // MARK: - Private

    private func loadItems(for date: Date) async {
        tasks          = (try? taskRepo?.fetchForDate(date)) ?? []
        goals          = (try? goalRepo?.fetchActive()) ?? []
        calendarEvents = await CalendarService.shared.loadEvents(for: date)
    }

    private func buildWeekDates(anchor: Date = Date()) {
        let calendar = Calendar.current
        let weekday  = calendar.component(.weekday, from: anchor)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - calendar.firstWeekday), to: anchor.startOfDay) ?? anchor
        weekDates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
}

// MARK: - TodayView
struct TodayView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = TodayViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection
                    weekSelector
                    FFDivider()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Spacing.xl) {
                            if !viewModel.calendarEvents.isEmpty {
                                calendarEventsSection
                            }
                            scheduledSection
                            if !viewModel.unscheduledTasks.isEmpty {
                                unscheduledSection
                            }
                            if viewModel.isNearEndOfDay {
                                endOfDayCard
                            }
                        }
                        .padding(.horizontal, Spacing.base)
                        .padding(.top, Spacing.base)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .task { await viewModel.load(taskRepo: appState.taskRepo, goalRepo: appState.goalRepo) }
            .sheet(isPresented: $viewModel.showAddTask) { AddTaskView() }
            .sheet(isPresented: $viewModel.showEndOfDay) { EndOfDayView(viewModel: viewModel) }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today")
                    .font(.ffDisplay2)
                    .foregroundColor(.ffTextPrimary)
                Text(viewModel.selectedDate.isToday ? "Let's make it count." : viewModel.selectedDate.shortDateString)
                    .font(.ffBody)
                    .foregroundColor(.ffTextSecondary)
            }
            Spacer()
            HStack(spacing: Spacing.sm) {
                if !viewModel.selectedDate.isToday {
                    Button("Today") {
                        viewModel.selectDate(Date())
                    }
                    .font(.ffBodyMed)
                    .foregroundColor(.ffPrimary)
                }
                CircularIconButton("plus", action: { viewModel.showAddTask = true })
            }
        }
        .padding(.horizontal, Spacing.base)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Week Selector
    private var weekSelector: some View {
        HStack(spacing: 0) {
            Button(action: { viewModel.advanceWeek(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.ffTextSecondary)
                    .padding(Spacing.sm)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(viewModel.weekDates, id: \.self) { date in
                        WeekDayCell(
                            date:       date,
                            isSelected: date.isSameDay(as: viewModel.selectedDate),
                            isToday:    date.isToday,
                            onTap:      { viewModel.selectDate(date) }
                        )
                    }
                }
                .padding(.horizontal, Spacing.base)
            }
            Button(action: { viewModel.advanceWeek(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.ffTextSecondary)
                    .padding(Spacing.sm)
            }
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Calendar Events
    private var calendarEventsSection: some View {
        VStack(spacing: Spacing.sm) {
            SectionHeader(title: "Calendar")
            VStack(spacing: Spacing.xs) {
                ForEach(viewModel.calendarEvents) { event in
                    CalendarEventRow(event: event)
                }
            }
        }
    }

    // MARK: - Scheduled Tasks
    private var scheduledSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                SectionHeader(title: viewModel.selectedDate.isToday ? "Scheduled" : "Tasks")
                Spacer()
                if !viewModel.tasks.isEmpty {
                    ProgressView(value: viewModel.completionPercent)
                        .tint(.ffPrimary)
                        .frame(width: 80)
                }
            }
            if viewModel.tasks.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "All clear",
                    subtitle: "No tasks for this day.",
                    actionLabel: "Add Task",
                    onAction: { viewModel.showAddTask = true }
                )
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(viewModel.scheduledTasks) { task in
                        NavigationLink {
                            TaskDetailView(task: task, viewModel: viewModel)
                        } label: {
                            TimelineTaskRow(
                                task: task,
                                goals: viewModel.goals,
                                onComplete: { viewModel.markComplete(task) },
                                onArchive: { viewModel.archiveTask(task) }
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // PM artifact P6: no-shame archive — "no longer relevant"
                            Button {
                                viewModel.archiveTask(task)
                                HapticManager.medium()
                            } label: {
                                Label("No longer relevant", systemImage: "archivebox")
                            }
                            .tint(Color.ffNeutral)

                            Button {
                                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                                viewModel.reschedule(task, to: tomorrow)
                            } label: {
                                Label("Tomorrow", systemImage: "calendar.badge.clock")
                            }
                            .tint(Color.ffSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Unscheduled
    private var unscheduledSection: some View {
        VStack(spacing: Spacing.sm) {
            SectionHeader(title: "Unscheduled")
            VStack(spacing: Spacing.xs) {
                ForEach(viewModel.unscheduledTasks) { task in
                    NavigationLink {
                        TaskDetailView(task: task, viewModel: viewModel)
                    } label: {
                        TimelineTaskRow(
                            task: task,
                            goals: viewModel.goals,
                            onComplete: { viewModel.markComplete(task) },
                            onArchive: { viewModel.archiveTask(task) }
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            viewModel.archiveTask(task)
                        } label: {
                            Label("No longer relevant", systemImage: "archivebox")
                        }
                        .tint(Color.ffNeutral)
                    }
                }
            }
        }
    }

    private var endOfDayCard: some View {
        GlassCard(cornerRadius: Radius.lg) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(LinearGradient.ffBrand)
                Text("Evening Review")
                    .font(.ffHeadline3)
                    .foregroundColor(.ffTextPrimary)
                Text("Take 2 minutes to reflect on today and set tomorrow's direction.")
                    .font(.ffBody)
                    .foregroundColor(.ffTextSecondary)
                    .multilineTextAlignment(.center)
                FFButton("Start Review", action: { viewModel.showEndOfDay = true })
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - WeekDayCell
struct WeekDayCell: View {
    var date:       Date
    var isSelected: Bool
    var isToday:    Bool
    var onTap:      () -> Void

    var body: some View {
        Button(action: { HapticManager.selection(); onTap() }) {
            VStack(spacing: 4) {
                Text(date.weekdayShort)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white : .ffTextSecondary)
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(LinearGradient.ffBrand)
                            .frame(width: 36, height: 36)
                    } else if isToday {
                        Circle()
                            .stroke(Color.ffPrimary, lineWidth: 1.5)
                            .frame(width: 36, height: 36)
                    }
                    Text(date.dayNumber)
                        .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? .white : isToday ? .ffPrimary : .ffTextPrimary)
                }
            }
            .frame(width: 44)
        }
    }
}

// MARK: - TimelineTaskRow
struct TimelineTaskRow: View {
    var task:       FocusTask
    var goals:      [Goal]
    var onComplete: () -> Void
    var onArchive:  () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            if let time = task.scheduledTime {
                Text(time.timeString)
                    .font(.ffCaption)
                    .foregroundColor(.ffTextSecondary)
                    .frame(width: 52, alignment: .trailing)
            } else {
                Spacer().frame(width: 52)
            }

            // Priority stripe — doubles as goal-health colour when goal is at-risk
            Rectangle()
                .fill(stripeColor)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.ffBodyMed)
                    .foregroundColor(task.isCompleted ? .ffTextTertiary : .ffTextPrimary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: Spacing.xs) {
                    PriorityBadge(task.priority, compact: true)
                    // PM artifact P3: goal health badge on the task row
                    if let goalID = task.goalID,
                       let goal = goals.first(where: { $0.id == goalID }) {
                        goalHealthPill(for: goal)
                    }
                }
            }

            Spacer()

            CheckmarkButton(isChecked: task.isCompleted, color: stripeColor, onToggle: onComplete)
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.base)
        .background(task.isCompleted ? Color.ffSurface.opacity(0.4) : Color.ffSurfaceElevated.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
    }

    // Stripe is red/amber when the parent goal is at-risk/missed — visual urgency bump
    private var stripeColor: Color {
        if let goalID = task.goalID,
           let goal = goals.first(where: { $0.id == goalID }) {
            switch goal.healthStatus {
            case .missed:  return .ffDanger
            case .atRisk:  return .ffWarning
            default: break
            }
        }
        switch task.priority {
        case .high:   return .ffPriorityHigh
        case .medium: return .ffPriorityMedium
        case .low:    return .ffPriorityLow
        }
    }

    @ViewBuilder
    private func goalHealthPill(for goal: Goal) -> some View {
        switch goal.healthStatus {
        case .atRisk, .missed:
            HStack(spacing: 3) {
                Image(systemName: goal.healthStatus.icon)
                    .font(.system(size: 9))
                Text(goal.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(Color(hex: goal.healthStatus.color))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(hex: goal.healthStatus.color).opacity(0.15))
            .clipShape(Capsule())
            .onAppear {
                AnalyticsService.shared.record(EventName.goalHealthBadgeSeen,
                                               meta: ["goal_id": goal.id.uuidString,
                                                      "health": goal.healthStatus.rawValue])
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - CalendarEventRow
struct CalendarEventRow: View {
    var event: CalendarEvent
    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(event.startDate.timeString)
                .font(.ffCaption)
                .foregroundColor(.ffTextSecondary)
                .frame(width: 52, alignment: .trailing)

            Rectangle()
                .fill(Color(hex: event.calendarColor))
                .frame(width: 3)
                .clipShape(Capsule())

            Text(event.title)
                .font(.ffBodyMed)
                .foregroundColor(.ffTextPrimary)
                .lineLimit(1)

            Spacer()

            Text("\(event.durationMinutes)m")
                .font(.ffCaption)
                .foregroundColor(.ffTextTertiary)
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.base)
        .background(Color.ffSurfaceElevated.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
    }
}

// MARK: - TaskDetailView
struct TaskDetailView: View {
    var task:      FocusTask
    var viewModel: TodayViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showReschedule = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        HStack {
                            PriorityBadge(task.priority)
                            TagChip(task.type.rawValue.capitalized, color: .ffSecondary)
                            Spacer()
                        }

                        Text(task.title)
                            .font(.ffDisplay2)
                            .foregroundColor(.ffTextPrimary)

                        if !task.notes.isEmpty {
                            Text(task.notes)
                                .font(.ffBody)
                                .foregroundColor(.ffTextSecondary)
                        }

                        if let due = task.dueDate {
                            HStack {
                                Image(systemName: "calendar")
                                Text(due.relativeString)
                            }
                            .font(.ffBody)
                            .foregroundColor(due.isPast ? .ffDanger : .ffTextSecondary)
                        }

                        if task.isPromise, let statement = task.originalStatement {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Original intention")
                                    .font(.ffCaption)
                                    .foregroundColor(.ffTextSecondary)
                                Text(statement)
                                    .font(.ffBody)
                                    .foregroundColor(.ffTextPrimary)
                            }
                            .padding(Spacing.base)
                            .glassCard()
                        }

                        Spacer(minLength: Spacing.huge)

                        VStack(spacing: Spacing.sm) {
                            if !task.isCompleted {
                                FFButton("Mark as Done", icon: "checkmark.circle.fill") {
                                    viewModel.markComplete(task)
                                    dismiss()
                                }
                                FFButton("Reschedule", style: .secondary, icon: "calendar.badge.clock") {
                                    showReschedule = true
                                }
                            }
                        }
                    }
                    .padding(Spacing.base)
                }
            }
            .navigationTitle("Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.ffPrimary)
                }
            }
        }
    }
}

// MARK: - EndOfDayView
struct EndOfDayView: View {
    var viewModel: TodayViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var wins        = ""
    @State private var notDone     = ""
    @State private var tomorrow    = ""
    @State private var wasRealistic = 3

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(LinearGradient.ffBrand)
                            Text("Evening Review")
                                .font(.ffDisplay2)
                                .foregroundColor(.ffTextPrimary)
                            Text("Reflect for 2 minutes.")
                                .font(.ffBody)
                                .foregroundColor(.ffTextSecondary)
                        }
                        .padding(.top, Spacing.xl)

                        reviewQuestion(label: "What did you complete today?", binding: $wins)
                        reviewQuestion(label: "What didn't get done?", binding: $notDone)
                        reviewQuestion(label: "What should move to tomorrow?", binding: $tomorrow)

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Was today realistic?")
                                .font(.ffHeadline3)
                                .foregroundColor(.ffTextPrimary)
                            HStack {
                                ForEach(1...5, id: \.self) { i in
                                    Button(action: { wasRealistic = i }) {
                                        Circle()
                                            .fill(i <= wasRealistic ? Color.ffPrimary : Color.ffSurfaceElevated)
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Text("\(i)").font(.ffCaption).foregroundColor(i <= wasRealistic ? .white : .ffTextSecondary)
                                            )
                                    }
                                    if i < 5 { Spacer() }
                                }
                            }
                        }
                        .padding(Spacing.base)
                        .glassCard()

                        FFButton("Save & Finish", icon: "checkmark") {
                            dismiss()
                        }
                        .padding(.bottom, Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.base)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func reviewQuestion(label: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(.ffHeadline3)
                .foregroundColor(.ffTextPrimary)
            FFTextField("Write here...", text: binding, axis: .vertical)
        }
    }
}
