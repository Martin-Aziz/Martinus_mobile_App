import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                CinematicBackgroundView(variant: 0)
                backgroundBlobs

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        greetingSection
                        if viewModel.isLoaded {
                            if let focus = viewModel.mainFocus {
                                TodayFocusCard(
                                    task: focus,
                                    progress: viewModel.focusProgress(for: focus),
                                    onChangeFocus: { viewModel.showChangeFocus = true }
                                )
                            } else {
                                EmptyFocusCard { appState.showAddTask = true }
                            }
                            if let insight = viewModel.insight {
                                AssistantCard(insight: insight) { action in
                                    handleInsightAction(action, insight: insight)
                                }
                            }
                            upcomingSection
                            if let quote = viewModel.dailyQuote {
                                DailyMotivationCard(quote: quote, onFavorite: {
                                    appState.quoteRepo.toggleFavorite(quote)
                                })
                            }
                            quickActionsSection
                        } else {
                            ProgressView()
                                .tint(.ffPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(Spacing.xxl)
                                .glassCard(cornerRadius: Radius.lg)
                        }
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.load(
                    taskRepo:  appState.taskRepo,
                    goalRepo:  appState.goalRepo,
                    quoteRepo: appState.quoteRepo,
                    userName:  appState.userProfile?.name ?? "there"
                )
            }
            .refreshable { await viewModel.refresh() }
            .sheet(item: $viewModel.motivationMoment) { moment in
                MotivationMomentView(moment: moment)
            }
            .confirmationDialog(
                "Change Today's Focus",
                isPresented: $viewModel.showChangeFocus,
                titleVisibility: .visible
            ) {
                ForEach(viewModel.focusCandidates) { task in
                    Button(task.title) { viewModel.setMainFocus(task) }
                }
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: viewModel.showAllUpcoming) { _, shouldShow in
                guard shouldShow else { return }
                viewModel.showAllUpcoming = false
                appState.selectedTab = .today
            }
        }
    }

    // MARK: - Sections

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(viewModel.greetingText)
                        .font(.ffDisplay2)
                        .foregroundColor(.ffTextPrimary)
                    Text(viewModel.greetingSubtitle)
                        .font(.ffBody)
                        .foregroundColor(.ffTextSecondary)
                }
                Spacer()
                NavigationLink {
                    InsightsView()
                } label: {
                    UserAvatarView(profile: appState.userProfile, size: 54)
                }
            }
        }
        .padding(.top, Spacing.xl)
    }

    private var upcomingSection: some View {
        VStack(spacing: Spacing.sm) {
            SectionHeader(
                title: "Upcoming",
                trailingLabel: viewModel.tasks.count > 6 ? "See All" : nil,
                onTap: { viewModel.showAllUpcoming = true }
            )
            if viewModel.upcomingItems.isEmpty {
                Text("Nothing scheduled for today.")
                    .font(.ffHeadline3)
                    .fontWeight(.semibold)
                    .foregroundColor(.ffTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.base)
                    .background(Color.ffSurfaceElevated.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(viewModel.upcomingItems) { task in
                        UpcomingTaskRow(task: task, onComplete: {
                            viewModel.markComplete(task)
                        })
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(spacing: Spacing.sm) {
            SectionHeader(title: "Quick Actions")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                QuickActionButton(icon: "plus.circle.fill",    label: "Add Task",    color: .ffPrimary)   { appState.showAddTask = true }
                QuickActionButton(icon: "target",             label: "New Goal",   color: .ffSecondary) { appState.showAddGoal = true }
                QuickActionButton(icon: "book.fill",          label: "Journal",    color: .ffSuccess)   { appState.selectedTab = .journal }
                QuickActionButton(icon: "timer",              label: "Focus",      color: .ffWarning)   { appState.showFocusSession = true }
                QuickActionButton(icon: "bell.fill",          label: "Reminder",   color: .ffPrimary) { appState.showAddTask = true }
                QuickActionButton(icon: "text.bubble.fill",   label: "Promise",    color: .ffPrimary) {
                    appState.showAddTask = true
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundBlobs: some View {
        ZStack {
            Circle()
                .fill(Color.ffPrimary.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)
            Circle()
                .fill(Color.ffSecondary.opacity(0.08))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: 150, y: 100)
        }
        .ignoresSafeArea()
    }

    private func handleInsightAction(_ action: InsightAction, insight: DailyInsight) {
        switch action.label {
        case "Move to Tomorrow":
            if let taskID = insight.taskID,
               let task = viewModel.tasks.first(where: { $0.id == taskID }) {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                appState.taskRepo.reschedule(task, to: tomorrow)
                Task { await viewModel.refresh() }
            }
        case "Start Now":
            appState.showFocusSession = true
        default: break
        }
    }
}

// MARK: - TodayFocusCard
struct TodayFocusCard: View {
    var task:            FocusTask
    var progress:        Double
    var onChangeFocus:   () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Focus")
                        .font(.ffCaption)
                        .foregroundColor(.ffTextSecondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    Text(task.title)
                        .font(.ffHeadline1)
                        .foregroundColor(.ffTextPrimary)
                }
                Spacer()
                ProgressRing(progress: progress, size: 56)
            }

            HStack(spacing: Spacing.sm) {
                PriorityBadge(task.priority)
                if let deadline = task.dueDate ?? task.scheduledTime ?? task.scheduledDate {
                    CompactCountdownLabel(target: deadline)
                }
            }

            if let notes = task.notes.isEmpty ? nil : task.notes {
                Text(notes)
                    .font(.ffSubhead)
                    .foregroundColor(.ffTextSecondary)
                    .lineLimit(2)
            }

            FFButton("Change Today's Focus", style: .secondary, icon: "arrow.triangle.2.circlepath", action: onChangeFocus)
        }
        .padding(Spacing.base)
        .glassCard(cornerRadius: Radius.lg)
    }
}

// MARK: - EmptyFocusCard
struct EmptyFocusCard: View {
    var onAdd: () -> Void
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "scope")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(LinearGradient.ffBrand)
            Text("No main focus set")
                .font(.ffHeadline3)
                .foregroundColor(.ffTextPrimary)
            Text("Set one clear priority for today.")
                .font(.ffBody)
                .foregroundColor(.ffTextSecondary)
            FFButton("Set Today's Focus", style: .primary, icon: "plus", action: onAdd)
                .padding(.top, Spacing.xs)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: Radius.lg)
    }
}

// MARK: - AssistantCard
struct AssistantCard: View {
    var insight: DailyInsight
    var onAction: (InsightAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LinearGradient.ffBrand)
                Text("Assistant")
                    .font(.ffCaption)
                    .foregroundColor(.ffTextSecondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            Text(insight.message)
                .font(.ffBody)
                .foregroundColor(.ffTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !insight.actions.isEmpty {
                HStack(spacing: Spacing.sm) {
                    ForEach(insight.actions.prefix(2)) { action in
                        Button(action: { HapticManager.light(); onAction(action) }) {
                            Text(action.label)
                                .font(.ffCaption)
                                .foregroundColor(action.style == .primary ? .white : .ffTextSecondary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, 8)
                                .background(
                                    action.style == .primary
                                    ? AnyView(LinearGradient.ffBrand)
                                    : AnyView(Color.ffSurfaceElevated)
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(Spacing.base)
        .glassCard(cornerRadius: Radius.md, borderOpacity: 0.15)
    }
}

// MARK: - UpcomingTaskRow
struct UpcomingTaskRow: View {
    var task:       FocusTask
    var onComplete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            CheckmarkButton(isChecked: task.isCompleted, onToggle: onComplete)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.ffBodyMed)
                    .foregroundColor(task.isCompleted ? .ffTextTertiary : .ffTextPrimary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(1)
                if let time = task.scheduledTime {
                    Text(time.timeString)
                        .font(.ffCaption)
                        .foregroundColor(.ffTextSecondary)
                }
                if let deadline = task.dueDate ?? task.scheduledTime ?? task.scheduledDate,
                   !task.isCompleted {
                    CompactCountdownLabel(target: deadline)
                }
            }

            Spacer()

            taskTypeIcon
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.base)
        .background(Color.ffSurfaceElevated.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
    }

    @ViewBuilder
    private var taskTypeIcon: some View {
        switch task.type {
        case .event:   Image(systemName: "calendar").foregroundColor(.ffSecondary)
        case .habit:   Image(systemName: "repeat").foregroundColor(.ffSuccess)
        case .promise: Image(systemName: "hand.raised.fill").foregroundColor(.ffWarning)
        default:       Image(systemName: "checkmark.square").foregroundColor(.ffTextTertiary)
        }
    }
}

// MARK: - DailyMotivationCard
struct DailyMotivationCard: View {
    var quote:      Quote
    var onFavorite: () -> Void
    @State private var isFavorited = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Daily Motivation")
                    .font(.ffCaption)
                    .foregroundColor(.ffTextSecondary)
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                TagChip(quote.category.label, color: .ffPrimary)
            }

            Text("“\(quote.text)”")
                .font(.ffQuote)
                .foregroundColor(.ffTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(quote.displayAuthor)")
                .font(.ffBodyMed)
                .foregroundStyle(LinearGradient.ffBrand)

            if !quote.explanation.isEmpty {
                Text(quote.explanation)
                    .font(.ffSubhead)
                    .foregroundColor(.ffTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: Spacing.base) {
                Button(action: {
                    isFavorited.toggle()
                    HapticManager.light()
                    onFavorite()
                }) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorited ? .ffDanger : .ffTextSecondary)
                }
                Spacer()
                ShareLink(item: "“\(quote.text)” — \(quote.displayAuthor)") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(.ffTextSecondary)
                }
            }
        }
        .padding(Spacing.base)
        .glassCard(cornerRadius: Radius.lg)
        .onAppear { isFavorited = quote.isFavorited }
    }
}

// MARK: - QuickActionButton
struct QuickActionButton: View {
    var icon:   String
    var label:  String
    var color:  Color
    var action: () -> Void

    var body: some View {
        Button(action: { HapticManager.medium(); action() }) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                Text(label)
                    .font(.ffCaption2)
                    .foregroundColor(.ffTextSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .glassCard(cornerRadius: Radius.sm)
        }
    }
}
