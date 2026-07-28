import SwiftUI
import SwiftData

// MARK: - AddTaskView
struct AddTaskView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let taskToEdit: FocusTask?
    private let onSave: (() -> Void)?

    @State private var title        = ""
    @State private var notes        = ""
    @State private var type         = TaskType.task
    @State private var priority     = Priority.medium
    @State private var isPromise    = false
    @State private var promisedTo   = ""
    @State private var hasDate      = false
    @State private var scheduledDate = Date()
    @State private var hasTime      = false
    @State private var scheduledTime = Date()
    @State private var hasDueDate   = false
    @State private var dueDate      = Date()
    @State private var isRecurring  = false

    init(task: FocusTask? = nil, initialDate: Date? = nil, initialType: TaskType = .task, onSave: (() -> Void)? = nil) {
        self.taskToEdit = task
        self.onSave = onSave
        let seedDate = initialDate ?? Date()
        let seedType = task?.type ?? initialType
        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _type = State(initialValue: seedType)
        _priority = State(initialValue: task?.priority ?? .medium)
        _isPromise = State(initialValue: task?.isPromise ?? (seedType == .promise))
        _promisedTo = State(initialValue: task?.promisedTo ?? "")
        _hasDate = State(initialValue: task?.scheduledDate != nil || initialDate != nil)
        _scheduledDate = State(initialValue: task?.scheduledDate ?? seedDate)
        _hasTime = State(initialValue: task?.scheduledTime != nil || seedType == .event)
        _scheduledTime = State(initialValue: task?.scheduledTime ?? seedDate)
        _hasDueDate = State(initialValue: task?.dueDate != nil || seedType == .event)
        _dueDate = State(initialValue: task?.dueDate ?? seedDate)
        _isRecurring = State(initialValue: task?.isRecurring ?? false)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CinematicBackgroundView(variant: 1)
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        titleSection
                        typeSection
                        prioritySection
                        promiseSection
                        dateSection
                        notesSection
                        saveButton
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.top, Spacing.base)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle(taskToEdit == nil ? (isPromise ? "Record a Promise" : type == .event ? "New Important Date" : "New Task") : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.ffTextSecondary)
                }
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(isPromise ? "What did you promise?" : "Task Title")
                .font(.ffCaption).foregroundColor(.ffTextSecondary)
            FFTextField(
                isPromise ? "I want to... / I will... / I promised to..." : "What needs to be done?",
                text: $title,
                icon: isPromise ? "hand.raised" : "checkmark.circle"
            )
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Type").font(.ffCaption).foregroundColor(.ffTextSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach([TaskType.task, .event, .reminder, .habit, .promise], id: \.self) { t in
                        TagChip(typeLabel(t), color: typeColor(t), isSelected: type == t) {
                            type      = t
                            isPromise = (t == .promise)
                            if t == .event {
                                hasDate = true
                                hasDueDate = true
                                hasTime = true
                            }
                        }
                    }
                }
            }
        }
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Priority").font(.ffCaption).foregroundColor(.ffTextSecondary)
            HStack(spacing: Spacing.sm) {
                ForEach(Priority.allCases) { p in
                    TagChip(p.label, color: priorityColor(p), isSelected: priority == p) {
                        priority = p
                    }
                }
                Spacer()
            }
        }
    }

    private var promiseSection: some View {
        Group {
            if isPromise {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Toggle(isOn: Binding(
                        get: { !promisedTo.isEmpty },
                        set: { if !$0 { promisedTo = "" } }
                    )) {
                        Text("Promise to another person")
                            .font(.ffBodyMed).foregroundColor(.ffTextPrimary)
                    }
                    .tint(.ffPrimary)

                    if !promisedTo.isEmpty || false {
                        FFTextField("Their name...", text: $promisedTo, icon: "person.fill")
                    }
                }
                .padding(Spacing.base)
                .glassCard()
            }
        }
    }

    private var dateSection: some View {
        VStack(spacing: Spacing.sm) {
            // Scheduled date
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Toggle(isOn: $hasDate) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "calendar").foregroundColor(.ffSecondary)
                        Text("Schedule Date").font(.ffBodyMed).foregroundColor(.ffTextPrimary)
                    }
                }
                .tint(.ffPrimary)
                if hasDate {
                    DatePicker("", selection: $scheduledDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(.ffPrimary)
                        .labelsHidden()
                }
            }

            FFDivider()

            // Scheduled time
            if hasDate {
                Toggle(isOn: $hasTime) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "clock").foregroundColor(.ffWarning)
                        Text("Add Time").font(.ffBodyMed).foregroundColor(.ffTextPrimary)
                    }
                }
                .tint(.ffPrimary)
                if hasTime {
                    DatePicker("", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .tint(.ffPrimary)
                        .labelsHidden()
                        .frame(height: 100)
                        .clipped()
                }
                FFDivider()
            }

            // Due date
            Toggle(isOn: $hasDueDate) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "flag.fill").foregroundColor(.ffDanger)
                    Text(type == .event ? "Event Date & Time" : "Due Date").font(.ffBodyMed).foregroundColor(.ffTextPrimary)
                }
            }
            .tint(.ffPrimary)
            if hasDueDate {
                DatePicker("", selection: $dueDate, displayedComponents: type == .event ? [.date, .hourAndMinute] : .date)
                    .datePickerStyle(.compact)
                    .tint(.ffPrimary)
                    .labelsHidden()
            }
        }
        .padding(Spacing.base)
        .glassCard()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Notes").font(.ffCaption).foregroundColor(.ffTextSecondary)
            FFTextField("Additional context...", text: $notes, icon: "text.alignleft", axis: .vertical)
        }
    }

    private var saveButton: some View {
        FFButton(taskToEdit == nil ? (isPromise ? "Record Promise" : type == .event ? "Add Important Date" : "Create Task") : "Save Changes", icon: taskToEdit == nil ? (isPromise ? "hand.raised.fill" : type == .event ? "calendar.badge.plus" : "plus.circle.fill") : "checkmark.circle.fill") {
            saveTask()
        }
        .disabled(title.isBlank)
        .opacity(title.isBlank ? 0.5 : 1)
    }

    // MARK: - Save

    private func saveTask() {
        let eventDate = type == .event ? dueDate : nil
        let task: FocusTask
        if let existing = taskToEdit {
            task = existing
            task.title = title.trimmed
            task.notes = notes
            task.type = type
            task.priority = priority
            task.scheduledDate = type == .event ? eventDate : (hasDate ? scheduledDate : nil)
            task.scheduledTime = type == .event ? eventDate : (hasTime ? combinedDateAndTime : nil)
            task.dueDate = hasDueDate ? dueDate : nil
            task.isPromise = isPromise
            task.promisedTo = promisedTo.isBlank ? nil : promisedTo.trimmed
            task.originalStatement = isPromise ? title.trimmed : nil
            task.isRecurring = isRecurring
            task.updatedAt = Date()
        } else {
            task = FocusTask(
                title:             title.trimmed,
                type:              type,
                priority:          priority,
                scheduledDate:     type == .event ? eventDate : (hasDate ? scheduledDate : nil),
                scheduledTime:     type == .event ? eventDate : (hasTime ? combinedDateAndTime : nil),
                dueDate:           hasDueDate ? dueDate : nil,
                isPromise:         isPromise,
                promisedTo:        promisedTo.isBlank ? nil : promisedTo.trimmed,
                originalStatement: isPromise ? title.trimmed : nil,
                notes:             notes
            )
            task.isRecurring = isRecurring
            appState.taskRepo.insert(task)
        }
        try? appState.taskRepo.save()

        // Schedule notification if time is set
        if hasTime || hasDueDate {
            Task { _ = await NotificationService.shared.scheduleTaskReminder(for: task) }
        }

        HapticManager.success()
        if taskToEdit == nil {
            appState.motivationMoment = AssistantService.motivation(for: .taskCreated, taskTitle: task.title)
        }
        onSave?()
        dismiss()
    }

    private var combinedDateAndTime: Date {
        let dateParts = Calendar.current.dateComponents([.year, .month, .day], from: scheduledDate)
        let timeParts = Calendar.current.dateComponents([.hour, .minute], from: scheduledTime)
        var components = dateParts
        components.hour = timeParts.hour
        components.minute = timeParts.minute
        return Calendar.current.date(from: components) ?? scheduledTime
    }

    // MARK: - Helpers
    private func typeLabel(_ t: TaskType) -> String {
        switch t {
        case .task:     return "Task"
        case .reminder: return "Reminder"
        case .habit:    return "Habit"
        case .promise:  return "Promise"
        case .event:    return "Event"
        case .focus:    return "Focus"
        }
    }

    private func typeColor(_ t: TaskType) -> Color {
        switch t {
        case .task:     return .ffPrimary
        case .reminder: return .ffWarning
        case .habit:    return .ffSuccess
        case .promise:  return Color(hex: "#F97316")
        default:        return .ffSecondary
        }
    }

    private func priorityColor(_ p: Priority) -> Color {
        switch p {
        case .high:   return .ffPriorityHigh
        case .medium: return .ffPriorityMedium
        case .low:    return .ffPriorityLow
        }
    }
}
