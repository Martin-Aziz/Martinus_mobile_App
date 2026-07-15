import SwiftUI
import SwiftData

// MARK: - AddTaskView
struct AddTaskView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

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

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()
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
            .navigationTitle(isPromise ? "Record a Promise" : "New Task")
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
                    ForEach([TaskType.task, .reminder, .habit, .promise], id: \.self) { t in
                        TagChip(typeLabel(t), color: typeColor(t), isSelected: type == t) {
                            type      = t
                            isPromise = (t == .promise)
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
                        .colorScheme(.dark)
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
                        .colorScheme(.dark)
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
                    Text("Due Date").font(.ffBodyMed).foregroundColor(.ffTextPrimary)
                }
            }
            .tint(.ffPrimary)
            if hasDueDate {
                DatePicker("", selection: $dueDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .tint(.ffPrimary)
                    .colorScheme(.dark)
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
        FFButton(isPromise ? "Record Promise" : "Create Task", icon: isPromise ? "hand.raised.fill" : "plus.circle.fill") {
            saveTask()
        }
        .disabled(title.isBlank)
        .opacity(title.isBlank ? 0.5 : 1)
    }

    // MARK: - Save

    private func saveTask() {
        let task = FocusTask(
            title:             title,
            type:              type,
            priority:          priority,
            scheduledDate:     hasDate    ? scheduledDate : nil,
            scheduledTime:     hasTime    ? scheduledTime : nil,
            dueDate:           hasDueDate ? dueDate       : nil,
            isPromise:         isPromise,
            promisedTo:        promisedTo.isBlank ? nil : promisedTo,
            originalStatement: isPromise ? title : nil,
            notes:             notes
        )

        appState.taskRepo.insert(task)
        try? appState.taskRepo.save()

        // Schedule notification if time is set
        if hasTime || hasDueDate {
            Task { _ = await NotificationService.shared.scheduleTaskReminder(for: task) }
        }

        HapticManager.success()
        dismiss()
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
