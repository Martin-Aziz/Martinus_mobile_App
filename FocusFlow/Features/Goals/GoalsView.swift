import SwiftUI
import SwiftData

// MARK: - GoalsViewModel
@MainActor
@Observable
final class GoalsViewModel {
    var goals:           [Goal]     = []
    var filteredGoals:   [Goal]     = []
    var selectedCategory: GoalCategory? = nil
    var searchText       = ""
    var isLoaded         = false
    var showAddGoal      = false

    private var goalRepo: GoalRepository?

    func load(goalRepo: GoalRepository) async {
        self.goalRepo = goalRepo
        await refresh()
    }

    func refresh() async {
        goals = (try? goalRepo?.fetchActive()) ?? []
        applyFilter()
        isLoaded = true
    }

    func applyFilter() {
        var result = goals
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        filteredGoals = result.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }

    func updateProgress(_ goal: Goal, progress: Double) {
        goalRepo?.updateProgress(goal, progress: progress)
        Task { await refresh() }
    }

    func archive(_ goal: Goal) {
        goalRepo?.archive(goal)
        Task { await refresh() }
    }

    func delete(_ goal: Goal) {
        goalRepo?.delete(goal)
        Task { await refresh() }
    }

    var totalProgress: Double {
        guard !goals.isEmpty else { return 0 }
        return goals.reduce(0) { $0 + $1.progress } / Double(goals.count)
    }
}

// MARK: - GoalsView
struct GoalsView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = GoalsViewModel()
    @State private var showAdd   = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerBar
                    categoryFilter

                    if !viewModel.isLoaded {
                        ProgressView().tint(.ffPrimary).frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredGoals.isEmpty {
                        emptyState
                    } else {
                        goalsList
                    }
                }
            }
            .task { await viewModel.load(goalRepo: appState.goalRepo) }
            .sheet(isPresented: $showAdd, onDismiss: { Task { await viewModel.refresh() } }) {
                AddGoalView()
            }
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Goals")
                    .font(.ffDisplay2)
                    .foregroundColor(.ffTextPrimary)
                if !viewModel.goals.isEmpty {
                    Text("\(Int(viewModel.totalProgress * 100))% overall progress")
                        .font(.ffBody)
                        .foregroundColor(.ffTextSecondary)
                }
            }
            Spacer()
            CircularIconButton("plus", action: { showAdd = true })
        }
        .padding(.horizontal, Spacing.base)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                TagChip("All", color: .ffPrimary, isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                    viewModel.applyFilter()
                }
                ForEach(GoalCategory.allCases) { cat in
                    TagChip(cat.emoji + " " + cat.label, color: .ffPrimary, isSelected: viewModel.selectedCategory == cat) {
                        viewModel.selectedCategory = (viewModel.selectedCategory == cat) ? nil : cat
                        viewModel.applyFilter()
                    }
                }
            }
            .padding(.horizontal, Spacing.base)
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - List
    private var goalsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.filteredGoals) { goal in
                    NavigationLink {
                        GoalDetailView(goal: goal, viewModel: viewModel)
                    } label: {
                        GoalCard(goal: goal)
                    }
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.bottom, 100)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon:        "target",
            title:       "No goals yet",
            subtitle:    "Set a meaningful goal and let FocusFlow help you reach it.",
            actionLabel: "Add First Goal",
            onAction:    { showAdd = true }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - GoalCard
struct GoalCard: View {
    var goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                HStack(spacing: Spacing.sm) {
                    Text(goal.emoji)
                        .font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title)
                            .font(.ffHeadline3)
                            .foregroundColor(.ffTextPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(goal.category.label)
                            .font(.ffCaption)
                            .foregroundColor(.ffTextSecondary)
                    }
                }
                Spacer()
                // PM artifact P3: goal health badge — visible at task-list layer
                GoalHealthBadge(status: goal.healthStatus)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.ffCaption)
                        .foregroundColor(.ffTextSecondary)
                    Spacer()
                    Text(goal.progress.percentString)
                        .font(.ffCaption)
                        .foregroundStyle(LinearGradient.ffBrand)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: Radius.full)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: Radius.full)
                            .fill(LinearGradient.ffBrand)
                            .frame(width: geo.size.width * goal.progress.clampedProgress, height: 8)
                            .animation(.easeInOut(duration: 0.6), value: goal.progress)
                    }
                }
                .frame(height: 8)
            }

            HStack {
                if let deadline = goal.targetDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(deadline.relativeString)
                            .font(.ffCaption)
                    }
                    .foregroundColor(
                        goal.daysUntilDeadline.map { $0 <= 3 } == true ? .ffDanger : .ffTextSecondary
                    )
                }
                Spacer()
                if let days = goal.daysUntilDeadline, days >= 0 {
                    Text("\(days)d left")
                        .font(.ffCaption)
                        .foregroundColor(.ffTextTertiary)
                }
            }
        }
        .padding(Spacing.base)
        .glassCard(cornerRadius: Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(hex: goal.colorHex).opacity(0.4), Color.clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - GoalHealthBadge
/// PM artifact P3: goal-health signal visible at the goal-card layer.
/// Kill metric: navigate-to-goal rate from badge tap > 10% at 60 days.
struct GoalHealthBadge: View {
    var status: GoalHealthStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: status.color))
            Text(status.label)
                .font(.ffCaption2)
                .foregroundColor(Color(hex: status.color))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: status.color).opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - GoalDetailView
struct GoalDetailView: View {
    var goal:      Goal
    var viewModel: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var progressSlider: Double = 0
    @State private var showEdit = false
    @State private var newMilestone = ""

    var body: some View {
        ZStack {
            Color.ffBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Hero
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text(goal.emoji).font(.system(size: 40))
                            Spacer()
                            PriorityBadge(goal.priority)
                        }
                        Text(goal.title)
                            .font(.ffDisplay2)
                            .foregroundColor(.ffTextPrimary)
                        if !goal.notes.isEmpty {
                            Text(goal.notes)
                                .font(.ffBody)
                                .foregroundColor(.ffTextSecondary)
                        }
                    }

                    // Stats row
                    HStack(spacing: Spacing.base) {
                        StatTile(label: "Progress", value: goal.progress.percentString,
                                 icon: "chart.line.uptrend.xyaxis", color: .ffPrimary)
                        if let days = goal.daysUntilDeadline {
                            StatTile(label: "Days Left", value: "\(days)",
                                     icon: "calendar", color: days <= 3 ? .ffDanger : .ffSecondary)
                        }
                    }

                    // Progress slider
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        SectionHeader(title: "Update Progress")
                        Slider(value: $progressSlider, in: 0...1, step: 0.05)
                            .tint(.ffPrimary)
                            .onChange(of: progressSlider) { _, new in
                                viewModel.updateProgress(goal, progress: new)
                            }
                        HStack {
                            Text("0%").font(.ffCaption).foregroundColor(.ffTextTertiary)
                            Spacer()
                            Text(progressSlider.percentString).font(.ffCaption).foregroundColor(.ffPrimary)
                            Spacer()
                            Text("100%").font(.ffCaption).foregroundColor(.ffTextTertiary)
                        }
                    }
                    .padding(Spacing.base)
                    .glassCard()

                    // Milestones
                    milestonesSection

                    // Danger zone
                    VStack(spacing: Spacing.sm) {
                        FFButton("Archive Goal", style: .secondary, icon: "archivebox") {
                            viewModel.archive(goal)
                            dismiss()
                        }
                    }
                    .padding(.bottom, Spacing.xxl)
                }
                .padding(Spacing.base)
            }
        }
        .navigationTitle(goal.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { progressSlider = goal.progress }
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Milestones")
            ForEach(goal.milestones) { milestone in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(milestone.isCompleted ? .ffSuccess : .ffTextTertiary)
                    Text(milestone.title)
                        .font(.ffBody)
                        .foregroundColor(milestone.isCompleted ? .ffTextTertiary : .ffTextPrimary)
                        .strikethrough(milestone.isCompleted)
                }
                .padding(.vertical, Spacing.xs)
            }
            HStack(spacing: Spacing.sm) {
                FFTextField("Add milestone...", text: $newMilestone, icon: "flag")
                Button(action: addMilestone) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.ffPrimary)
                }
            }
        }
    }

    private func addMilestone() {
        guard !newMilestone.isBlank else { return }
        var milestones = goal.milestones
        milestones.append(GoalMilestone(title: newMilestone, sortOrder: milestones.count))
        goal.milestones = milestones
        newMilestone = ""
        HapticManager.light()
    }
}

// MARK: - AddGoalView
struct AddGoalView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title      = ""
    @State private var notes      = ""
    @State private var category   = GoalCategory.personal
    @State private var priority   = Priority.medium
    @State private var targetDate: Date? = nil
    @State private var hasDeadline = false
    @State private var selectedEmoji = "⭐"
    @State private var selectedColor = "#8C65FF"
    @State private var showEmojiPicker = false

    private let emojiOptions = ["⭐","🚀","💪","📚","💰","❤️","🎯","🌱","🏆","✈️","🎨","💻","🏋️","📝","🧘"]
    private let colorOptions  = ["#8C65FF","#00D4FF","#22C55E","#F59E0B","#EC4899","#F97316","#06B6D4"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Emoji picker
                        VStack(spacing: Spacing.sm) {
                            Text("Choose an emoji")
                                .font(.ffCaption)
                                .foregroundColor(.ffTextSecondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Spacing.sm) {
                                ForEach(emojiOptions, id: \.self) { emoji in
                                    Text(emoji)
                                        .font(.system(size: 28))
                                        .frame(width: 52, height: 52)
                                        .background(selectedEmoji == emoji ? Color.ffPrimary.opacity(0.2) : Color.ffSurfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                                        .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(selectedEmoji == emoji ? Color.ffPrimary : Color.clear, lineWidth: 2))
                                        .onTapGesture { selectedEmoji = emoji }
                                }
                            }
                        }
                        .padding(Spacing.base)
                        .glassCard()

                        // Title
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Goal Title").font(.ffCaption).foregroundColor(.ffTextSecondary)
                            FFTextField("What do you want to achieve?", text: $title)
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Why it matters").font(.ffCaption).foregroundColor(.ffTextSecondary)
                            FFTextField("Your reason...", text: $notes, axis: .vertical)
                        }

                        // Category
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Category").font(.ffCaption).foregroundColor(.ffTextSecondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(GoalCategory.allCases) { cat in
                                        TagChip(cat.emoji + " " + cat.label, color: .ffPrimary, isSelected: category == cat) {
                                            category = cat
                                        }
                                    }
                                }
                            }
                        }

                        // Priority
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Priority").font(.ffCaption).foregroundColor(.ffTextSecondary)
                            HStack(spacing: Spacing.sm) {
                                ForEach(Priority.allCases) { p in
                                    TagChip(p.label, color: priorityColor(p), isSelected: priority == p) {
                                        priority = p
                                    }
                                }
                            }
                        }

                        // Deadline
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Toggle(isOn: $hasDeadline) {
                                Text("Set a Deadline")
                                    .font(.ffBodyMed)
                                    .foregroundColor(.ffTextPrimary)
                            }
                            .tint(.ffPrimary)
                            if hasDeadline {
                                DatePicker("Target Date", selection: Binding(
                                    get: { targetDate ?? Date().addingTimeInterval(30*24*3600) },
                                    set: { targetDate = $0 }
                                ), displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(.ffPrimary)
                                .colorScheme(.dark)
                            }
                        }
                        .padding(Spacing.base)
                        .glassCard()

                        FFButton("Create Goal", icon: "target") {
                            saveGoal()
                        }
                        .disabled(title.isBlank)
                        .opacity(title.isBlank ? 0.5 : 1)
                        .padding(.bottom, Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.top, Spacing.base)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.ffTextSecondary)
                }
            }
        }
    }

    private func saveGoal() {
        let goal = Goal(
            title:      title,
            category:   category,
            priority:   priority,
            targetDate: hasDeadline ? targetDate : nil,
            notes:      notes,
            colorHex:   selectedColor,
            emoji:      selectedEmoji
        )
        appState.goalRepo.insert(goal)
        try? appState.goalRepo.save()
        HapticManager.success()
        dismiss()
    }

    private func priorityColor(_ p: Priority) -> Color {
        switch p {
        case .high:   return .ffPriorityHigh
        case .medium: return .ffPriorityMedium
        case .low:    return .ffPriorityLow
        }
    }
}
